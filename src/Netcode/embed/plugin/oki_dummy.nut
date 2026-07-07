// Oki Dummy - training mode wakeup/block reversal for practice P2
//
// Architecture:
//   - player2=0 + guard_mode=1 + ex_guard_mode=1 during barrier window.
//     Practice_CommonUpdate (player2<3 path) sets autoGuard=true,
//     autoBaria=1. CalcContactTestGuard sees autoGuard → guard_state=1.
//     IsFree() is false during jump → Practice_Com_Wait NOT called →
//     CommonPracticeLoop NOT called → inputs not zeroed.
//   - forceBariaCount + guardBaria: survive Practice_CommonUpdate.
//     PlayerGuardAction_Normal (hit time) checks forceBariaCount>0 +
//     guardBaria → autoBaria=1 → BariaGuard_Init (barrier guard).
//   - player2=4 + device hijack for action injection (before barrier).
//   - Detection: transition from IsDamage → fully stand (motion<=1).
//   - P button (btn==4): temporarily overrides recover_mode so the game's
//     Practice_CommonUpdate sets input.b3=1 every frame during IsDamage()>=2.
//     This gives the same seamless timing as the built-in "front(tag)"/
//     "back(tag)" tech options — zero vulnerability gap.
//   - Action configured via practice menu page "Oki Dummy":
//     ::config.practice.oki_dir (1-9) + oki_btn (0-7: A,B,C,D,P,AB,BC,CP; 8=None)
config = {
    enabled = true
    delay_frames = 0     // 0 = earliest possible frame after recovery
    hold_guard = false   // hold back during delay frames (simulates fuzzy defense)
};

class modifier extends modifier {
    _cfg = null;
    _saved_player2 = -1;
    _was_paused = false;
    _was_damage = false;
    _wakeup_active = false;
    _delay_remaining = -1;
    _action_pending = false;
    _proxy = null;
    _baria_frames = 0;    // remaining frames of active barrier guard window
    _saved_guard_mode = -1;
    _saved_ex_guard_mode = -1;
    _no_guard_mode = false;  // user's guard_mode=0 → keep player2=0 for disableGuard=-1
    _post_baria_debug = 0;   // frames of debug output after barrier window ends
    _saved_recover_mode = -1; // saved recover_mode when P button overrides it
    _picked_dir = 5;   // randomly selected dir from active slots
    _picked_btn = 0;   // randomly selected btn from active slots
    _picked_delay = 0; // per-slot delay (fuzzy guard frames)
    _frame_tick = 0;   // simple counter for pseudo-random
    _saved_user_eg = -1; // saved ex_guard_mode for engine translation
    _idle_p2_changed = false; // player2 temporarily changed for idle guard
    _once_guard_frames = 0;   // guard_mode=3 (once): post-hit guard window
    _saved_user_gm = -1;      // saved guard_mode for engine translation
    _reversal_saved_p2 = -1;  // saved player2 for reversal restore
    _picked_trigger = 0;      // 0=on hit, 1=on block (per-slot trigger type)
    _was_guard_motion = false; // blockstun state tracking

    function Enabled(param) {
        return param.game_mode == 40;
    }

    function constructor() {
        _cfg = ::plugin.cfg.oki_dummy.data;
    }

