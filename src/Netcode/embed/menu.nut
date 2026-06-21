common <- {};
::manbow.CompileFile("data/system/component/menu_common.nut", common);
::UI <- {};
::manbow.CompileFile("squiroll/UI/ui.nut", ::UI);
local scene = [];
cursor <- {};
::manbow.CompileFile("data/system/cursor/cursor.nut", cursor);
scene.append(cursor);
title <- {};
::manbow.CompileFile("data/system/title/title.nut", title);
story_select <- {};
::manbow.CompileFile("data/system/select/script/story_select_action.nut", story_select);
character_select <- {};
::manbow.CompileFile("data/system/select/script/character_select_action.nut", character_select);
back <- {};
::manbow.CompileFile("data/system/back/back.nut", back);
network <- {};
::manbow.CompileFile("data/system/network/network.nut", network);
scene.append(network);
watch <- {};
::manbow.CompileFile("data/system/watch/watch.nut", watch);
scene.append(watch);
music_room <- {};
::manbow.CompileFile("data/system/music_room/music_room.nut", music_room);
scene.append(music_room);
replay_select <- {};
::manbow.CompileFile("data/system/replay_select/replay_select.nut", replay_select);
scene.append(replay_select);
pause <- {};
::manbow.CompileFile("data/system/pause/pause.nut", pause);
scene.append(pause);
tutorial <- {};
::manbow.CompileFile("data/system/tutorial/tutorial.nut", tutorial);
scene.append(tutorial);
practice <- {};
::manbow.CompileFile("data/system/practice/practice.nut", practice);
scene.append(practice);
config <- {};
::manbow.CompileFile("data/system/config/config.nut", config);
scene.append(config);
key_config <- {};
::manbow.CompileFile("data/system/key_config/key_config.nut", key_config);
scene.append(key_config);
help <- {};
::manbow.CompileFile("data/system/help/help.nut", help);
scene.append(help);
mod_config <- {};
::manbow.CompileFile("squiroll/config/mod_config.nut", mod_config);
scene.append(mod_config);
network_config <- {};
::manbow.CompileFile("squiroll/config/network_config.nut", network_config);
scene.append(network_config);
credits <- {};
::manbow.CompileFile("squiroll/credits.nut",credits);
scene.append(credits);

