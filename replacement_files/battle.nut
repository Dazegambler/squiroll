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
		break;

	case 40:
		::manbow.CompileFile("data/actor/status/gauge_vs.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_practice.nut", this);
		break;

	case 30:
		::manbow.CompileFile("data/actor/status/gauge_vs.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_tutorial.nut", this);
		break;

	default:
		::manbow.CompileFile("data/actor/status/gauge_vs.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_vs_player.nut", this);
		break;
	}

	if (::replay.GetState() == ::replay.PLAY)
	{
		if (::network.IsActive())
		{
			::manbow.CompileFile("data/script/battle/battle_watch.nut", this);
		}
		else if (param.game_mode == 10)
		{
			::manbow.CompileFile("data/script/battle/battle_replay_story.nut", this);
		}
		else
		{
			::manbow.CompileFile("data/script/battle/battle_replay.nut", this);
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
	if (::network.inst) {
		::setting.ping.update_consts();
		local ping = {};
		ping.text <- ::font.CreateSystemString("");
		ping.text.sx = ::setting.ping.SX;
		ping.text.sy = ::setting.ping.SY;
		ping.text.ConnectRenderSlot(::graphics.slot.ui, 60000);
		ping.Update <-  function() {
			if (::network.inst) {
				if (::rollback.resyncing() != false) {
					this.text.Set("ping:" + ::network.GetDelay() + "(resyncing)");
				} else {
					this.text.Set("ping:" + ::network.GetDelay());
				}
				this.text.x = ::setting.ping.X - (this.text.width / 2);
				this.text.y = (::setting.ping.Y - this.text.height);
			}else{
				::loop.DeleteTask(this);
				this = null;
			}
		};
		::loop.AddTask(ping);
	}

	if (::setting.input_display.enabled){
		local input = {};
		input.list <- [];
		input.entries <- [];
		input.lastinput <- "";
		input.getinputs <- getinputs;
		input.listmax <- ::setting.input_display.list_max;

		for (local i = 0; i < input.listmax; i++){
			local t = ::manbow.String();
			input.list.append(t);
			input.list[i].Initialize(::talk.font);
			input.list[i].red = ::setting.input_display.red;
			input.list[i].green = ::setting.input_display.green;
			input.list[i].blue = ::setting.input_display.blue;
			input.list[i].alpha = ::setting.input_display.alpha;
			input.list[i].sy = ::setting.input_display.SY;
			input.list[i].sx = ::setting.input_display.SX;
			input.list[i].x = ::setting.input_display.X;
			input.list[i].y = ::setting.input_display.Y-(i*::setting.input_display.offset);
			input.list[i].ConnectRenderSlot(::graphics.slot.ui,60000);
		}
		input.Update <- function () {
			local str = this.getinputs();
			if (str != this.lastinput && str != ""){
				this.entries.insert(0, str);
				if (this.entries.len() > this.listmax){
					this.entries.pop();
				}
				this.lastinput = str;
			}
			for (local i = 0; i < this.listmax; i++){
				this.list[i].Set(this.entries.len() > i ? this.entries[i] : "");
			}
		};
		AddTask(input);
	}
	//end of additions

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

//additions
function getinputs()
{
	local str = "";
	str += ::input_all.x < 0 ? "4" : "";
	str += ::input_all.x > 0 ? "6" : "";
	str += ::input_all.y < 0 ? "8" : "";
	str += ::input_all.y > 0 ? "2" : "";
	//str += "";
	str += ::input_all.b0 ? "A" : "";
	str += ::input_all.b1 ? "B" : "";
	str += ::input_all.b2 ? "C" : "";
	str += ::input_all.b4 ? "D" : "";
	str += ::input_all.b3 ? "E" : "";

	return str;
}
//end of additions
function Release()
{
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

	if (::network.IsPlaying() && ::network.use_lobby)
	{
		::network.Disconnect();
	}
	else
	{
		::loop.EndWithFade();
	}
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

