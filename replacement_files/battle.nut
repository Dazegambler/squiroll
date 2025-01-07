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

::manbow.CompileFile("data/actor/script/battle.nut", this);
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
this.UI_task <- false;
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
	if (::replay.GetState() == ::replay.PLAY && ::network.inst == null)
		::discord.rpc_set_details("Watching a replay");
	::discord.rpc_set_state(param.game_mode < 10 ? "Starting match" : "");
	::discord.rpc_set_large_img_key("stage" + ::stage.background.id);
	if (::replay.GetState() != ::replay.PLAY && (::network.IsPlaying() || param.game_mode != 1)) {
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
		HideUISetup(60);
		//framedisplaysetup();
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

	if (::network.IsPlaying()) {
		::setting.ping.update_consts();
		if (::setting.ping.enabled) {
			this.ping_obj = {};
			this.ping_obj.text <- ::font.CreateSystemString("");
			this.ping_obj.text.sx = ::setting.ping.SX;
			this.ping_obj.text.sy = ::setting.ping.SY;
			this.ping_obj.text.red = ::setting.ping.red;
			this.ping_obj.text.green = ::setting.ping.green;
			this.ping_obj.text.blue = ::setting.ping.blue;
			this.ping_obj.text.alpha = ::setting.ping.alpha;
			this.ping_obj.text.ConnectRenderSlot(::graphics.slot.front, 1);
			this.ping_obj.Update <- function() {
				local delay = ::network.GetDelay();
				::rollback.update_delay(delay);
				local str = "ping:" + delay;
				if (::setting.ping.ping_in_frames) str += " [" + ::rollback.get_buffered_frames() + "f]";
				if (::rollback.resyncing()) str += " (resyncing)";
				this.text.Set(str);
				this.text.x = ::setting.ping.X - (this.text.width / 2);
				this.text.y = (::setting.ping.Y - this.text.height);
			};
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
	// ::debug.fprint_value(::battle.team[0].current.collisionGroup,"cgroup.txt");
}

function framedisplaysetup() {
	/*
	IsAttack() continously attacking still increases the count
	value types:
	0 nothing
	1 melee,grab A
	2 bullet,occult B A+B
	3 special C
	4 SC A
	5 LW C+E
	6 tag E
	IsFree() doesn't really work, seems to always increase
	GetKeyFrameData() seems to have useful things
	damagePoint active frames
	check p1.motion to have frame data of one attack only
	CHECK FLAGSTATE
	bit 1 is input lock, no matter what you press nothing will happen while bit 1 is active
	bit 16777216 is center lane fall exception
	MELEE:
	F5A
	startup 256
	active (512,256,32)(1024,512,256,32)
	recovery 1024,32
	J5A
	startup 256
	active (512,256,32)(1024,512,256,32)
	recovery (1024,512,32)(1024,32)
	C5A,4A
	startup 0
	active,recovery 1024,512,32
	6A
	startup 256
	active (1024,512,256,32)(1024,256,32)
	recovery 1024,512,32
	8A
	startup 256
	active (16777216,256,32)(16777216,1024,256,32)
	recovery (16777216,1024,512,32)(16777216,1024,32)
	H.J8A
	startup 256
	active (16777216,256,32)(16777216,1024,256,32)
	recovery (1024,512,32)(1024,32)
	L.J8A
	startup 16777216,256
	active (16777216,256,32)(16777216,1024,256,32)
	recovery (16777216,1024,512,32)(16777216,1024,32)(1024,32)
	4A
	startup 16777216,256
	active  (16777216,256,32)(16777216,512,256,32)(16777216,512,32)
	recovery 1024,32
	H.J4A
	startup 16777216,256
	active  16777216,256,32
	recovery (1024,512,32)(1024,32)
	L.J4A
	startup 16777216,256
	active  (16777216,256,32)(16777216,512,256,32)(16777216,1024,512,32)
	recovery (1024,512,32)(1024,32)
	32 is for recovery
	512 is for active
	288 maybe for some moves?
	256
	check flagattack
	*/
	local frame = {};
	frame.motion <- 0;
	frame.test <- false;
	frame.data <- [
		0,//startup
		0,//active
		0//recovery
	];
	frame.timer <- 0;
	frame.text <- ::font.CreateSystemString("");
	frame.text.sx = ::setting.ping.SX;
	frame.text.sy = ::setting.ping.SY;
	frame.text.red = ::setting.ping.red;
	frame.text.green = ::setting.ping.green;
	frame.text.blue = ::setting.ping.blue;
	frame.text.alpha = ::setting.ping.alpha;
	frame.text.ConnectRenderSlot(::graphics.slot.front, 1);
	frame.str <- "";
	frame.Update <- function () {
		local p1 = ::battle.team[0].current;
		local frameData = p1.GetKeyFrameData();
		local attackData = p1.temp_atk_data;
		// ::debug.print_value(p1.cancelLV);
		// return;
		local fre = p1.IsFree();
		// local att = p1.IsAttack();
		// local rcvr = frameData.recover;
		local flag = p1.flagState;
		local dmg = frameData.damagePoint;
		local mot = p1.motion;
		if ( fre == false ) {
			this.timer = 120;
			if (this.motion != mot) {
				this.data = [0,0,0];
				this.motion = mot
			}
			data[dmg!= 0 && ((flag & 0x320) || (flag & 0x120)) ? 1 : ((flag & 0x420)) ? 2 : 0]++;//was 0x320 0x220
		}
		else {this.data = [0,0,0];this.timer--;}
		//local str = format("startup:%d||active:%d||recovery:%d||frame:%d\n",data[0],data[1],data[2],p1.frame);
		local bin = "[";
		for (local i = 32 -1; i >= 0; i--){
			local v = 1 << i;
			if (p1.flagState & v)bin += format("%d,",v);
		}
		bin += "]";
		local bin1 = "[";
		for (local i = 32 -1; i >= 0; i--){
			local v = 1 << i;
			if (p1.flagAttack & v)bin1 += format("%d,",v);
		}
		bin1 += "]";
		local str = format("startup:%2d||active:%2d||recovery:%2d||dmg:%5s||flag:%s%s\n",
							data[0]+1,data[1],data[2],(dmg!=0).tostring(),bin,bin1);
		if (this.str != str && fre == false){
			::debug.print((this.str = str));
		}
		this.text.Set(this.timer > 0 ? this.str : "");
		this.text.x = ::setting.ping.X - (this.text.width / 2);
		this.text.y = (::setting.ping.Y - this.text.height);
	}
	AddTask(frame);
	this.frame_task = frame;
}

function inputdisplaysetup(player) {
	::setting.input_display.update_consts();
	local p = player != 1 ? ::setting.input_display.p1 : ::setting.input_display.p2;
	if (p.enabled) {
		local input = {};
		input.list <- [];
		input.buf <- [];
		input.lastinput <- "";
		input.sincelast <- 0; //frames
		input.autodeletetimer <- p.timer; //frames
		input.getinputs <- getinputs;
		input.padding <- p.spacing ? " " : "";
		input.listmax <- p.list_max;

		for (local i = 0; i < input.listmax; ++i) {
			local t = ::manbow.String();
			t.Initialize(::talk.font);
			t.red = p.red;
			t.green = p.green;
			t.blue = p.blue;
			t.alpha = p.alpha;
			t.sy = p.SY;
			t.sx = p.SX;
			t.x = p.X;
			t.y = p.Y - (i * p.offset);
			t.ConnectRenderSlot(::graphics.slot.ui, 60000);
			input.list.append(t);
			input.buf.append("");
		}
		input.Update <- function () {
			local str = this.getinputs(player,this.padding);
			if (str != this.lastinput && str != "") {
				for (local i = this.listmax-1; i > 0; --i) {
					this.buf[i] = this.buf[i-1];
					this.list[i].Set(this.buf[i-1]);
				}
				this.buf[0] = str;
				this.list[0].Set(str);
				this.lastinput = str;
				this.sincelast = this.autodeletetimer;
			} else if (this.sincelast && !--this.sincelast) {
				for (local i = 0; i < this.listmax; ++i) {
					this.buf[i] = "";
					this.list[i].Set("");
				}
				this.lastinput = "";
			}
		};
		this.input_task = input;
		AddTask(input);
	}
}

function getinputs(player,none)
{
	local str = "";
	local setting = player != 1 ? ::setting.input_display.p1 : ::setting.input_display.p2;
	local team = ::battle.team[(::network.IsPlaying() ? ::network.is_parent_vs : player == 1) ? 1 : 0];
	local input = team.input;
	local x_axis = setting.raw_input || team.current.direction > 0 ? input.x : -input.x;
	if (input.y < 0) {
		str = x_axis < 0 ? "7" : !x_axis ? "8" : "9";
	}
	else if (!input.y) {
		str = x_axis < 0 ? "4" : !x_axis ? none : "6";
	}
	else {
		str = x_axis < 0 ? "1" : !x_axis ? "2" : "3";
	}
	str += none;
	str += input.b0 ? "A" : none;
	str += input.b1 ? input.b1 > 12 ? "[B]" : none + "B" + none : none + none + none;
	str += input.b2 ? "C" : none;
	str += input.b4 ? "D" : none;
	str += input.b3 ? "E" : none;
	return str;
}

function HideUISetup(hold) {
	local ui = {};
	ui.active <- true;
	ui.Update <- function () {
		local b2 = ::input_all.b2;
		local b4 = ::input_all.b4;
		if ((b2 != 0 && b4 != 0) &&
			b2 % hold == 0 && b4 % hold == 0){
			if (!(active = !active))::battle.gauge.Hide();
			else{::battle.gauge.Show(0);}
		}
	}
	this.UI_task = ui;
	AddTask(this.UI_task);
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
		DeleteTask(this.frame_task);
		this.frame_task = null;
	}
	if (this.UI_task != null) {
		DeleteTask(this.UI_task);
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
	this.UpdateMainOrig();

	if (::menu.pause_hack)
		::menu.pause_hack = false;
	else if (::loop.pause_count == 0 && !this.is_time_stop && !::network.IsPlaying())
		::overlay.set_hitboxes(this.group_player, this.team[0].current.hit_state, this.team[1].current.hit_state);
	}
