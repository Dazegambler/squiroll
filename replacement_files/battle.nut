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
		if (::setting.frame_data.enabled)framedisplaysetup();
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
	this.gauge.Initialize = function () {
		local actor;
		local mat = ::manbow.Matrix();
		local lang = ::config.lang;
		this.parts = [];
		local face_slave = [];
		this.face = {};
		actor = this.CreateStaticParts(8010, this.mat_left_top, this.mat_identity, ::actor.actor_list.master0.mgr.GetAnimationSet2D());
		this.face.master0 <- actor;
		actor = this.CreateStaticParts(8010, this.mat_left_top, this.mat_identity, ::actor.actor_list.slave0.mgr.GetAnimationSet2D());
		actor.SetMotion(8010, 1);
		face_slave.append(actor);
		this.face.slave0 <- actor;
		mat.SetScaling(-1, 1, 1);
		mat.Translate(1280, 0, 0);
		actor = this.CreateStaticParts(8011, this.mat_right_top, mat, ::actor.actor_list.master1.mgr.GetAnimationSet2D());
		this.face.master1 <- actor;
		actor = this.CreateStaticParts(8011, this.mat_right_top, mat, ::actor.actor_list.slave1.mgr.GetAnimationSet2D());
		actor.SetMotion(8011, 1);
		face_slave.append(actor);
		this.face.slave1 <- actor;

		if (::network.inst)
		{
			for( local i = 0; i < 2; i = ++i )
			{
				local icon = ::manbow.Sprite();
				local custom_icon = ::manbow.Texture();
				if (!::setting.misc.hide_profile_pictures() && ::network.icon[i] != null && custom_icon.CreateFromBase64(::network.icon[i], 32, 32)) {
					icon.Initialize(custom_icon, 0, 0, 32, 32);
				} else {
					icon.Initialize(::menu.cursor.texture, 160, i * 32, 32, 32);
				}
				icon.ConnectRenderSlot(::graphics.slot.ui, 40000);
				icon.x = i == 0 ? 116 : 1280 - 116 - 32;
				icon.y = 4;
				icon.ConnectRenderSlot(::graphics.slot.status, 3000);
				this.AddParts(icon, i == 0 ? this.mat_left_top : this.mat_right_top);
				local name = ::font.CreateSystemString(::network.player_name[i]);
				name.sx = name.sy = 2.00000000 / 3.00000000;
				name.x = i == 0 ? icon.x + 32 : icon.x - name.width * name.sx;
				name.y = icon.y + 2;
				name.ConnectRenderSlot(::graphics.slot.status, 4000);
				this.AddParts(name, i == 0 ? this.mat_left_top : this.mat_right_top);
			}
		}

		actor = this.CreateStaticParts(0, this.mat_left_top);
		this.spell_name_x <- [
			actor.GetFramePointX(0),
			actor.GetFramePointX(1)
		];
		this.spell_name_y <- [
			actor.GetFramePointY(0),
			actor.GetFramePointY(1)
		];
		this.spell_name_start_y <- actor.GetFramePointY(2);
		this.CreateStaticParts(20, this.mat_left_top);
		this.CreateStaticParts(1, this.mat_right_top);
		this.CreateStaticParts(21, this.mat_right_top);
		this.CreateStaticParts(2, this.mat_center);
		actor = this.CreateStaticParts(3, this.mat_center);

		if (::battle.time < 0)
		{
			actor = this.CreateStaticParts(4, this.mat_center);
			this.time <- null;
		}
		else
		{
			this.time <- ::manbow.Number();
			this.time.Initialize(this.texture, 0, 656, 32, 54, 2, 0, true);
			this.time.SetValue(99);
			this.time.x = 640 + 32;
			this.time.y = actor.GetFramePointY(0);
			this.time.ConnectRenderSlot(::graphics.slot.status, 1000);
			this.AddParts(this.time, this.mat_center);
		}

		this.fps <- ::manbow.Number();
		this.fps.Initialize(this.texture, 0, 575, 16, 18, 2, -5, true);
		this.fps.SetValue(0);
		this.fps.x = 1279;
		this.fps.y = 1;
		this.fps.ConnectRenderSlot(::graphics.slot.status, 1000);
		this.fps.visible = ::config.graphics.fps;
		local bottom = [
			this.CreateStaticParts(10, this.mat_left_bottom),
			this.CreateStaticParts(11, this.mat_right_bottom)
		];
		this.gauge = [
			{},
			{}
		];

		foreach( i, v in this.gauge )
		{
			local t = ::battle.team[i];
			local offset = i * 10;
			local dir = i == 0 ? 1.00000000 : -1.00000000;
			local mat_top = i == 0 ? this.mat_left_top : this.mat_right_top;
			local mat_bottom = i == 0 ? this.mat_left_bottom : this.mat_right_bottom;
			local mat = ::manbow.Matrix();
			v.team <- t;
			v.regain <- this.Gauge();
			v.regain.Initialize(100 + offset, mat_top);
			v.regain.actor.SetTake(3);
			v.damage <- this.Gauge();
			v.damage.Initialize(100 + offset, mat_top);
			v.damage.actor.SetTake(2);
			v.life <- this.Gauge();
			v.life.Initialize(100 + offset, mat_top);
			v.op <- this.Gauge();
			v.op.Initialize(200 + offset, mat_top);
			v.op_state <- this.CreateStaticParts(lang * 10000 + 201 + offset, mat_top);
			v.op_state.visible = false;
			v.op_flash <- this.CreateStaticParts(203 + offset, mat_top);
			v.op_flash.visible = false;
			v.op_flash2 <- this.CreateStaticParts(lang * 10000 + 202 + offset, mat_top);
			v.op_flash2.visible = false;
			local a = [
				this.Gauge(),
				this.Gauge(),
				this.Gauge(),
				this.Gauge(),
				this.Gauge()
			];

			for( local j = 0; j < 5; j = ++j )
			{
				a[j].Initialize(300 + offset + j, mat_bottom);
			}

			v.mp <- a;
			a = [
				this.SPGauge(),
				this.SPGauge()
			];
			a[0].Initialize(t.sp_max, bottom[i].GetFramePointX(0), bottom[i].GetFramePointY(0), dir, mat_bottom);
			a[1].Initialize(t.sp_max2 - t.sp_max, bottom[i].GetFramePointX(0) + ((a[0].length * a[0].scale).tointeger() + 19) * dir, bottom[i].GetFramePointY(0), dir, mat_bottom);
			v.sp <- a;
			actor = ::spell.CreateCardSprite(t.master_name, t.master.spellcard.id);
			mat = ::manbow.Matrix();
			mat.SetTranslation(bottom[i].GetFramePointX(1) - ::spell.width / 2, bottom[i].GetFramePointY(1) - ::spell.height / 2, 0);
			this.AddParts(actor, mat_bottom, mat);
			actor.ConnectRenderSlot(::graphics.slot.status, 1200);
			v.spell <- actor;

			if ("match_num" in ::battle)
			{
				v.win <- [];

				for( local j = 0; j < ::battle.match_num; j = ++j )
				{
					mat = ::manbow.Matrix();
					mat.SetTranslation(j * dir * -32, 0, 0);
					actor = this.CreateStaticParts(220 + i, mat_top, mat);
					v.win.push(actor);
				}
			}

			v.face_slave <- face_slave[i];
		}

		::graphics.slot.status.Show(false);
	}
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
				this.text.x = ::setting.ping.X - ((this.text.width * this.text.sx) / 2);
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
	// ::debug.print_value(::battle.team[0].current.group);
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
	check p1.motion to have frame data of one attack only
	*/
	::setting.frame_data.update_consts();
	local frame = {};
	frame.motion <- 0;
	frame.data <- [
		0,//startup
		[0],//active
		0,//recovery
	];
	frame.timer <- 0;
	frame.text <- ::font.CreateSystemString("");
	frame.text.sx = ::setting.frame_data.SX;
	frame.text.sy = ::setting.frame_data.SY;
	frame.text.red = ::setting.frame_data.red;
	frame.text.green = ::setting.frame_data.green;
	frame.text.blue = ::setting.frame_data.blue;
	frame.text.alpha = ::setting.frame_data.alpha;
	frame.text.ConnectRenderSlot(::graphics.slot.status, 1);
	if (::setting.frame_data.input_flags){
		frame.flags <- ::font.CreateSystemString("");
		frame.flags.sx = ::setting.frame_data.SX;
		frame.flags.sy = ::setting.frame_data.SY;
		frame.flags.red = ::setting.frame_data.red;
		frame.flags.green = ::setting.frame_data.green;
		frame.flags.blue = ::setting.frame_data.blue;
		frame.flags.alpha = ::setting.frame_data.alpha;
		frame.flags.ConnectRenderSlot(::graphics.slot.status,1);
	}
	frame.frameStr <- "";
	frame.flagStr <- "";
	// frame.attackStr <- "";
	// frame.lastLog <- "";
	frame.Update <- function () {
		local p1 = ::battle.team[0].current;
		local fre = p1.IsFree();
		local active = ::setting.frame_data.IsFrameActive(::battle.team[0].current);
		if ( !fre && (p1.IsAttack() > 0 && p1.IsAttack() < 6)) {
			this.timer = ::setting.frame_data.timer;
			if (this.motion != p1.motion) {
				this.data = [0,[0],0];
				this.motion = p1.motion;
			}
			if (active && p1.hitStopTime == 0){
				if (this.data[2] != 0){
					this.data[1].append(data[2]);
					this.data[2] = 0;
					this.data[1].append(0);
				}
				this.data[1][this.data[1].len()-1]++;
			}else if (!active && p1.hitStopTime == 0){this.data[this.data[1][0] != 0 ? 2 : 0]++;}
		}
		else {this.data = [0,[0],0];this.timer--;}
		// local log = "";
		local activeStr = "";
		for(local i = 0; i < this.data[1].len(); i++){
			if (i > 2 && i != this.data[1].len()-1){
				if (this.data[1][i] == this.data[1][i - 2])activeStr += "+";
				continue;
			}
			activeStr += format(!(i & 1) ? "%2d" : "%2d not active",data[1][i]);
			activeStr += i != (this.data[1].len()-1) ? ">" : "";
		}
		local frame = format("%s%s%s",
			this.data[0] > 0 ? format("startup:%2d ",this.data[0]+1) : "",
			this.data[1][0] != 0 ? "active:"+activeStr+" " : "",
			this.data[2] > 0 ? format("recovery:%2d ",this.data[2]) : "");
		if (frame != "" && !fre && (p1.IsAttack() > 0 && p1.IsAttack() < 6)){
			this.frameStr = frame;
			// log+=frame;
		}
		this.text.Set(this.timer > 0 ? this.frameStr : "");
		this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
		this.text.y = ::setting.frame_data.Y - this.text.height;
		if (::setting.frame_data.input_flags){
			local flags = "";
			for (local i = 32 -1; i >= 0; i--){
				local v = 1 << i;
				local str = "";
				if (p1.flagState & v){
					switch (v){
						case 0x1://1
							str = "no input,";
							break;
						case 0x10://16
							str = "block,";
							break;
						case 0x20://32
							str = "special cancel,";
							break;
						case 0x100://256
							str = "can be counter hit,";
							break;
						case 0x200://512
							str = "can dial,";
							break;
						case 0x400://1024
							str = "bullet cancel,";
							break;
						case 0x800://2048
							str = "attack block,";
							break;
						case 0x1000://4096
							str = "graze,";
							break;
						case 0x2000://8192
							str = "no grab,";
							break;
						case 0x4000://16384
							str = "dash cancel,";
							break;
						case 0x8000://32768
							str = "melee immune,";
							break;
						case 0x10000://65536
							str = "bullet immune,";
							break;
						case 0x200000://2097152
							str = "knock check,";
							break;
						case 0x1000000://16777216
							str = "no landing,";
							break;
						case 0x80000000://2147483648
							str = "invisible,";
							break;
						default:
							str = format("%d,",v);
							break;
					}
				}
				flags += str;
			}
			if (this.flagStr != flags && !fre && (p1.IsAttack() > 0 && p1.IsAttack() < 6)){
				this.flagStr = flags;
				// log += flags != "" ? format("[%s]",flags) : "none";
			}
			this.flags.Set(this.timer > 0 ? format("[%s]",this.flagStr) : "");
			this.flags.x = ::setting.frame_data.X - ((this.flags.width * this.flags.sx) / 2);
			this.flags.y = ::setting.frame_data.Y;
			// local bin1 = "";
			// for (local i = 32 -1; i >= 0; i--){
			// 	local v = 1 << i;
			// 	if (p1.flagAttack & v)bin1 += format("%d,",v);
			// }
			// if (this.attackStr != bin1 && !fre && (p1.IsAttack() > 0 && p1.IsAttack() < 6)){
			// 	this.attackStr = bin1;
			// 	log += bin1 != "" ? format("[%s]",bin1) : "//none";
			// }
		}
		// if (log != "" && this.lastLog != log+"\n"){
		// 	this.lastLog = log+"\n";
		// 	::debug.print(this.lastLog);
		// }
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
			if (!(this.active = !this.active))::battle.gauge.Hide();
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
