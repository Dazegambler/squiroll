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
		inputdisplaysetup(0);
		inputdisplaysetup(1);
		break;

	case 40:
		::manbow.CompileFile("data/actor/status/gauge_vs.nut", this.gauge);
		::manbow.CompileFile("data/script/battle/battle_practice.nut", this);
		inputdisplaysetup(0);
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
		inputdisplaysetup(0);
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

function inputdisplaysetup(player){
	::setting.input_display.update_consts();
	if ((player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).enabled){
		local input = {};
		input.list <- [];
		input.buf <- [];
		input.lastinput <- "";
		input.sincelast <- 0; //frames
		input.autodeletetimer <- (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).timer; //frames
		input.reset <- false;
		input.cursor <- -1;
		input.getinputs <- getinputs;
		input.padding <- (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).spacing ? " " : "";
		input.listmax <- (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).list_max;

		for (local i = 0; i < input.listmax; i++){
			local t = ::manbow.String();
			input.list.append(t);
			input.list[i].Initialize(::talk.font);
			input.list[i].red = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).red;
			input.list[i].green = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).green;
			input.list[i].blue = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).blue;
			input.list[i].alpha = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).alpha;
			input.list[i].sy = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).SY;
			input.list[i].sx = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).SX;
			input.list[i].x = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).X;
			input.list[i].y = (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).Y - (i * (player == 1 ? ::setting.input_display.p2 : ::setting.input_display.p1).offset);
			input.list[i].ConnectRenderSlot(::graphics.slot.ui, 60000);
		}
		for (local i = 0; i < input.listmax; i++){
			input.buf.append("");
		}
		input.Update <- function () {
			local str = this.getinputs(player,this.padding);
			if (str != this.lastinput && str != ""){
				this.reset = true;
				for (local i = (this.listmax-1); i > -1; i--){
					if (i+1 == (this.listmax)){
						this.buf[i] = "";
						this.list[i].Set("");
					}else{
						this.buf[i+1] = this.buf[i];
						this.list[i+1].Set(this.buf[i]);
					}
				}
				this.buf[0] = str;
				this.list[0].Set(str);
				this.lastinput = str;
				this.sincelast = 0;
			}else if (this.sincelast > this.autodeletetimer){
				if (this.reset == true){
					for ( this.cursor = (this.listmax-1); this.cursor > -1; this.cursor--){
						this.buf[this.cursor] = "";
						this.list[this.cursor].Set("");
					}
					this.cursor = 0;
					this.lastinput = "";
					this.reset = false;
				}
			}else{
				this.sincelast++;
			}
		};
		AddTask(input);
	}
}

//additions
function getinputs(player,none)
{
	local str = "";
	local player = ::battle.team[player]
	switch (true){
		case (player.input.x < 0 && player.input.y < 0)://4
			str += player.current.direction > 0 ? "7" :"9";
			break;
		case (player.input.x < 0 && player.input.y > 0)://4
			str += player.current.direction > 0 ? "1" : "3";
			break;
		case (player.input.x > 0 && player.input.y < 0)://6
			str += player.current.direction > 0 ? "9" : "7";
			break;
		case (player.input.x > 0 && player.input.y > 0)://6
			str += player.current.direction > 0 ? "3" : "1";
			break;
		case (player.input.x < 0)://raw 4
			str += player.current.direction > 0 ? "4" : "6";
			break;
		case (player.input.x > 0)://raw 6
			str += player.current.direction > 0 ? "6" : "4";
			break;
		case (player.input.y < 0):
			str += "8";
			break;
		case (player.input.y > 0):
			str += "2";
			break;
		default:
			str += none;
			break;
	}
	str += none;
	str += player.input.b0 ? "A" : none;
	str += player.input.b1 ? player.input.b1 > 12 ? "[B]" : "B" : none;
	str += player.input.b2 ? "C" : none;
	str += player.input.b4 ? "D" : none;
	str += player.input.b3 ? "E" : none;
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

