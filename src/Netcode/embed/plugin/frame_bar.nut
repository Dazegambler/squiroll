// Frame Bar - SF6-style visual frame meter bar (standalone module)
//
// Dual-team tracking with sprite-based timeline rendering:
//   - Phase colors: green (startup), red (active), blue (recovery), yellow (stun)
//   - Cancel window (left quarter) and invincibility (right quarter) overlays
//   - Segment count labels for phases > 3f
//   - Frame advantage calculation between attacker and defender
//   - Timeline alignment so both bars share the same time axis
//
// This module is independent of frame_data.nut (text display).
// frame_data.nut keeps its own single-team tracking and config menu.

config = {
    enabled = true
    x = 280
    y = 555
    sx = 0.75
    sy = 0.75
    width = 720
};

// Patches
::plugin.Patch("data/script/actor.nut",function() {
    local createplayer = CreatePlayer;
    function CreatePlayer(...) {
    	vargv.insert(0,this);
    	local t = createplayer.acall(vargv);

    	t.player_class = class extends t.player_class {
    		_tid = -1;
    		function SetMotion(motion, take) {
    			base.SetMotion(motion,take);
    			if (!("_tid" in this)) return;
    			local task = ::battle.modifiers.frame_bar.task;
    			if (!task || !task.current_data) return;

    			// Resolve team index on first call
    			if (_tid < 0) {
    				if (task.teams[0] && task.teams[0] == team) _tid = 0;
    				else if (task.teams[1] && task.teams[1] == team) _tid = 1;
    			}
    			if (_tid < 0) return;

    			local cd = task.current_data[_tid];
    			if (cd && cd.motion != motion && cd.take >= keyTake) {
    				if (motion >= 1000) {
    					// Cancel (attack->attack) or gap (idle->attack)?
    					if (cd.frame_count > 0 && cd.motion >= 1000) {
    						task.ContinueMove(_tid);
    					} else {
    						task.IsNewMove(_tid);
    					}
    				} else {
    					cd.motion = motion;
    				}
    			}
    		}
    	};

    	return t;
    }
});

// Base class for display elements
class display_module {
    text = null;
    constructor() {
        text = ::UI.Text({
            sy = 0.75
            max_length = 1010
        });
        text.ConnectRenderSlot(::graphics.slot.info,1);
    }
    function Render(data) {}
    function Clear() {text.Set("");}
}

