::manbow.CompileFile("data/script/battle/battle_team.nut", this);
::manbow.CompileFile("data/script/battle/battle_on_move.nut", this);
::manbow.CompileFile("data/script/battle/battle_on_hit.nut", this);
::manbow.CompileFile("data/script/battle/battle_param.nut", this);
::manbow.CompileFile("data/script/battle/battle_update.nut", this);
function InitializeUser()
{
}

function UpdateUser()
{
}

function TerminateUser()
{
}

::manbow.CompileFile("setting.nut",::setting);
::manbow.CompileFile("debug.nut",::debug);
::manbow.CompileFile("data/actor/script/battle.nut", this);
::manbow.CompileFile("UI.nut", this);
::manbow.CompileFile("frame_data.nut", this);
::manbow.CompileFile("input_display.nut",this);
this.rollback <- {};
::manbow.CompileFile("rollback.nut",this.rollback);
this.gauge <- {};
::manbow.CompileFile("data/actor/status/gauge_common.nut", this.gauge);
::manbow.CompileFile("data/actor/status/spellcard.nut", this);
::manbow.CompileFile("data/actor/status/combo.nut", this);
::manbow.CompileFile("data/actor/status/bgm_title.nut", this);
this.game_mode <- -1;
this.ping_task <- null;
this.input_task <- null;
this.ping_obj <- null;
this.frame_task <- null;
this.UI_task <- null;
this.frame_lock <- false;
class this.InitializeParam
{
	game_mode = 1;
	seed = 0;
	team = [
		null,
		null
	];
	constructor()
	{
		this.team = [
			{},
			{}
		];

		foreach( i, v in this.team )
		{
			v.device_id <- -2;
			v.master <- null;
			v.slave <- null;
			v.slave_sub <- null;
			v.master_spell <- 0;
			v.slave_spell <- 0;
			v.slave_sub_spell <- 0;
			v.start_x <- ::battle.start_x[i];
			v.start_y <- ::battle.start_y[i];
			v.start_direction <- ::battle.start_direction[i];
		}
	}

}

this.name_overrides <- {
    hijiri = "Byakuren",
    sinmyoumaru = "Shinmyoumaru",
    usami = "Sumireko",
    udonge = "Reisen",
    jyoon = "Joon"
};

function LookupName(name) {
	return (name in this.name_overrides) ? this.name_overrides[name] : (name.slice(0, 1).toupper() + name.slice(1, name.len()));
}