    function PreFrame() {
        // Disconnect oki sprites from overlay during gameplay
        // UpdateMain reconnects them when menu is open
        if ("_oki_sprites" in ::menu) {
            foreach (s in ::menu._oki_sprites) {
                try { s.DisconnectRenderSlot(); } catch(e) {}
            }
        }

        if (!_cfg.enabled) return true;
        if (::battle.state != 8) return true;

        // --- pause-menu handling ---
        if (::menu.pause_hack) {
            if (!_was_paused) {
                // pause_hack is set by practice.Initialize, but battle.UpdateMain
                // doesn't run during the menu. This block fires on the FIRST frame
                // AFTER the menu closes. Save the user's new settings — don't
                // restore old values (that would overwrite menu changes).
                _saved_player2 = ::config.practice.player2;
                if (_saved_guard_mode >= 0) {
                    ::config.practice.guard_mode = _saved_guard_mode;
                    ::config.practice.ex_guard_mode = _saved_ex_guard_mode;
                    _saved_guard_mode = -1;
                }
                _RestoreRecoverMode();
                _baria_frames = 0;
                _no_guard_mode = (::config.practice.guard_mode == 0 && ::config.practice.ex_guard_mode == 0);
                _once_guard_frames = 0;
                _action_pending = false;
                _wakeup_active = false;
                _reversal_saved_p2 = -1;
                _was_paused = true;
            }
            return true;
        }
        if (_was_paused) {
            _saved_player2 = ::config.practice.player2;
            _no_guard_mode = (::config.practice.guard_mode == 0 && ::config.practice.ex_guard_mode == 0);
            _once_guard_frames = 0;
            _action_pending = false;
            _wakeup_active = false;
            _reversal_saved_p2 = -1;
            _was_paused = false;
        }

        local team1 = ::battle.team[1];
        if (!team1 || !team1.current) return true;
        local p2 = team1.current;

        // --- device hijack ---
        if (p2.command && (!_proxy || p2.command.device != _proxy)) {
            _proxy = {
                x = 0, y = 0,
                b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0,
                b0r = 0, b1r = 0, b2r = 0, b3r = 0, b4r = 0, b5r = 0
            };
            try { p2.command.device = _proxy; ::print("[oki] device hijacked\n"); }
            catch (e) { _proxy = null; ::print("[oki] hijack FAILED: " + e + "\n"); }
        }

        // --- first-run: init config defaults ---
        if (_saved_player2 < 0) {
            _saved_player2 = ::config.practice.player2;
            _no_guard_mode = (::config.practice.guard_mode == 0 && ::config.practice.ex_guard_mode == 0);
        }
        // First-run: init slot configs + migrate legacy oki_dir/oki_btn
        if (!("oki_slot" in ::config.practice)) {
            ::print("[oki] config init: creating defaults\n");
            ::config.practice.oki_slot <- 0;
            if ("oki_dir" in ::config.practice) {
                ::config.practice.oki_s0_dir <- ::config.practice.oki_dir;
                ::config.practice.oki_s0_btn <- ::config.practice.oki_btn;
            } else {
                ::config.practice.oki_s0_dir <- 5;
                ::config.practice.oki_s0_btn <- 0;
            }
            for (local s = 1; s < 5; s++) {
                ::config.practice["oki_s" + s + "_dir"] <- 5;
                ::config.practice["oki_s" + s + "_btn"] <- 8;
            }
        }
        // Migrate: ensure weight/delay/trigger exist for all slots
        for (local s = 0; s < 5; s++) {
            local wk = "oki_s" + s + "_weight";
            if (!(wk in ::config.practice)) ::config.practice[wk] <- 5;
            local dk = "oki_s" + s + "_delay";
            if (!(dk in ::config.practice)) ::config.practice[dk] <- 0;
            local tk = "oki_s" + s + "_trigger";
            if (!(tk in ::config.practice)) ::config.practice[tk] <- 0;
        }

        // --- P button recover_mode override ---
        // The game's Practice_CommonUpdate (practice_update.nut) directly sets
        // this.input.b3=1 and this.input.x=±3 every frame while IsDamage()>=2,
        // AFTER input processing and CommonPracticeLoop, BEFORE stateLabel.
        // This gives seamless swap wake-up with zero vulnerability gap.
        // We temporarily override recover_mode to leverage this mechanism.
        local btn = _picked_btn;
        if (btn == 4) {
            // Map oki_dir to recover_mode: forward→4, backward→5, neutral→5
            // After _DirToXY + direction conversion: forward = x>0, back = x<0
            local dir = _picked_dir;
            local d = _DirToXY(dir);
            // numpad 6 = forward: d.x=6 before conversion, we check the numpad directly
            local desired_rm = (dir == 6 || dir == 3 || dir == 9) ? 4 : 5;

            if (_saved_recover_mode < 0) {
                _saved_recover_mode = ::config.practice.recover_mode;
            }
            ::config.practice.recover_mode = desired_rm;
        } else {
            _RestoreRecoverMode();
        }

        // --- calculate guard_active (shared by idle + delay sections) ---
        // guard_mode: 0=off, 1=all, 2=random, 3=once
        // All(1) & Random(2): always translate player2 for engine autoGuard.
        // Once(3): only during post-hit guard window (_once_guard_frames).
        _saved_user_gm = ::config.practice.guard_mode;
        local gm = ::config.practice.guard_mode;
        local guard_active = (gm >= 1 && gm <= 2);
        if (gm == 3 && _once_guard_frames > 0) {
            guard_active = true;
            _once_guard_frames--;
        }

        // --- maintain guard window (after D actions) ---
        // Engine mapping: autoBaria=1 → always BariaGuard_Init.
        // forceBariaCount>=10 → enhanced barrier guard (JustGuardBaria visual = 精防).
        // ex_guard_mode=2 in Practice_CommonUpdate → autoBaria=2 (random 50%), useless.
        // So we translate: user_eg 0→autoBaria 0, 1→autoBaria 1, 2→autoBaria 1+forceBariaCount.
        if (_baria_frames > 0) {
            ::config.practice.player2 = 0;
            ::config.practice.guard_mode = 1;
            local eg = _saved_ex_guard_mode;
            _ApplyGuardType(p2, eg);
            _baria_frames--;
        } else if (!_action_pending) {
            // Barrier window just ended: restore guard config and player2 ONCE
            if (_saved_guard_mode >= 0) {
                ::print("[oki] RESTORE guard_mode=" + _saved_guard_mode
                    + " ex_guard=" + _saved_ex_guard_mode + "\n");
                _post_baria_debug = 30;
                ::config.practice.guard_mode = _saved_guard_mode;
                ::config.practice.ex_guard_mode = _saved_ex_guard_mode;
                _saved_guard_mode = -1;
                if (_no_guard_mode) {
                    ::config.practice.player2 = 0;
                } else {
                    ::config.practice.player2 = _saved_player2;
                }
            }
            // Idle: track user's current player2 (don't override — menu changes must stick)
            _saved_player2 = ::config.practice.player2;
            if (guard_active) {
                // Practice_CommonUpdate clears autoGuard for player2>=3.
                // Temporarily set player2=0 so the engine handles autoGuard.
                // Restored in PostFrame.
                if (::config.practice.player2 >= 3) {
                    ::config.practice.player2 = 0;
                    _idle_p2_changed = true;
                }
                _ApplyGuardType(p2, ::config.practice.ex_guard_mode);
            }
            if (_proxy) _ZeroProxy(p2);
        }

        // --- action injection ---
        if (_action_pending) {
            if (_proxy && p2.command) {
                // Save player2 before reversal overrides it (restored in PostFrame)
                if (_reversal_saved_p2 < 0) {
                    _reversal_saved_p2 = ::config.practice.player2;
                }
                _ZeroProxy(p2);

                if (_delay_remaining > 0) {
                    // Fuzzy defense during delay frames
                    // Only guard when Guard is enabled; otherwise just wait
                    ::config.practice.player2 = 0;
                    if (guard_active) {
                        if (_saved_guard_mode < 0) {
                            _saved_guard_mode = ::config.practice.guard_mode;
                            _saved_ex_guard_mode = ::config.practice.ex_guard_mode;
                        }
                        ::config.practice.guard_mode = 1;
                        _ApplyGuardType(p2, _saved_ex_guard_mode);
                    }
                    _delay_remaining--;
                } else {
                    ::config.practice.player2 = 4;
                    local dir = _picked_dir;
                    local abtn = _picked_btn;
                    // P button is handled by recover_mode override above,
                    // not by post-stand input injection.
                    if (abtn == 4) {
                        _action_pending = false;
                    } else {
                        ::print("[oki] injecting dir=" + dir + " btn=" + abtn + "\n");
                        _InjectAction(p2, dir, abtn);
                        _action_pending = false;
                    }
                }
            }
        }

        // --- translate ex_guard_mode for Practice_CommonUpdate ---
        // ex_guard_mode=2 causes Practice_CommonUpdate to set autoBaria=2 (random 50%).
        // Translate to 1 so it sets autoBaria=1 (guaranteed barrier guard).
        // _ApplyGuardType already set p2.autoBaria and forceBariaCount directly.
        _saved_user_eg = ::config.practice.ex_guard_mode;
        if (_saved_user_eg == 2) {
            ::config.practice.ex_guard_mode = 1;
        }

        // Translate guard_mode=3→1 for engine when once window is active.
        // The engine doesn't reliably handle guard_mode=3; we implement the
        // once semantics ourselves via _once_guard_frames.
        if (_saved_user_gm == 3 && guard_active) {
            ::config.practice.guard_mode = 1;
        }

        return true;
    }