class modifier extends modifier {
    // Sprite-based frame bar with phase colors, overlays, and frame advantage
    framebar = class extends display_module {
        pool = null;
        pool_size = 60;
        tex = null;
        label = null;
        team_idx = 0;
        label_below = false;
        count_labels = null;
        adv_label = null;
        bg_bar = null;
        cancel_pool = null;
        inv_pool = null;

        PIP_W = 12.0;
        BAR_H = 22.0;
        GAP = 1.0;
        TEX_SIZE = 16.0;

        constructor(_team_idx = 0, _label_below = false) {
            team_idx = _team_idx;
            label_below = _label_below;

            pool = [];
            tex = ::manbow.Texture();
            tex.Load("data/actor/status/texture/gauge.png");

            label = ::UI.Text();
            label.sy = 0.75;
            label.red = label.green = label.blue = label.alpha = 1;
            label.ConnectRenderSlot(::graphics.slot.info, 2);

            adv_label = ::UI.Text();
            adv_label.sy = 0.75;
            adv_label.ConnectRenderSlot(::graphics.slot.info, 2);

            bg_bar = ::manbow.Sprite();
            bg_bar.Initialize(tex, 264, 360, 16, 16);
            bg_bar.filter = 1;
            bg_bar.ConnectRenderSlot(::graphics.slot.info, 0);
            bg_bar.alpha = 0;

            for (local i = 0; i < pool_size; i++) {
                local s = ::manbow.Sprite();
                s.Initialize(tex, 264, 360, 16, 16);
                s.filter = 1;
                s.ConnectRenderSlot(::graphics.slot.info, 1);
                s.alpha = 0;
                pool.append(s);
            }

            count_labels = [];
            for (local i = 0; i < 10; i++) {
                local t = ::UI.Text();
                t.sy = 0.5;
                t.sx = 0.5;
                t.red = 1; t.green = 1; t.blue = 1; t.alpha = 0.9;
                t.ConnectRenderSlot(::graphics.slot.info, 2);
                count_labels.append(t);
            }

            cancel_pool = [];
            for (local i = 0; i < pool_size; i++) {
                local s = ::manbow.Sprite();
                s.Initialize(tex, 264, 360, 16, 16);
                s.filter = 1;
                s.ConnectRenderSlot(::graphics.slot.info, 1);
                s.alpha = 0;
                cancel_pool.append(s);
            }

            inv_pool = [];
            for (local i = 0; i < pool_size; i++) {
                local s = ::manbow.Sprite();
                s.Initialize(tex, 264, 360, 16, 16);
                s.filter = 1;
                s.ConnectRenderSlot(::graphics.slot.info, 1);
                s.alpha = 0;
                inv_pool.append(s);
            }
        }

        function Render(data, adv = null) {
            local cfg = ::plugin.cfg.frame_bar;
            local bar_x = cfg.data.x.tofloat();
            local base_y = cfg.data.y.tofloat();

            // Layout: 1P-label -> 1P-bar -> gap -> 2P-bar -> 2P-label
            local bar_y;
            if (team_idx == 0) {
                bar_y = base_y + 32;
            } else {
                bar_y = base_y + 32 + 22 + 4;
            }

            // Black background bar (border effect)
            bg_bar.x = bar_x;
            bg_bar.y = bar_y;
            bg_bar.sx = (pool_size * PIP_W) / TEX_SIZE;
            bg_bar.sy = BAR_H / TEX_SIZE;
            bg_bar.red = 0; bg_bar.green = 0; bg_bar.blue = 0;
            bg_bar.alpha = 0.9;

            local pw = (PIP_W - GAP) / TEX_SIZE;
            local ph = (BAR_H - 2) / TEX_SIZE;
            local pip_y = bar_y + 1;
            local prefix = team_idx == 0 ? "1P" : "2P";

            // No data: show empty grid with label only
            if (!data || data.frame_count <= 0) {
                for (local i = 0; i < pool_size; i++) {
                    local s = pool[i];
                    s.x = bar_x + i * PIP_W + GAP * 0.5;
                    s.y = pip_y;
                    s.sx = pw;
                    s.sy = ph;
                    s.red = 0.35; s.green = 0.35; s.blue = 0.35;
                    s.alpha = 0.5;
                }
                label.Set(prefix);
                label.x = bar_x;
                label.sx = 0.6;
                label.y = label_below ? bar_y + BAR_H + 1 : bar_y - 32;
                adv_label.Set("");
                foreach(t in count_labels) t.Set("");
                foreach(cs in cancel_pool) cs.alpha = 0;
                foreach(cs in inv_pool) cs.alpha = 0;
                return;
            }

            local fc = data.pip_colors;
            local offset = data.timeline_offset;
            // Visual end = offset + number of actual pips
            local visual_end = offset + fc.len();

            // Draw with timeline offset
            if (visual_end <= 60) {
                // Blank pips for offset (time alignment)
                for (local i = 0; i < offset && i < pool_size; i++) {
                    local s = pool[i];
                    s.x = bar_x + i * PIP_W + GAP * 0.5;
                    s.y = pip_y;
                    s.sx = pw; s.sy = ph;
                    s.red = 0.35; s.green = 0.35; s.blue = 0.35;
                    s.alpha = 0.4;
                }
                // Actual pips
                for (local i = 0; i < fc.len() && (offset + i) < pool_size; i++) {
                    local s = pool[offset + i];
                    s.x = bar_x + (offset + i) * PIP_W + GAP * 0.5;
                    s.y = pip_y;
                    s.sx = pw; s.sy = ph;
                    s.red = fc[i][0]; s.green = fc[i][1]; s.blue = fc[i][2];
                    s.alpha = 0.85;
                }
                // Empty grid after all pips
                for (local i = visual_end; i < pool_size; i++) {
                    local s = pool[i];
                    s.x = bar_x + i * PIP_W + GAP * 0.5;
                    s.y = pip_y;
                    s.sx = pw; s.sy = ph;
                    s.red = 0.35; s.green = 0.35; s.blue = 0.35;
                    s.alpha = 0.5;
                }
            } else {
                // Overflow with offset: ghost + bright
                local current_start = ((visual_end - 1) / 60).tointeger() * 60;
                local ghost_start = current_start - 60;
                if (ghost_start < 0) ghost_start = 0;

                // Ghost: dimmed
                for (local vi = ghost_start; vi < current_start && vi < visual_end; vi++) {
                    local pip = vi - ghost_start;
                    if (pip >= 60) break;
                    local s = pool[pip];
                    s.x = bar_x + pip * PIP_W + GAP * 0.5;
                    s.y = pip_y;
                    s.sx = pw; s.sy = ph;
                    if (vi < offset) {
                        s.red = 0.12; s.green = 0.12; s.blue = 0.12;
                        s.alpha = 0.08;
                    } else {
                        local ci = vi - offset;
                        if (ci < fc.len()) {
                            s.red = fc[ci][0] * 0.45;
                            s.green = fc[ci][1] * 0.45;
                            s.blue = fc[ci][2] * 0.45;
                            s.alpha = 0.6;
                        }
                    }
                }

                // Current cycle: bright
                for (local vi = current_start; vi < visual_end; vi++) {
                    local pip = vi - current_start;
                    if (pip >= 60) break;
                    local s = pool[pip];
                    s.x = bar_x + pip * PIP_W + GAP * 0.5;
                    s.y = pip_y;
                    s.sx = pw; s.sy = ph;
                    if (vi < offset) {
                        s.red = 0.12; s.green = 0.12; s.blue = 0.12;
                        s.alpha = 0.15;
                    } else {
                        local ci = vi - offset;
                        if (ci < fc.len()) {
                            s.red = fc[ci][0]; s.green = fc[ci][1]; s.blue = fc[ci][2];
                            s.alpha = 0.85;
                        }
                    }
                }
            }

            // Cancel + Invincibility overlay (top half, split left/right)
            local ph_half = (BAR_H - 2) / 2.0 / TEX_SIZE;
            local pw_q = (PIP_W - GAP) / 2.0 / TEX_SIZE;
            local half_w = (PIP_W - GAP) / 2.0;
            local c_start = 0;
            local c_end = visual_end;
            if (visual_end > pool_size) {
                c_start = ((visual_end - 1) / pool_size).tointeger() * pool_size;
            }
            for (local i = 0; i < pool_size; i++) {
                local vi = c_start + i;
                local cs = cancel_pool[i];
                local is = inv_pool[i];
                cs.alpha = 0;
                is.alpha = 0;
                if (vi >= c_end || vi < offset) continue;
                local ci = vi - offset;
                if (ci >= fc.len() || ci >= data.flag_states.len()) continue;
                local fs = data.flag_states[ci];
                local pip_x = bar_x + i * PIP_W + GAP * 0.5;

                // Left quarter: cancel type
                local cancel_flag = fs & 0x4420;
                if (cancel_flag) {
                    cs.x = pip_x;
                    cs.y = pip_y;
                    cs.sx = pw_q;
                    cs.sy = ph_half;
                    local nt = 0;
                    if (cancel_flag & 0x20) nt++;
                    if (cancel_flag & 0x400) nt++;
                    if (cancel_flag & 0x4000) nt++;
                    if (nt >= 2) { cs.red = 1.0; cs.green = 1.0; cs.blue = 1.0; }
                    else if (cancel_flag & 0x20) { cs.red = 0.75; cs.green = 0.3; cs.blue = 1.0; }
                    else if (cancel_flag & 0x400) { cs.red = 0.2; cs.green = 0.85; cs.blue = 0.9; }
                    else if (cancel_flag & 0x4000) { cs.red = 1.0; cs.green = 0.55; cs.blue = 0.1; }
                    cs.alpha = 0.9;
                }

                // Right quarter: invincibility type
                local inv_flag = fs & 0x1B000;
                if (inv_flag) {
                    is.x = pip_x + half_w;
                    is.y = pip_y;
                    is.sx = pw_q;
                    is.sy = ph_half;
                    local nt = 0;
                    if (inv_flag & 0x1000) nt++;
                    if (inv_flag & 0x2000) nt++;
                    if (inv_flag & 0x8000) nt++;
                    if (inv_flag & 0x10000) nt++;
                    if (nt >= 2) { is.red = 1.0; is.green = 1.0; is.blue = 1.0; }
                    else if (inv_flag & 0x8000) { is.red = 1.0; is.green = 0.4; is.blue = 0.6; }
                    else if (inv_flag & 0x10000) { is.red = 0.5; is.green = 1.0; is.blue = 0.3; }
                    else if (inv_flag & 0x2000) { is.red = 1.0; is.green = 0.85; is.blue = 0.3; }
                    else if (inv_flag & 0x1000) { is.red = 0.75; is.green = 0.75; is.blue = 0.85; }
                    is.alpha = 0.9;
                }
            }

            // Segment count labels (>3f per phase)
            local label_idx = 0;
            local vis_start = 0;
            local vis_end = visual_end;
            if (visual_end > pool_size) {
                vis_start = ((visual_end - 1) / pool_size).tointeger() * pool_size;
            }
            local seg_color = null;
            local seg_len = 0;
            for (local vi = vis_start; vi < vis_end; vi++) {
                local color = null;
                if (vi >= offset) {
                    local ci = vi - offset;
                    if (ci < fc.len()) color = fc[ci];
                }
                local same = (color && seg_color &&
                    color[0] == seg_color[0] &&
                    color[1] == seg_color[1] &&
                    color[2] == seg_color[2]);
                if (same) {
                    seg_len++;
                } else {
                    if (seg_len > 3 && seg_color && label_idx < count_labels.len()) {
                        local pool_pos = (vi - 1) - vis_start;
                        if (pool_pos >= 0 && pool_pos < pool_size) {
                            local t = count_labels[label_idx];
                            t.Set(format("%d", seg_len));
                            t.sx = 0.5;
                            t.x = bar_x + pool_pos * PIP_W + PIP_W / 2 - (t.width * t.sx) / 2;
                            t.y = pip_y + (BAR_H - 2) / 2 - 5;
                            label_idx++;
                        }
                    }
                    seg_color = color;
                    seg_len = color ? 1 : 0;
                }
            }
            // Handle last segment
            if (seg_len > 3 && seg_color && label_idx < count_labels.len()) {
                local pool_pos = (vis_end - 1) - vis_start;
                if (pool_pos >= 0 && pool_pos < pool_size) {
                    local t = count_labels[label_idx];
                    t.Set(format("%d", seg_len));
                    t.sx = 0.5;
                    t.x = bar_x + pool_pos * PIP_W + PIP_W / 2 - (t.width * t.sx) / 2;
                    t.y = pip_y + (BAR_H - 2) / 2 - 5;
                    label_idx++;
                }
            }
            for (local i = label_idx; i < count_labels.len(); i++) {
                count_labels[i].Set("");
            }

            // Summary text
            local startup_f = 0;
            foreach(idx, val in data.frames[0]) {
                if (!(idx & 1) && val > 0) startup_f += val;
            }
            local active_f = 0;
            foreach(idx, val in data.frames[1]) {
                if (!(idx & 1) && val > 0) active_f += val;
            }
            local recovery_f = 0;
            foreach(idx, val in data.frames[2]) {
                if (!(idx & 1) && val > 0) recovery_f += val;
            }
            local stun_f = data.stun_count;
            label.Set(format("%s S:%d A:%d R:%d Stun:%d",
                prefix, startup_f, active_f, recovery_f, stun_f));
            label.x = bar_x;
            label.sx = 0.6;
            label.y = label_below ? bar_y + BAR_H + 1 - 6 : bar_y - 32;
            label.red = 1; label.green = 1; label.blue = 1;

            if (adv != null) {
                local display_adv = team_idx == 1 ? -adv : adv;
                local sign = display_adv >= 0 ? "+" : "";
                adv_label.Set(format(" | %s%d", sign, display_adv));
                adv_label.sx = 0.6;
                adv_label.y = label.y;
                adv_label.x = label.x + label.width * label.sx;
                if (display_adv > 0) {
                    adv_label.red = 0.3; adv_label.green = 0.5; adv_label.blue = 1.0;
                } else if (display_adv < 0) {
                    adv_label.red = 1.0; adv_label.green = 0.2; adv_label.blue = 0.2;
                } else {
                    adv_label.red = 1; adv_label.green = 1; adv_label.blue = 1;
                }
                adv_label.alpha = 1;
            } else {
                adv_label.Set("");
            }
        }

        function Clear() {
            label.Set("");
            adv_label.Set("");
            bg_bar.alpha = 0;
            foreach(s in pool) s.alpha = 0;
            foreach(cs in cancel_pool) cs.alpha = 0;
            foreach(cs in inv_pool) cs.alpha = 0;
            foreach(t in count_labels) t.Set("");
        }
    };

