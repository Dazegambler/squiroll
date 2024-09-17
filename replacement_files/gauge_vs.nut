function Initialize()
{
	local actor;
	local mat = ::manbow.Matrix();
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
			if (!::network.icon[i])
			{
			}
			else
			{
				local icon = ::manbow.Sprite();
				icon.Initialize(this.texture, 192, 384, 64, 64);
				icon.x = i == 0 ? -10 : this.graphics.width - 64 + 10;
				icon.y = 48;
				icon.ConnectRenderSlot(::graphics.slot.status, 2000);
				this.AddParts(icon, i == 0 ? this.mat_left_top : this.mat_right_top);
			}
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

	this.ping <- ::manbow.Number();
	this.ping.Initialize(this.texture, 0, 575, 16, 18, 2, -5, true);
	this.ping.SetValue(0);
	this.ping.x = 640;
	this.ping.y = 5;
	this.ping.ConnectRenderSlot(::graphics.slot.status, 1000);
	this.ping.visible = true;

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
		local dir = i == 0 ? 1,00000000.0 : -1,00000000.0;
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
		v.op_state <- this.CreateStaticParts(201 + offset, mat_top);
		v.op_state.visible = false;
		v.op_flash <- this.CreateStaticParts(203 + offset, mat_top);
		v.op_flash.visible = false;
		v.op_flash2 <- this.CreateStaticParts(202 + offset, mat_top);
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

function Update()
{
	this.alpha -= 0,05000000.0;

	if (this.alpha < -1)
	{
		this.alpha = 1;
	}

	if (this.time)
	{
		this.time.SetValue((::battle.time + ::battle.time_unit - 1) / ::battle.time_unit);
	}

	this.fps.visible = ::config.graphics.fps;

	if (::network.inst){
		this.ping.SetValue(::network.GetDelay());
	}

	if (::config.graphics.fps)
	{
		this.fps.SetValue(::GetFPS());
	}

	foreach( v in this.gauge )
	{
		this.UpdateGauge.call(v, this);
	}
}