    function PostFrame() {
        if (!_cfg.enabled) return;
        if (::battle.state != 8) return;

        // Restore user's ex_guard_mode (translated in PreFrame for engine)
        if (_saved_user_eg >= 0) {
            ::config.practice.ex_guard_mode = _saved_user_eg;
            _saved_user_eg = -1;
        }

        // Restore guard_mode (translated in PreFrame for engine)
        if (_saved_user_gm >= 0) {
            ::config.practice.guard_mode = _saved_user_gm;
            _saved_user_gm = -1;
        }

        // Restore player2 (translated to 0 in PreFrame for idle guard)
        if (_idle_p2_changed) {
            ::config.practice.player2 = _saved_player2;
            _idle_p2_changed = false;
        }

        // Restore player2 after reversal action completes (was set to 4 in PreFrame)
        if (_reversal_saved_p2 >= 0 && !_action_pending) {
            ::config.practice.player2 = _reversal_saved_p2;
            _reversal_saved_p2 = -1;
        }

        local team1 = ::battle.team[1];
        if (!team1 || !team1.current) return;

        local p2 = team1.current;
        local is_damage = p2.IsDamage();
        local is_stand = (p2.motion <= 1);
        local is_guard_motion = (p2.motion >= 100 && p2.motion <= 123);

        // End barrier window when character returns to idle/free state.
        // This prevents autoGuard from persisting after landing.
        if (_baria_frames > 0 && is_stand) {
            _baria_frames = 0;
            _post_baria_debug = 30;
            ::print("[oki] barrier window ended (idle/landed)\n");
        }

        // Practice_CommonUpdate for player2<3 with guard_mode=0 does NOT
        // clear autoGuard (switch has no case 0). Explicitly clear it
        // only when user has disabled guard, to prevent persistent guarding.
        if (_baria_frames == 0 && !_action_pending && ::config.practice.guard_mode == 0) {
            p2.autoGuard = false;
        }

        // Debug: PostFrame guard state during barrier window
        if (_baria_frames > 0 && _baria_frames <= 45) {
            ::print("[oki] POST f=" + (_baria_frames+1)
                + " motion=" + p2.motion
                + " flag&16=" + (p2.flagState & 16)
                + " disableGuard=" + p2.disableGuard
                + " autoGuard=" + p2.autoGuard
                + " autoBaria=" + p2.autoBaria
                + " forceBariaCount=" + p2.forceBariaCount
                + " guardBaria=" + p2.guardBaria
                + " input.x=" + p2.input.x
                + " IsGuard=" + p2.IsGuard()
                + " player2=" + ::config.practice.player2
                + "\n");
        }

        // Debug: Post-baria-window frames (after barrier guard ends)
        if (_post_baria_debug > 0) {
            ::print("[oki] AFTER f=" + _post_baria_debug
                + " motion=" + p2.motion
                + " disableGuard=" + p2.disableGuard
                + " autoGuard=" + p2.autoGuard
                + " guard_mode=" + ::config.practice.guard_mode
                + " ex_guard_mode=" + ::config.practice.ex_guard_mode
                + " player2=" + ::config.practice.player2
                + " IsGuard=" + p2.IsGuard()
                + "\n");
            _post_baria_debug--;
        }

        // --- Trigger detection: hit (on-hit) or blockstun (on-block) ---
        if (!_was_damage && is_damage) {
            // On-hit: pick from slots with trigger=0
            _PickRandomSlot(0);
        }
        if (!_was_guard_motion && is_guard_motion && !is_damage) {
            // On-block: pick from slots with trigger=1 (blockstun from attack)
            _PickRandomSlot(1);
        }

        // --- Recovery → wakeup ---
        // Hit recovery: was damaged → now not damaged
        if (_was_damage && !is_damage) {
            // P button swap is handled by recover_mode override (PreFrame).
            // The game's Practice_CommonUpdate + stateLabel handle the swap
            // seamlessly. No PostFrame action needed for btn==4.
            local btn = _picked_btn;
            if (_picked_trigger == 0 && btn != 4 && btn != 8) {
                _wakeup_active = true;
            }
        }
        // Block recovery: was guarding → now not guarding (and not hit)
        if (_was_guard_motion && !is_guard_motion && !is_damage) {
            local btn = _picked_btn;
            if (_picked_trigger == 1 && btn != 4 && btn != 8) {
                _wakeup_active = true;
            }
        }

        if (_wakeup_active && is_stand) {
            local dir = _picked_dir;
            local btn = _picked_btn;
            ::print("[oki] stand after " + (_picked_trigger == 0 ? "hit" : "block") +
                "! motion=" + p2.motion + " dir=" + dir + " btn=" + btn + "\n");

            // Clean up stale barrier state from previous wakeup
            _baria_frames = 0;

            // 5D barrier guard: call after actor update (PostFrame) to
            // survive CommonCpuLoop's input zeroing. Directional D actions
            // (4D/6D/7D/8D/9D/1D/2D/3D) are handled via state-function
            // calls in _CallDAction during PreFrame injection.
            if (btn == 3 && dir == 5) {
                try {
                    p2.Guard_Stance(null);
                    ::print("[oki] Guard_Stance called directly (5D)\n");
                } catch (e) {
                    ::print("[oki] Guard_Stance failed: " + e + "\n");
                }
            }

            _delay_remaining = _picked_delay;
            _action_pending = true;
            _wakeup_active = false;
        }

        // Guard mode "once" (guard_mode=3): start 30f guard window when hit or block connects.
        // Outside this window the dummy doesn't guard. Each new hit/block re-opens the window.
        if (!_was_damage && is_damage && ::config.practice.guard_mode == 3) {
            _once_guard_frames = 30;
            ::print("[oki] guard once: 30f window started (hit)\n");
        }
        if (!_was_guard_motion && is_guard_motion && !is_damage && ::config.practice.guard_mode == 3) {
            _once_guard_frames = 30;
            ::print("[oki] guard once: 30f window started (block)\n");
        }

        _was_damage = is_damage;
        _was_guard_motion = is_guard_motion;
    }