    // Per-team state (index 0 = 1P, index 1 = 2P)
    teams = null;
    current_data = null;
    actives = null;
    tracked_last_frame = null;

    parts = null;

    constructor() {
        teams = [null, null];
        current_data = [null, null];
        actives = [false, false];
        tracked_last_frame = [false, false];

        parts = {};
        parts.framebar1 <- framebar(0, false);  // 1P: label above
        parts.framebar2 <- framebar(1, true);   // 2P: label below
    }

    function Release() {foreach(key,_ in parts)delete parts[key];}

    function Tick(tid, data) {
        local current = teams[tid].current;

        data.frame_count++;
        data.flag_state = current.flagState;
        data.flag_attack = current.flagAttack;
        data.flag_states.append(current.flagState);
        if(::setting.frame_data.GetMetadata(current)[0])data.metadata = ::setting.frame_data.GetMetadata(current);

        // Phase detection with had_active state machine
        local phase = 0; // 0=startup, 1=active, 2=recovery
        if (!actives[tid]) actives[tid] = ::setting.frame_data.IsFrameActive(current);
        if (actives[tid]) {
            phase = 1;
            data.had_active = true;
        } else if (data.had_active) {
            phase = 2;
        }

        // Record per-frame color
        local phase_colors = [
            [0.2, 0.75, 0.2],  // 0: startup - green
            [0.85, 0.15, 0.15], // 1: active - red
            [0.2, 0.4, 0.85],  // 2: recovery - blue
        ];
        data.pip_colors.append(phase_colors[phase]);

        // Also update frames array (for summary labels)
        local top = data.frames[phase].len() - 1;
        data.frames[phase][top]++;

        // Armor handling
        if (current.armor) {
            if (!data.armor.len() ||
                data.armor.top()[0] != current.armor ||
                data.armor.top()[2] != data.frame_count - 1
            ){
                data.armor.append([current.armor,data.frame_count,data.frame_count]);
            }else {
                data.armor.top()[2] = data.frame_count;
            }
        }

        // Cancel handling
        if (data.flag_state) {
            local cancels = data.flag_state & 0x4420;
            if (!data.cancels.len() ||
                data.cancels.top()[0] != cancels ||
                data.cancels.top()[2] != data.frame_count - 1
            ){
                data.cancels.append([cancels,data.frame_count,data.frame_count]);
            }else {
                data.cancels.top()[2] = data.frame_count;
            }
        }
    }