pause_hack <- false;
PauseInitializeOrig <- pause.Initialize;
pause.Initialize = function(_mode) {
	::menu.pause_hack = true;
	::overlay.clear();
	::menu.PauseInitializeOrig.call(this, _mode);
}
PracticeInitializeOrig <- practice.Initialize;
practice.Initialize = function() {
	::menu.pause_hack = true;
	::overlay.clear();

	// Disconnect and remove old oki sprites to prevent accumulation
	if ("_oki_sprites" in ::menu) {
		foreach (s in ::menu._oki_sprites) {
			try { s.DisconnectRenderSlot(); } catch(e) {}
			try { s.x = -9999; } catch(e) {}
		}
	}
	::menu._oki_sprites <- [];

	// Clean up previous oki items from item_list[3] so PracticeInitializeOrig
	// sees the original list and doesn't accumulate duplicates across pauses.
	local il = this.item_list[3];
	for (local i = il.len() - 1; i >= 0; i--) {
		if (il[i] == "oki_dir" || il[i] == "oki_btn" || il[i] == "oki_slot" || il[i] == "oki_wt" || il[i] == "oki_dly" || il[i] == "oki_trg") il.remove(i);
	}

	::menu.PracticeInitializeOrig.call(this);

	// Always re-insert Oki items — PracticeInitializeOrig resets page[3].cursor
	// and BeginAnime rebuilds anime.page[3], so we must rebuild every time.
	if (!("oki_slot" in ::config.practice)) {
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

	// 1. Insert into item_list[3]
	// indices: 5=slot, 6=dir, 7=btn, 8=wt, 9=dly, 10=trg
	il.insert(5, "oki_trg");
	il.insert(5, "oki_dly");
	il.insert(5, "oki_wt");
	il.insert(5, "oki_btn");
	il.insert(5, "oki_dir");
	il.insert(5, "oki_slot");

	// 2. Create item-level cursors — type=1 (UpdateH, responds to LR)
	local cursor_slot = this.Cursor(1, 5, ::input_all);
	local cursor_dir = this.Cursor(1, 9, ::input_all);
	local cursor_btn = this.Cursor(1, 9, ::input_all);
	local cursor_wt = this.Cursor(1, 10, ::input_all);
	local cursor_dly = this.Cursor(1, 16, ::input_all);
	local cursor_trg = this.Cursor(1, 2, ::input_all);
	cursor_slot.enable_ok = false; cursor_slot.enable_cancel = false;
	cursor_dir.enable_ok = false; cursor_dir.enable_cancel = false;
	cursor_btn.enable_ok = false; cursor_btn.enable_cancel = false;
	cursor_wt.enable_ok = false; cursor_wt.enable_cancel = false;
	cursor_dly.enable_ok = false; cursor_dly.enable_cancel = false;
	cursor_trg.enable_ok = false; cursor_trg.enable_cancel = false;
	// Initialize cursors from current slot's config
	local sl = ::config.practice.oki_slot;
	cursor_slot.val = sl;
	cursor_dir.val = ::config.practice["oki_s" + sl + "_dir"] - 1;
	local sbtn = ::config.practice["oki_s" + sl + "_btn"];
	if (sbtn < 0 || sbtn >= 9) sbtn = 0;
	cursor_btn.val = sbtn;
	local swt = ::config.practice["oki_s" + sl + "_weight"];
	if (swt < 1 || swt > 10) swt = 5;
	cursor_wt.val = swt - 1;
	local sdly = ::config.practice["oki_s" + sl + "_delay"];
	if (sdly < 0 || sdly > 15) sdly = 0;
	cursor_dly.val = sdly;
	local strg = ::config.practice["oki_s" + sl + "_trigger"];
	if (strg < 0 || strg > 1) strg = 0;
	cursor_trg.val = strg;
	this.page[3].cursor["oki_slot"] <- cursor_slot;
	this.page[3].cursor["oki_dir"] <- cursor_dir;
	this.page[3].cursor["oki_btn"] <- cursor_btn;
	this.page[3].cursor["oki_wt"] <- cursor_wt;
	this.page[3].cursor["oki_dly"] <- cursor_dly;
	this.page[3].cursor["oki_trg"] <- cursor_trg;
	::print("[oki-menu] init: slot=" + sl + " dir=" + cursor_dir.val + " btn=" + cursor_btn.val + " wt=" + cursor_wt.val + " dly=" + cursor_dly.val + " trg=" + cursor_trg.val + "\n");

	// 3. Create label sprites + select_obj for the three new items
	local t = ::menu.common.item_y - 32 - 8;  // 160
	local spc = 32;
	local lx = ::menu.common.item_x - 240;   // 400
	local pg = this.anime.page[3];

	// --- Helper: multi-sprite select_obj (native-style rendering) ---
	local function MakeSelect(options, x, y, mat, curs) {
		local item = [];
		foreach (opt in options) {
			local s = ::font.CreateSystemString(opt);
			s.ConnectRenderSlot(::graphics.slot.overlay, 0);
			s.x = x; s.y = y; s.visible = false;
			::menu._oki_sprites.append(s);
			item.append(s);
		}
		item[curs.val].visible = true;
		local cur = curs.val;
		return {
			item   = item,
			cursor = curs,
			mat_world = mat,
			current  = cur,
			active   = false,
			Update   = function() {
				foreach (v in this.item) v.SetWorldTransform(this.mat_world);
				if (this.cursor.val != this.current) {
					this.item[this.current].visible = false;
					this.current = this.cursor.val;
					this.item[this.current].visible = true;
				}
			},
			Show = function() {
				if (this.current < this.item.len())
					this.item[this.current].visible = true;
			},
			Hide = function() {
				foreach (v in this.item) v.visible = false;
			}
		};
	}

	// Reversal Slot # (j=5, y=320)
	local ts = ::font.CreateSystemString("Reversal Slot #");
	ts.ConnectRenderSlot(::graphics.slot.overlay, 0);
	ts.x = lx; ts.y = t + 5 * spc;
	::menu._oki_sprites.append(ts);
	local islot = { text = ts, select_obj = null };
	islot.select_obj = MakeSelect(
		["1","2","3","4","5"],
		ts.x + 320, ts.y, pg.mat_world, cursor_slot
	);

	// Direction (j=6, y=352)
	local td = ::font.CreateSystemString("  Direction");
	td.ConnectRenderSlot(::graphics.slot.overlay, 0);
	td.x = lx; td.y = t + 6 * spc;
	::menu._oki_sprites.append(td);
	local idir = { text = td, select_obj = null };
	idir.select_obj = MakeSelect(
		["1","2","3","4","5","6","7","8","9"],
		td.x + 320, td.y, pg.mat_world, cursor_dir
	);

	// Action (j=7, y=384)
	local tb = ::font.CreateSystemString("  Action");
	tb.ConnectRenderSlot(::graphics.slot.overlay, 0);
	tb.x = lx; tb.y = t + 7 * spc;
	::menu._oki_sprites.append(tb);
	local iact = { text = tb, select_obj = null };
	iact.select_obj = MakeSelect(
		["A","B","C","D","P","AB","BC","CP","Off"],
		tb.x + 320, tb.y, pg.mat_world, cursor_btn
	);

	// Weight (j=8, y=416)
	local tw = ::font.CreateSystemString("  Weight");
	tw.ConnectRenderSlot(::graphics.slot.overlay, 0);
	tw.x = lx; tw.y = t + 8 * spc;
	::menu._oki_sprites.append(tw);
	local iwt = { text = tw, select_obj = null };
	iwt.select_obj = MakeSelect(
		["1","2","3","4","5","6","7","8","9","10"],
		tw.x + 320, tw.y, pg.mat_world, cursor_wt
	);

	// Delay (j=9, y=448)
	local tdl = ::font.CreateSystemString("  Delay");
	tdl.ConnectRenderSlot(::graphics.slot.overlay, 0);
	tdl.x = lx; tdl.y = t + 9 * spc;
	::menu._oki_sprites.append(tdl);
	local idly = { text = tdl, select_obj = null };
	idly.select_obj = MakeSelect(
		["0f","1f","2f","3f","4f","5f","6f","7f","8f","9f","10f","11f","12f","13f","14f","15f"],
		tdl.x + 320, tdl.y, pg.mat_world, cursor_dly
	);

	// Trigger (j=10, y=480)
	local ttr = ::font.CreateSystemString("  Trigger");
	ttr.ConnectRenderSlot(::graphics.slot.overlay, 0);
	ttr.x = lx; ttr.y = t + 10 * spc;
	::menu._oki_sprites.append(ttr);
	local itrg = { text = ttr, select_obj = null };
	itrg.select_obj = MakeSelect(
		["Hit","Block"],
		ttr.x + 320, ttr.y, pg.mat_world, cursor_trg
	);

	// 4. Insert real items into pg.item (anime system handles rendering + highlighting)
	pg.item.insert(5, islot);
	pg.item.insert(6, idir);
	pg.item.insert(7, iact);
	pg.item.insert(8, iwt);
	pg.item.insert(9, idly);
	pg.item.insert(10, itrg);

	// 5. Shift common items (now at pg.item indices 11+, were 5+) down 192px
	for (local j = 11; j < pg.item.len(); j++) {
		if (pg.item[j] && pg.item[j].text) {
			pg.item[j].text.y += 192;
			if (pg.item[j].select_obj) {
				foreach (s in pg.item[j].select_obj.item) s.y += 192;
			}
		}
	}

	// 6. Update page cursor — rebuild skip from modified item_list
	local ci = this.cursor_item_list[3];
	ci.item_num = il.len();
	local sk = []; foreach (v in il) sk.append(v ? 0 : 1);
	ci.SetSkip(sk);

	// 7. If currently on page 3, resync
	if (this.cursor_page.val == 3) {
		this.item = il;
		this.cursor_item = ci;
	}

	// --- Patch ex_guard_mode: extend 2→3 options (add Just Guard) ---
	// Game engine supports ex_guard_mode=2 (Just Guard) but the cursor only
	// has item_num=2, causing "the index '2' does not exist" crash.
	{
		// Clamp config before patching cursor
		if (typeof ::config.practice.ex_guard_mode != "integer"
			|| ::config.practice.ex_guard_mode < 0
			|| ::config.practice.ex_guard_mode > 2)
			::config.practice.ex_guard_mode = 0;

		local eg_cursor = this.page[2].cursor["ex_guard_mode"];
		eg_cursor.item_num = 3;
		eg_cursor.val = ::config.practice.ex_guard_mode;

		// Find ex_guard_mode in anime.page[2].item (index matches item_list[2])
		local eg_idx = -1;
		foreach (idx, name in this.item_list[2]) {
			if (name == "ex_guard_mode") { eg_idx = idx; break; }
		}
		if (eg_idx >= 0) {
			local pg2 = this.anime.page[2];
			local eg_item = pg2.item[eg_idx];
			if (eg_item && eg_item.select_obj) {
				// Disconnect old select_obj sprites from overlay
				try { foreach (v in eg_item.select_obj.item) { v.visible = false; v.DisconnectRenderSlot(); } } catch(e) {}
				// Replace with 3-option select
				eg_item.select_obj = MakeSelect(
					["Off", "Barrier Guard", "Just Guard"],
					eg_item.text.x + 320, eg_item.text.y,
					pg2.mat_world, eg_cursor
				);
			}
		}
	}

	// Patch UpdateMain: handle LR on Oki items, sync to config, prevent page switch
	local orig_update = this.UpdateMain;
	this.UpdateMain = function() {
		local cp_saved = this.cursor_page.val;
		local ci_saved = this.cursor_item.val;
		local prev_slot = ::config.practice.oki_slot;

		// --- Focus-toggle for Oki items (matching No/Yes pattern) ---
		// Unfocused: LR switches pages, UD moves between items.
		// Press Z → lock/focus the item → LR changes values, page blocked.
		// Press Z again or move away → unlock/unfocus.
		local on_oki = (cp_saved == 3 && ci_saved >= 5 && ci_saved <= 10);

		// Edge-detect Z via 0→non-zero transition on input_all.b0
		local b0_now = 0;
		try { b0_now = ::input_all.b0; } catch(e) {}
		if (!("_oki_b0_prev" in ::menu)) ::menu._oki_b0_prev <- 0;
		local z_edge = (b0_now != 0 && ::menu._oki_b0_prev == 0);
		::menu._oki_b0_prev = b0_now;

		if (!("_oki_focused" in ::menu)) ::menu._oki_focused <- false;

		// Auto-unfocus when cursor moves away from Oki items
		if (!on_oki) ::menu._oki_focused = false;

		// Z toggles focus on Oki items
		if (on_oki && z_edge) ::menu._oki_focused = !::menu._oki_focused;

		// When focused: process LR to change values
		if (on_oki && ::menu._oki_focused) {
			if ("oki_slot" in this.page[3].cursor) {
				local curs;
				if (ci_saved == 5) curs = this.page[3].cursor["oki_slot"];
				else if (ci_saved == 6) curs = this.page[3].cursor["oki_dir"];
				else if (ci_saved == 7) curs = this.page[3].cursor["oki_btn"];
				else if (ci_saved == 8) curs = this.page[3].cursor["oki_wt"];
				else if (ci_saved == 9) curs = this.page[3].cursor["oki_dly"];
				else curs = this.page[3].cursor["oki_trg"];
				curs.Update();

				// Slot changed: sync all cursors to new slot's values
				if (ci_saved == 5) {
					local new_sl = curs.val;
					if (new_sl != prev_slot) {
						::config.practice.oki_slot = new_sl;
						this.page[3].cursor["oki_dir"].val = ::config.practice["oki_s" + new_sl + "_dir"] - 1;
						this.page[3].cursor["oki_btn"].val = ::config.practice["oki_s" + new_sl + "_btn"];
						local nwt = ::config.practice["oki_s" + new_sl + "_weight"];
						this.page[3].cursor["oki_wt"].val = (nwt < 1 || nwt > 10) ? 4 : nwt - 1;
						this.page[3].cursor["oki_dly"].val = ::config.practice["oki_s" + new_sl + "_delay"];
						local ntrg = ::config.practice["oki_s" + new_sl + "_trigger"];
						this.page[3].cursor["oki_trg"].val = (ntrg < 0 || ntrg > 1) ? 0 : ntrg;
					}
				}
			}
		}

		// Save cursor values before orig_update (don't delete entries —
		// deleting causes crashes if orig_update triggers BeginAnime).
		// orig_update may corrupt our cursor values; restore after.
		local _oki_saved = null;
		if ("oki_slot" in this.page[3].cursor) {
			_oki_saved = {
				slot = this.page[3].cursor["oki_slot"].val,
				dir  = this.page[3].cursor["oki_dir"].val,
				btn  = this.page[3].cursor["oki_btn"].val,
				wt   = this.page[3].cursor["oki_wt"].val,
				dly  = this.page[3].cursor["oki_dly"].val,
				trg  = this.page[3].cursor["oki_trg"].val
			};
		}

		orig_update.call(this);

		// Restore cursor values that orig_update may have changed
		if (_oki_saved && "oki_slot" in this.page[3].cursor) {
			this.page[3].cursor["oki_slot"].val = _oki_saved.slot;
			this.page[3].cursor["oki_dir"].val  = _oki_saved.dir;
			this.page[3].cursor["oki_btn"].val  = _oki_saved.btn;
			this.page[3].cursor["oki_wt"].val   = _oki_saved.wt;
			this.page[3].cursor["oki_dly"].val  = _oki_saved.dly;
			this.page[3].cursor["oki_trg"].val  = _oki_saved.trg;
		}

		// Anime system handles all rendering: text highlighting, cursor indicator,
		// page visibility. No manual overlay management needed.

		// When focused on Oki item: block page switch caused by LR
		if (on_oki && ::menu._oki_focused) {
			if (this.cursor_page.val != cp_saved) {
				this.cursor_page.val = cp_saved;
				this.cursor_page.diff = 0;
				this.item = this.item_list[cp_saved];
				this.cursor_item = this.cursor_item_list[cp_saved];
				this.cursor_item.val = ci_saved;
			}
		}

		// Sync config: write Dir/Act/Wt/Dly to current slot
		try {
			if (this.cursor_page.val == 3 && "oki_slot" in this.page[3].cursor) {
				local sl = ::config.practice.oki_slot;
				::config.practice["oki_s" + sl + "_dir"] = this.page[3].cursor["oki_dir"].val + 1;
				::config.practice["oki_s" + sl + "_btn"] = this.page[3].cursor["oki_btn"].val;
				::config.practice["oki_s" + sl + "_weight"] = this.page[3].cursor["oki_wt"].val + 1;
				::config.practice["oki_s" + sl + "_delay"] = this.page[3].cursor["oki_dly"].val;
				::config.practice["oki_s" + sl + "_trigger"] = this.page[3].cursor["oki_trg"].val;
			}
		} catch (e) {}
	};
	this.Update = this.UpdateMain;
}

foreach (key,str in {
	["copy_host"]="copy IP/port to clipboard",
	["copy_watch"]="copy watch IP/port to clipboard"
}) {
	help.src[0][key] <- help.func_init_text(str);
	help.src[1][key] <- help.func_init_text(str);
}
function BeginAct()
{
	act.pl.BeginStage(0);
	::loop.DeleteTask(_act_task);
}

function EndAct()
{
	act.pl.EndStage();

	if ("Terminate" in act.global)
	{
		act.global.Terminate();
	}

	::loop.DeleteTask(_act_task);
}

function EndActDelayed( delay = 30 )
{
	_act_task.count = delay;
	::loop.AddTask(_act_task);
}

class EndActDelayedTask
{
	act = null;
	count = 0;
	function Update()
	{
		if (count-- == 0)
		{
			act.pl.EndStage();

			if ("Terminate" in act.global)
			{
				act.global.Terminate();
			}

			::loop.DeleteTask(this);
		}
	}

}

function BeginAnime()
{
	::loop.DeleteTask(_anime_task);
	anime.Initialize();
}

function EndAnime()
{
	::loop.DeleteTask(_anime_task);

	if ("Terminate" in anime)
	{
		anime.Terminate();
	}
}

function EndAnimeDelayed( delay = 30 )
{
	_anime_task.count = delay;
	::loop.AddTask(_anime_task);
}

class EndAnimeDelayedTask
{
	anime = null;
	count = 0;
	function Update()
	{
		if (count-- == 0)
		{
			anime.Terminate();
			::loop.DeleteTask(this);
		}
	}

}


foreach( v in scene )
{
	if ("act" in v)
	{
		v._act_task <- EndActDelayedTask();
		v._act_task.act = v.act.weakref();
		v.BeginAct <- BeginAct;
		v.EndAct <- EndAct;
		v.EndActDelayed <- EndActDelayed;
	}

	if ("anime" in v)
	{
		v._anime_task <- EndAnimeDelayedTask();
		v._anime_task.anime = v.anime.weakref();
		v.BeginAnime <- BeginAnime;
		v.EndAnime <- EndAnime;
		v.EndAnimeDelayed <- EndAnimeDelayed;
	}
}

// Patch practice scene cleanup: disconnect oki sprites when leaving training mode
if ("EndAnime" in practice) {
	local _orig_practice_end_anime = practice.EndAnime;
	practice.EndAnime = function() {
		if ("_oki_sprites" in ::menu) {
			foreach (s in ::menu._oki_sprites) {
				try { s.DisconnectRenderSlot(); } catch(e) {}
			}
		}
		_orig_practice_end_anime.call(this);
	};
}
if ("EndAct" in practice) {
	local _orig_practice_end_act = practice.EndAct;
	practice.EndAct = function() {
		if ("_oki_sprites" in ::menu) {
			foreach (s in ::menu._oki_sprites) {
				try { s.DisconnectRenderSlot(); } catch(e) {}
			}
		}
		_orig_practice_end_act.call(this);
	};
}