    function _RestoreRecoverMode() {
        if (_saved_recover_mode >= 0) {
            ::config.practice.recover_mode = _saved_recover_mode;
            _saved_recover_mode = -1;
        }
    }

    // Map user's ex_guard_mode to engine autoBaria + forceBariaCount.
    // Engine: autoBaria=1 → always BariaGuard_Init.
    //         forceBariaCount>=10 → enhanced barrier (JustGuardBaria visual = 精防).
    // User: 0=Off (normal), 1=Barrier Guard (盾防), 2=Just Guard (精防).
    function _ApplyGuardType(p2, user_eg) {
        if (user_eg == 0) {
            p2.autoBaria = 0;
        } else {
            // Both Barrier (1) and Just (2) use autoBaria=1
            p2.autoBaria = 1;
            if (user_eg == 2) {
                // Just Guard = enhanced barrier guard
                p2.forceBariaCount = 15;
                p2.guardBaria = true;
            }
        }
    }

    function _PickRandomSlot(trigger_type = 0) {
        local active = [];
        local weights = [];
        for (local s = 0; s < 5; s++) {
            local key = "oki_s" + s + "_btn";
            local tk = "oki_s" + s + "_trigger";
            local t = (tk in ::config.practice) ? ::config.practice[tk] : 0;
            if (t != trigger_type) continue;
            if ((key in ::config.practice) && ::config.practice[key] != 8) {
                local wk = "oki_s" + s + "_weight";
                local w = (wk in ::config.practice) ? ::config.practice[wk] : 5;
                if (w < 1) w = 1;
                active.append(s);
                weights.append(w);
            }
        }
        if (active.len() == 0) {
            _picked_dir = 5;
            _picked_btn = 8;
            _picked_delay = 0;
            _picked_trigger = trigger_type;
            return;
        }
        local total = 0;
        foreach (w in weights) total += w;
        _frame_tick = (_frame_tick * 1103515245 + 12345) & 0x7fffffff;
        local r = _frame_tick % total;
        local acc = 0;
        local chosen = active[0];
        for (local i = 0; i < active.len(); i++) {
            acc += weights[i];
            if (r < acc) { chosen = active[i]; break; }
        }
        _picked_dir = ::config.practice["oki_s" + chosen + "_dir"];
        _picked_btn = ::config.practice["oki_s" + chosen + "_btn"];
        _picked_delay = ::config.practice["oki_s" + chosen + "_delay"];
        _picked_trigger = trigger_type;
        local trig_label = trigger_type == 0 ? "hit" : "block";
        ::print("[oki] picked slot " + chosen + " dir=" + _picked_dir + " btn=" + _picked_btn + " delay=" + _picked_delay + " trig=" + trig_label + " (w=" + weights[active.find(chosen)] + "/" + total + ")\n");
    }