function Create( param )
{
	::setting.network.update_consts();
	if (::network.IsActive() && ::setting.network.hide_opponent_name){
		::network.player_name[0] = "P1";
		::network.player_name[1] = "P2";
	}
	if (::replay.GetState() == ::replay.PLAY && ::network.inst == null)
		::discord.rpc_set_details("Watching a replay");
	::discord.rpc_set_state(param.game_mode < 10 ? "Starting match" : "");
	::discord.rpc_set_large_img_key("stage" + ::stage.background.id);
	if (::replay.GetState() != ::replay.PLAY && (::network.IsPlaying() || (param.game_mode != 1 && param.game_mode != 10))) {
		local p1m = param.team[0].master.name;
		local p1s = param.team[0].slave.name;
		local p2m = param.team[1].master.name;
		local p2s = param.team[1].slave.name;

		::discord.rpc_set_small_img_key(::network.IsPlaying() ? (::network.is_parent_vs ? p2m : p1m) : p1m);
		::discord.rpc_set_small_img_text(format("%s/%s vs %s/%s", LookupName(p1m), LookupName(p1s), LookupName(p2m), LookupName(p2s)));
	}
	::discord.rpc_commit();

	::manbow.SetTerminateFunction(function ()
	{
		::battle.Release();
	});
	this.Update = this.UpdateMain;
	::manbow.CompileFile("data/script/battle/battle_param.nut", this);
	::manbow.CompileFile("data/script/battle/battle_team.nut", this);

	switch(param.game_mode)
	{
	case 10:
		::manbow.CompileFile("data/actor/status/gauge_story.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_story.nut", this);
		inputdisplaysetup(0);
		inputdisplaysetup(1);
		break;

	case 40:
		::manbow.CompileFile("data/actor/status/gauge_vs.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_practice.nut", this);
		local practicerestart = this.PracticeRestart;
		this.PracticeRestart = function () {
			this.UI_task.active = true;
			this.frame_task.full = !this.UI_task.active;
			practicerestart();
		};
		HideUISetup(60);
		framedisplaysetup();
		inputdisplaysetup(0);
		inputdisplaysetup(1);
		break;

	case 30:
		::manbow.CompileFile("data/actor/status/gauge_vs.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_tutorial.nut", this);
		break;

	default:
		::manbow.CompileFile("data/actor/status/gauge_vs.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_vs_player.nut", this);
		inputdisplaysetup(::network.IsPlaying() ? (::network.is_parent_vs ? 1 : 0) : 0);
		if(!::network.IsPlaying())inputdisplaysetup(1);
		break;
	}

	if (::replay.GetState() == ::replay.PLAY)
	{
		if (::network.IsActive())
		{
			::manbow.CompileFile("data/script/battle/battle_watch.nut", this);
			HideUISetup(15);
			inputdisplaysetup(1);
			inputdisplaysetup(0);
		}
		else if (param.game_mode == 10)
		{
			::manbow.CompileFile("data/script/battle/battle_replay_story.nut", this);
		}
		else
		{
			::manbow.CompileFile("data/script/battle/battle_replay.nut", this);
			HideUISetup(15);
			inputdisplaysetup(0);
			inputdisplaysetup(1);
		}
	}

	if (::network.IsPlaying())
	{
		::manbow.CompileFile("data/script/battle/battle_network.nut", this);
	}

	this.srand(param.seed);
	::graphics.ShowActor(true);
	::graphics.ShowBackground(true);
	::camera.Initialize();

	if ("SetCamera" in ::stage.background)
	{
		::stage.background.SetCamera();
	}

	this.world = ::manbow.World2D();
	this.world.Init(-1000, -1000, -100, 3560, 2440, 100);

	this.group_player = ::manbow.Actor2DGroup();
	this.group_player.SetWorld(this.world);
	this.group_player.SetCamera(::camera.camera2d);
	this.group_player.SetOnMoveCallbackFunction(this, this.OnMove);
	this.group_effect = ::manbow.Actor2DGroup();
	::actor.SetGroup(this.group_player, this.group_effect);
	this.CreateTeam(0, param.team[0]);
	this.CreateTeam(1, param.team[1]);
	this.InitializeUser();
	::camera.Reset();
 	this.gauge.Initialize();

	if (::network.IsActive() && !::setting.network.hide_profile_pictures){
		for( local i = 0; i < 2; i = ++i ){
			local icon = ::manbow.Sprite();
			local custom_icon = ::manbow.Texture();
			if (::network.icon[i] != null && custom_icon.CreateFromBase64(::network.icon[i], 32, 32)) {
				icon.Initialize(custom_icon, 0, 0, 32, 32);
				icon.x = i == 0 ? 116 : 1280 - 116 - 32;
				icon.y = 4;
				icon.ConnectRenderSlot(::graphics.slot.status, 3000);
				this.gauge.AddParts(icon, i == 0 ? this.gauge.mat_left_top : this.gauge.mat_right_top);
			}
		}
	}

	if (::network.IsPlaying()) {
		::setting.ping.update_consts();
		if (::setting.ping.enabled) {
			this.ping_obj = ::UI.CreateText(
				0,"",
				::setting.ping.SX,
				::setting.ping.SY,
				::setting.ping.red,
				::setting.ping.green,
				::setting.ping.blue,
				::setting.ping.alpha,
				::graphics.slot.status,1,
				function () {
					local delay = ::network.GetDelay();
					::rollback.update_delay(delay);
					local str = "ping:" + delay;
					if (::setting.ping.input_delay) str += " [" + ::rollback.get_buffered_frames() + "f]";
					if (::rollback.resyncing()) str += " (resyncing)";
					this.text.Set(str);
					this.text.x = ::setting.ping.X - ((this.text.width * this.text.sx) / 2);
					this.text.y = (::setting.ping.Y - this.text.height);
				}
			);
			this.ping_task = this.ping_obj;
			::loop.AddTask(this.ping_obj);
		}
	}
	if (!::network.IsActive())
	{
		if (param.game_mode == 10)
		{
			::replay.SetDevice([
				this.team[0].input,
				this.team[1].input,
				::input_talk
			], ::story.stage * 3);
		}
		else
		{
			::replay.SetDevice([
				this.team[0].input,
				this.team[1].input
			], 0);
			  // [329]  OP_JMP            0      0    0    0
		}
	}

	// ::rollback.Reset(this.group_player);
}

function framedisplaysetup() {
	/*
	subState
	team.combo_count is for how much you're being comboed
	current issues:
	projectiles and delayed child actors fucking up frame data
	installs
	IsAttack() continously attacking still increases the count
	value types:
	0 nothing
	1 melee,grab A
	2 bullet,occult B A+B
	3 special C
	4 SC A+C
	5 LW C+E
	6 tag E
	check p1.motion to have frame data of one attack only
	2500 SCs
	1800-1802 grab
	melee 2048,128,2
	projectile 4096,128,4
	*/
	::setting.frame_data.update_consts();
	local frame = FrameDataDisplay(0);
	AddTask(frame);
	this.frame_task = frame;
}

function inputdisplaysetup(player) {
	::setting.input_display.update_consts();
	local p = player != 1 ? ::setting.input_display.p1 : ::setting.input_display.p2;
	local input = this.CreateInput_display(player,p);
	this.input_task = input;
	AddTask(input);
}