    function IsNewMove(tid) {
        current_data[tid] = NewData(tid);
        Tick(tid, current_data[tid]);
    }

    function ContinueMove(tid) {
        local data = current_data[tid];
        data.motion = teams[tid].current.motion;
        // Keep: frame_count, pip_colors, cancels, armor, metadata
        // Reset phase state for new move
        data.had_active = false;
        data.frames = [[0],[0],[0]];
        actives[tid] = false;
        Tick(tid, data);
    }

    function TickStun(tid, data) {
        local current = teams[tid].current;
        data.frame_count++;
        data.flag_state = current.flagState;
        data.flag_attack = current.flagAttack;
        data.flag_states.append(current.flagState);
        if(::setting.frame_data.GetMetadata(current)[0])data.metadata = ::setting.frame_data.GetMetadata(current);
        // Yellow = hitstun/blockstun
        data.pip_colors.append([0.85, 0.8, 0.1]);
        data.stun_count++;
    }

    function NewData(tid) {
        local current = teams[tid].current;
        return {
            motion = current.motion
            take = current.keyTake
            frame_count = 0
            frames = [[0],[0],[0]]
            pip_colors = []
            had_active = false
            cancels = []
            armor = []
            metadata = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            flag_state = 0
            flag_attack = 0
            flag_states = []
            stun_count = 0
            timeline_offset = 0  // pip offset for time alignment
        };
    }