    function _ZeroProxy(p2 = null) {
        _proxy.x = 0; _proxy.y = 0;
        _proxy.b0 = 0; _proxy.b1 = 0; _proxy.b2 = 0;
        _proxy.b3 = 0; _proxy.b4 = 0; _proxy.b5 = 0;
        _proxy.b0r = 0; _proxy.b1r = 0; _proxy.b2r = 0;
        _proxy.b3r = 0; _proxy.b4r = 0; _proxy.b5r = 0;
        // Clear game-side input/command to prevent button persistence
        if (p2 && p2.command) {
            p2.input.b0 = 0; p2.input.b1 = 0; p2.input.b2 = 0;
            p2.input.b3 = 0; p2.input.b4 = 0; p2.input.b5 = 0;
            p2.input.x = 0; p2.input.y = 0;
            p2.command.rsv_k0 = 0; p2.command.rsv_k1 = 0; p2.command.rsv_k2 = 0;
            p2.command.rsv_k3 = 0; p2.command.rsv_k4 = 0; p2.command.rsv_k5 = 0;
            p2.command.rsv_x = 0; p2.command.rsv_y = 0;
        }
    }

    // Direct state-function injection for D button (b4).
    // CommonCpuLoop zeros input.b4 irrevocably and command.Update never
    // restores it, so the only way to trigger D actions is to call the
    // game's state-transition functions directly.
    function _CallDAction(p2, d) {
        p2.input.x = d.x;
        p2.input.y = d.y;

        if (d.y < 0) {
            p2.SlideUp_Init(null);
            ::print("[oki] D-inject: SlideUp x=" + d.x + "\n");
        } else if (d.y > 0) {
            p2.SlideFall_Init(null);
            ::print("[oki] D-inject: SlideFall x=" + d.x + "\n");
        } else if (d.x > 0) {
            p2.DashFront_Init(null);
            ::print("[oki] D-inject: DashFront\n");
        } else if (d.x < 0) {
            p2.DashBack_Init(null);
            ::print("[oki] D-inject: DashBack\n");
        }
        // 5D handled in PostFrame via Guard_Stance

        // Start guard window only when Guard is enabled.
        // Guard=false → just jump/dash, no auto-guard.
        // Guard=true → guard with type from ex_guard_mode (Off/Just/Barrier).
        if ((d.x != 0 || d.y != 0) && ::config.practice.guard_mode > 0) {
            _saved_guard_mode = ::config.practice.guard_mode;
            _saved_ex_guard_mode = ::config.practice.ex_guard_mode;
            _baria_frames = 45;
            ::print("[oki] guard window started (45 frames)\n");
        }
    }