// function patch_prefix(obj, name, prefix_func) {
//     local delegate = obj.getdelegate();
//     if (!delegate || typeof delegate != "table") throw "No valid delegate";

//     local orig = delegate[name];
//     if (typeof orig != "function") throw "Target is not a function";

//     delegate[name] = function(...) {
//         prefix_func(vargv);
//         return orig.acall(obj, vargv);
//     };
//     setdelegate(obj, delegate);
// }

function HideUISetup(hold) {
	// local test = ::font.CreateSystemString(" \f");
	// ::print(format("width:%d\n",test.width - 12));
	//'b' 19
	//'B' 20
	//'d' 19
	//'D' 23
	//'s' 16
	//'S' 19
	//'c' 17
	//'C' 21
	//' ' 7
	//'~' 14
	//'|-' 21
	//'-' 13
	//'|' 8
	//'[]' 28
	//" []" 40
	//" [" 26
	//" " 12
	// "   " 26
	local a = {};
	a.lastinput <- 0;
	a.active <- true;
	a.Update <- function () {
		local t0 = ::battle.team[0];
		local t1 = ::battle.team[1];
		local player = ::battle.team[0].current;
		local i = ::input_all.b6;
		local z = ::input_all.b7;
		local w = ::input_all.b8;
		// ::print(::manbow.GetKeyboardState()+"\n");//2 = 1
		if (i == 1){
			local now = ::date().sec;
			if (!(now - this.lastinput)){
				if (!(this.active = !this.active))::battle.gauge.Hide();
				else ::battle.gauge.Show(0);
				::battle.frame_task.full = !this.active;
				this.lastinput = 0;
				::sound.PlaySE("sys_ok");

			}else this.lastinput = now;
		}
		if (z && (!(z % 10) || z == 1)){
			::battle.frame_lock = false;
			// ::debug.test(player);
		}
		if (w == 1) {
			::setting.frame_data.frame_stepping = !::setting.frame_data.frame_stepping;
			::setting.save("frame_data_display","frame_stepping",::setting.frame_data.frame_stepping.tostring());
		}
	};
	this.UI_task = a;
	// AddTask(this.UI_task);
}

function Release()
{
	::discord.rpc_set_small_img_key("");
	::discord.rpc_set_small_img_text("");
	::discord.rpc_set_large_img_key("mainicon");
	if (::replay.GetState() == ::replay.PLAY && ::network.inst == null)
		::discord.rpc_commit_details_and_state("Idle", "");

	if (this.ping_task != null) {
		::loop.DeleteTask(this.ping_task);
		this.ping_task = null;
		this.ping_obj = null;
	}
	if (this.input_task != null) {
		DeleteTask(this.input_task);
		this.input_task = null;
	}
	if (this.frame_task != null) {
		::loop.DeleteTask(this.frame_task);
		this.frame_task.Release();
		this.frame_task = null;
	}
	if (this.UI_task != null) {
		// DeleteTask(this.UI_task);
		this.UI_task = null;
	}
	this.task = {};
	this.gauge.Terminate();
	this.TerminateUser();
	::actor.SetGroup(null, null);
	::camera.Clear();
	this.battleUpdate = null;
	this.group_player = null;
	this.group_effect = null;

	if ("bgm" in this)
	{
		this.bgm = null;
	}

	foreach( v in this.team )
	{
		v.Release();
	}

	this.team = [
		null,
		null
	];
	::talk.Clear();
	::effect.Clear();
	::manbow.SetTerminateFunction(null);

	::overlay.clear();
	// ::rollback.Clear();
}

function Begin()
{
}

function End()
{
	if (this.ping_task != null) {
		::loop.DeleteTask(this.ping_task);
		this.ping_task = null;
		this.ping_obj = null;
	}
	::sound.StopBGM(500);
	::loop.EndWithFade();
}

function AddTask( actor )
{
	this.task[actor.tostring()] <- actor;
}

function DeleteTask( actor )
{
	if (actor.tostring() in this.task)
	{
		delete this.task[actor.tostring()];
	}
}

function SetTimeStop( n )
{
	this.time_stop_count = n;
}

function SetSlow( n )
{
	this.slow_count = n;
}

this.UpdateMainOrig <- this.UpdateMain;
this.UpdateMain = function() {
	if(this.UI_task)this.UI_task.Update();
	if (!::network.IsActive() &&
		::setting.frame_data.frame_stepping &&
		this.frame_lock){
		return;
	}
	this.UpdateMainOrig();

	if (::menu.pause_hack)
		::menu.pause_hack = false;
	else if (::loop.pause_count == 0 && !this.is_time_stop && !::network.IsPlaying())
		::overlay.set_hitboxes(this.group_player, this.team[0].current.hit_state, this.team[1].current.hit_state);
}