    function ClearAll() {
        foreach(part in parts)part.Clear();
    }

    function PreFrame() {
        return true;
    }

    function Update() {
        local cfg = ::plugin.cfg.frame_bar;
        if (!::battle.team) return;

        // Initialize team references
        for (local tid = 0; tid < 2; tid++) {
            if (!teams[tid] && "current" in ::battle.team[tid]) {
                teams[tid] = ::battle.team[tid];
            }
        }

        // Save frame_counts BEFORE processing this frame (for timeline alignment)
        local saved_fc = [0, 0];
        for (local tid = 0; tid < 2; tid++) {
            if (current_data[tid]) saved_fc[tid] = current_data[tid].frame_count;
        }

        // Process each team
        for (local tid = 0; tid < 2; tid++) {
            if (!teams[tid]) continue;
            local current = teams[tid].current;

            if (!current_data[tid]) {
                current_data[tid] = NewData(tid);
            }

            local data = current_data[tid];

            // Detect stun: multiple indicators
            local in_stun = false;
            // Hitstun: recover > 0 (set by SetRecoverFrame)
            try { if (current.recover > 0) in_stun = true; } catch(e) {}
            // Blockstun: guard motions 100-103 (just), 110-113 (barrier), 120-123 (normal)
            if (current.motion >= 100 && current.motion <= 103) in_stun = true;
            if (current.motion >= 110 && current.motion <= 113) in_stun = true;
            if (current.motion >= 120 && current.motion <= 123) in_stun = true;
            // Also check flagState block bit
            if (current.flagState & 0x800) in_stun = true;
            // Combo indicators as fallback
            try { if (teams[tid].combo_count > 0) in_stun = true; } catch(e) {}
            try { if (teams[tid].combo_stun > 0) in_stun = true; } catch(e) {}

            // Fresh stun start after a gap -> reset data with timeline offset
            if (in_stun && !tracked_last_frame[tid]) {
                current_data[tid] = NewData(tid);
                data = current_data[tid];
                // Align: offset = the OTHER player's frame_count at this moment
                data.timeline_offset = saved_fc[1 - tid];
            }

            if (cfg.data.enabled) {
                // Show hitStop frames (don't skip them) -- only skip super freeze
                if (!teams[tid].time_stop_count) {
                    if (in_stun) {
                        TickStun(tid, data);
                        tracked_last_frame[tid] = true;
                    } else if (current.motion >= 1000 && ::setting.frame_data.hasData(current)) {
                        Tick(tid, data);
                        tracked_last_frame[tid] = true;
                    } else {
                        tracked_last_frame[tid] = false;
                    }
                }
            }
        }

        // Calculate frame advantage
        local frame_adv = null;
        local d0 = current_data[0];
        local d1 = current_data[1];
        if (d0 && d1) {
            // Find who is attacking and who is stunned
            local attacker_tid = -1;
            local defender_tid = -1;
            if (d1.stun_count > 0 && d0.frame_count > 0 && d0.frame_count > d1.timeline_offset) {
                attacker_tid = 0; defender_tid = 1;
            } else if (d0.stun_count > 0 && d1.frame_count > 0 && d1.frame_count > d0.timeline_offset) {
                attacker_tid = 1; defender_tid = 0;
            }
            if (attacker_tid >= 0) {
                local atk = current_data[attacker_tid];
                local def = current_data[defender_tid];
                // attacker's visual end = frame_count
                // defender's visual end = timeline_offset + stun_count
                local atk_end = atk.frame_count;
                local def_end = def.timeline_offset + def.stun_count;
                frame_adv = def_end - atk_end;
            }
        }

        // Render
        if (cfg.data.enabled) {
            parts.framebar1.Render(current_data[0], frame_adv);
            parts.framebar2.Render(current_data[1], frame_adv);
        } else {
            ClearAll();
            current_data = [null, null];
        }
        actives = [false, false];
    }

    function Enabled(param) {
        local enabled = (param.game_mode == 40 || ::replay.GetState() == ::replay.PLAY);
        if (param.game_mode == 40) {
            local practicerestart = PracticeRestart;
            function PracticeRestart() {
                local bar_task = modifiers.frame_bar.task;
                if (bar_task) {
                    bar_task.ClearAll();
                    bar_task.current_data = [null, null];
                    bar_task.actives = [false, false];
                    bar_task.tracked_last_frame = [false, false];
                }
                practicerestart();
            };
        }
        return enabled;
    }
};