    function _DirToXY(dir) {
        local x = 0, y = 0;
        if (dir == 1 || dir == 4 || dir == 7) x = -6;
        if (dir == 3 || dir == 6 || dir == 9) x = 6;
        if (dir == 7 || dir == 8 || dir == 9) y = -10;
        if (dir == 1 || dir == 2 || dir == 3) y = 10;
        return { x = x, y = y };
    }

    function _InjectAction(p2, dir, btn) {
        local d = _DirToXY(dir);
        // Convert numpad direction to character-relative coordinates
        // P2 faces left (direction=-1), so forward(6) = x<0, back(4) = x>0
        d.x = d.x * p2.direction;

        p2.input.b0 = 0; p2.input.b1 = 0; p2.input.b2 = 0;
        p2.input.b3 = 0; p2.input.b4 = 0; p2.input.b5 = 0;
        p2.input.x = 0; p2.input.y = 0;
        p2.command.rsv_k0 = 0; p2.command.rsv_k1 = 0; p2.command.rsv_k2 = 0;
        p2.command.rsv_k3 = 0; p2.command.rsv_k4 = 0; p2.command.rsv_k5 = 0;
        p2.command.rsv_x = 0; p2.command.rsv_y = 0;

        _proxy.x = d.x;  _proxy.y = d.y;
        p2.input.x = d.x;  p2.input.y = d.y;
        p2.command.rsv_x = d.x;  p2.command.rsv_y = d.y;

        if (btn == 0) {
            _proxy.b0 = 2; p2.input.b0 = 1; p2.command.rsv_k0 = 5;
        } else if (btn == 1) {
            _proxy.b1 = 2; p2.input.b1 = 1; p2.command.rsv_k1 = 5;
        } else if (btn == 2) {
            _proxy.b2 = 2; p2.input.b2 = 1; p2.command.rsv_k2 = 5;
        } else if (btn == 3) {
            _CallDAction(p2, d);
        } else if (btn == 4) {
            // P button swap wake-up is handled by recover_mode override.
            // This path should not be reached (blocked in PreFrame),
            // but kept as safety fallback.
            _proxy.b3 = 2; p2.input.b3 = 1; p2.command.rsv_k3 = 7;
        } else if (btn == 5) {
            _proxy.b0 = 2; p2.input.b0 = 1; p2.command.rsv_k0 = 5;
            _proxy.b1 = 2; p2.input.b1 = 1; p2.command.rsv_k1 = 5;
        } else if (btn == 6) {
            _proxy.b1 = 2; p2.input.b1 = 1; p2.command.rsv_k1 = 5;
            _proxy.b2 = 2; p2.input.b2 = 1; p2.command.rsv_k2 = 5;
        } else if (btn == 7) {
            _proxy.b2 = 2; p2.input.b2 = 1; p2.command.rsv_k2 = 5;
            _proxy.b3 = 2; p2.input.b3 = 1; p2.command.rsv_k3 = 7;
        }
    }
};
