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

function Create( param )
{
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
		inputdisplaysetup(0);
		if(!::network.IsPlaying())inputdisplaysetup(1);
		break;
	}

	if (::replay.GetState() == ::replay.PLAY)
	{
		if (::network.IsActive())
		{
			::manbow.CompileFile("data/script/battle/battle_watch.nut", this);
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

	//additions
	if (::network.IsActive()) {
		::setting.ping.update_consts();
		if (::setting.ping.enabled) {
			local ping = {};
			ping.text <- ::font.CreateSystemString("");
			ping.text.sx = ::setting.ping.SX;
			ping.text.sy = ::setting.ping.SY;
			ping.text.red = ::setting.ping.red;
			ping.text.green = ::setting.ping.green;
			ping.text.blue = ::setting.ping.blue;
			ping.text.alpha = ::setting.ping.alpha;
			ping.text.ConnectRenderSlot(::graphics.slot.ui, 60000);
			ping.Update <- function() {
				local delay = ::network.GetDelay();
				local str = "ping:" + delay;
				if (::setting.ping.ping_in_frames) str += "[" + ((delay + 15) / 16) + "f]";
				if (::rollback.resyncing()) str += "(resyncing)";
				this.text.Set(str);
				this.text.x = ::setting.ping.X - (this.text.width / 2);
				this.text.y = (::setting.ping.Y - this.text.height);
			};
			this.ping_task = ping;
			::loop.AddTask(ping);
		}
	}
	//end of additions
	//displayAllElements(this.team[0].master,"master.txt","");
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
}

// function displayAllElements(obj,file,indent) {
// 	indent += " ";
//     ::debug.fprint(file,indent+"----"+obj+"----\n");

//     // foreach (key, value in obj) {
//     //     ::debug.fprint(file,indent+key + " : " + typeof(value) + "\n");

//     //     if (typeof(value) == "table") {
//     //         displayAllElements(key,file,indent);
//     //     }
//     // }
// 	::debug.fprint(file,indent+"---------------\n");
// }

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

//additions
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
//end of additions
function Release()
{
	if (this.ping_task != null) {
		::loop.DeleteTask(this.ping_task);
		this.ping_task = null;
	}
	if (this.input_task != null) {
		DeleteTask(this.input_task);
		this.input_task = null;
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
}

function Begin()
{
}

function End()
{
	::sound.StopBGM(500);

	//if (::network.IsPlaying() && ::network.use_lobby)
	//{
		//::network.Disconnect();
	//}
	//else
	//{
		::loop.EndWithFade();
	//}
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

