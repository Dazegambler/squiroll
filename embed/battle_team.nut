class this.PlayerTeamData
{
	index = 0;
	master_name = "";
	slave_name = "";
	master = null;
	slave = null;
	slave_sub = null;
	current = null;
	slave_ban = 0;
	change_count = 0;
	input = null;
	device_id = 0;
	target = null;
	start_x = 0;
	start_y = 0;
	life = 9999;
	regain_life = 9999;
	life_limit = 0;
	enable_regain = true;
	damage_life = 9999;
	life_max = 9999;
	shield_life = 0;
	shield_life_max = 9999;
	sp = 0;
	sp_stop = 0;
	sp_rate = 1;
	sp_max = 500;
	sp_max2 = 2000;
	sp2_enable = true;
	spell_active = false;
	spell_use_count = 0;
	spell_time = 0;
	spell_enable_end = true;
	mp = 0;
	mp_stop = 0;
	op = 0;
	op_leak = 0;
	op_stop = 0;
	op_stop_max = 100;
	combo = null;
	combo_break = false;
	combo_count = 0;
	combo_damage = 0;
	combo_reset_count = 0;
	combo_change = 0;
	damage_scale = 1;
	counter_scale = 1;
	base_scale = 1;
	kaiki_scale = 1.00000000;
	combo_stun = 0;
	combo_wall = 0;
	combo_ground = 0;
	combo_hit_id = 0;
	player_update = null;
	stop_reserve = 0;
	time_stop_count = 0;
	time_stop_mask = 0;
	group_object = 0;
	group_team = 0;
	group_nonstop = 0;
	callback_group_shot = 0;
	callback_mask_shot = 0;
	callback_group_object_shot = 0;
	callback_group_object = 0;
	callback_mask_object = 0;
	callback_group_self = 0;
	callback_mask_self = 0;
	color_back = null;
	fade_back = null;
	fade_screen = null;
	clearBackGroundCount = 0;
	spellBackCount = 0;
	shield = null;
	constructor()
	{
		if (!this.SetDamage)
		{
			this.SetDamage = this.SetDamageBase;
		}

		if (!this.SetDamage_FullRegain)
		{
			this.SetDamage_FullRegain = this.SetDamage_FullRegain_Base;
		}

		if (!this.AddSP)
		{
			this.AddSP = this.AddSP_Base;
		}
	}

	function Release()
	{
		this.master = null;
		this.slave = null;
		this.current = null;
		this.input = null;
		this.combo = null;
		this.target = null;
		this.color_back = null;
		this.fade_back = null;
		this.fade_screen = null;
		this.shield = null;
	}

	function copy(lhs,rhs){
		foreach(i,v in typeof lhs == "instance" ? lhs.getclass() : lhs){
			switch (typeof lhs[i]) {
				case "function":
					break;
				case "table":
				case "class":
				case "instance":
					if(lhs[i])this.copy(rhs[i] <- {},lhs[i]);
					else rhs[i] <- lhs[i];
					break;
				case "integer":
				case "float":
				case "string":
				case "bool":
				case "null":
					rhs[i] <- lhs[i];
					break;
			}
		}
	};

	function StoreState() {
		local data = {};
		this.copy(this,data);
		return data;
	}

	function merge(lhs,rhs,known){
		foreach(i,v in typeof lhs == "instance" ? lhs.getclass() : lhs){
			if (known.find(lhs))break;
			switch (typeof lhs[i]) {
				case "function":
					break;
				case "table":
				case "class":
				case "instance":
					// ::print("on:"+i+"."+lhs[i]+"\n");
					if(lhs[i]) {
						known.append(lhs[i]);
						this.merge(rhs[i],lhs[i],known);
					}else rhs[i] = lhs[i];
					break;
				default:
					// ::print("restoring:"+i+"\n");
					rhs[i] = lhs[i];
					break;
			}
		}
	};

	function RestoreState(state) {
		local known = [];
		this.merge(state,this,known);
	}

	function Update()
	{
		this.input.Update();
		this.combo.Update();
		::battle.rollback.timeline.top()[this] <- this.StoreState();
	}

	function SetGroup( _index )
	{
		this.index = _index;

		switch(this.index)
		{
		case 0:
			this.group_object = 16;
			this.group_team = 1 | 4;
			this.group_nonstop = 256 | 4096;
			this.callback_group_shot = 16;
			this.callback_mask_shot = 2 | 32 | 131072 | 8192 | 4 | 64 | 262144 | 16384;
			this.callback_group_object_shot = 65536;
			this.callback_group_object = 4096;
			this.callback_mask_object = 2 | 32 | 131072 | 8192 | 4 | 64 | 262144 | 16384;
			this.callback_group_self = 1024;
			this.callback_mask_self = 256;
			break;

		case 1:
			this.group_object = 32;
			this.group_team = 2 | 8;
			this.group_nonstop = 512 | 4096;
			this.callback_group_shot = 32;
			this.callback_mask_shot = 1 | 16 | 65536 | 4096 | 4 | 64 | 262144 | 16384;
			this.callback_group_object_shot = 131072;
			this.callback_group_object = 8192;
			this.callback_mask_object = 1 | 16 | 65536 | 4096 | 4 | 64 | 262144 | 16384;
			this.callback_group_self = 2048;
			this.callback_mask_self = 512;
			break;
		}
	}

	function Change()
	{
		::camera.RemoveTarget(this.current);
		this.current = this.current == this.slave ? this.master : this.slave;
		this.change_count++;
		::camera.AddTarget(this.current);
		this.target.team.target = this.current;
	}

	function ChangeSlave()
	{
		if (this.slave_sub == null)
		{
			return;
		}

		local c = this.slave;
		this.slave = this.slave_sub;
		this.slave_sub = c;

		if (this.current != this.master)
		{
			::camera.RemoveTarget(this.current);
			this.current = this.slave;
			::camera.AddTarget(this.current);
			this.target.team.target = this.current;
		}
	}

	function ResetRound()
	{
		this.master.Warp(this.start_x, this.start_y);

		if (this.slave)
		{
			this.slave.Warp(this.start_x, this.start_y);
		}

		this.master.direction = this.index == 0 ? 1.00000000 : -1.00000000;

		if (this.slave)
		{
			this.slave.direction = this.master.direction;
		}

		this.master.Reset_PlayerCommon(true);

		if (this.slave)
		{
			this.slave.Reset_PlayerCommon(true);
		}

		if (this.slave_sub)
		{
			this.slave_sub.Reset_PlayerCommon(true);
		}

		this.master.TeamReset_Change_Master();
		this.slave_ban = 0;
		this.life = this.life_max;
		this.regain_life = this.life_max;
		this.life_limit = 0;
		this.enable_regain = true;
		this.damage_life = this.life_max;
		this.shield_life = 0;
		this.mp = 1000;
		this.mp_stop = 0;
		this.sp_stop = 0;
		this.sp2_enable = true;
		this.op = 1000;
		this.op_leak = 0;
		this.op_stop = 0;
		this.op_stop_max = 0;
		this.spell_active = false;
		this.spell_time = 0;
		this.spell_use_count = 0;
		this.master.spellcard.Deactivate();

		if (this.slave)
		{
			this.slave.spellcard.Deactivate();
		}

		if (this.slave_sub)
		{
			this.slave_sub.spellcard.Deactivate();
		}

		this.master.lastword.Deactivate();
		this.clearBackGroundCount = 0;
		::graphics.ShowBackground(true);
		this.ResetCombo();
	}

	function ResetBoss()
	{
		this.master.Warp(this.start_x, this.start_y);

		if (this.slave)
		{
			this.slave.Warp(this.start_x, this.start_y);
		}

		this.master.direction = this.index == 0 ? 1.00000000 : -1.00000000;

		if (this.slave)
		{
			this.slave.direction = this.master.direction;
		}

		this.master.Reset_PlayerCommon(true);

		if (this.slave)
		{
			this.slave.Reset_PlayerCommon(true);
		}

		if (this.slave_sub)
		{
			this.slave_sub.Reset_PlayerCommon(true);
		}

		this.master.TeamReset_Change_Master();
		this.slave_ban = 0;
		this.life = this.life_max;
		this.regain_life = this.life_max;
		this.life_limit = 0;
		this.enable_regain = true;
		this.damage_life = this.life_max;
		this.shield_life = 0;
		this.mp = 1000;
		this.mp_stop = 0;
		this.sp_stop = 0;
		this.sp2_enable = true;
		this.op = 1000;
		this.op_leak = 0;
		this.op_stop = 0;
		this.op_stop_max = 0;
		this.spell_active = false;
		this.spell_time = 0;
		this.spell_use_count = 0;
		this.master.spellcard.Deactivate();

		if (this.slave)
		{
			this.slave.spellcard.Deactivate();
		}

		if (this.slave_sub)
		{
			this.slave_sub.spellcard.Deactivate();
		}

		this.master.lastword.Deactivate();
		this.clearBackGroundCount = 0;
		::graphics.ShowBackground(true);
		this.ResetCombo();
	}

	SetDamage = null;
	function SetDamageBase( damage, disable_ko )
	{
		if (::battle.state != 8)
		{
			return;
		}

		if (this.combo_count == 0)
		{
			this.damage_life = this.life;
		}

		if (this.current == this.master)
		{
			if (damage > 0)
			{
				if (this.shield_life > 0)
				{
					this.shield_life -= this.shield_rate * damage.tointeger();

					if (this.shield_life < 0)
					{
						this.shield_life = 0;
					}
				}
				else
				{
					this.life -= damage.tointeger();

					if (this.slave_ban)
					{
						this.regain_life = this.life;
					}
					else
					{
						this.regain_life -= (damage * 0.75000000).tointeger();

						if (this.regain_life < this.life)
						{
							this.regain_life = this.life;
						}
					}
				}

				if (this.current.pEvent_getDamage)
				{
					this.current.pEvent_getDamage(damage);
				}
			}
			else
			{
				this.life -= damage.tointeger();

				if (this.regain_life > this.life_max)
				{
					this.regain_life = this.life_max;
				}
				else if (this.regain_life < this.life)
				{
					this.regain_life = this.life;
				}

				if (this.life_max > 1 && this.life > this.life_max)
				{
					this.regain_life = this.life = this.life_max;
				}
			}
		}
		else if (damage > 0)
		{
			if (this.current.pEvent_getDamage)
			{
				this.current.pEvent_getDamage(damage);
			}

			if (this.shield_life > 0)
			{
				this.shield_life -= damage.tointeger();

				if (this.shield_life < 0)
				{
					this.shield_life = 0;
				}
			}
			else
			{
				this.regain_life -= damage.tointeger();

				if (this.regain_life < this.life)
				{
					this.life = this.regain_life;
				}
			}
		}
		else
		{
			this.life -= damage.tointeger();

			if (this.regain_life > this.life_max)
			{
				this.regain_life = this.life_max;
			}
			else if (this.regain_life < this.life)
			{
				this.regain_life = this.life;
			}

			if (this.life_max > 1 && this.life > this.life_max)
			{
				this.regain_life = this.life = this.life_max;
			}
		}

		if (this.life <= 0)
		{
			if (disable_ko)
			{
				this.life = 1;

				if (this.regain_life < this.life)
				{
					this.regain_life = this.life;
				}
			}
			else
			{
				this.life = 0;
				this.regain_life = 0;
			}
		}
	}

	function SetDamageBoss( damage, disable_ko )
	{
		if (::battle.state != 8)
		{
			return;
		}

		if (this.combo_count == 0)
		{
			this.damage_life = this.life;
		}

		if (this.current == this.master)
		{
			if (damage > 0)
			{
				if (this.life <= this.life_limit)
				{
					damage = (damage * 0.20000000).tointeger();
				}
				else if (this.life - damage.tointeger() < this.life_limit)
				{
					local d_ = this.life - this.life_limit;
					damage = d_ + ((damage - d_) * 0.20000000).tointeger();
				}

				this.life -= damage.tointeger();
				this.regain_life -= damage.tointeger();

				if (this.current.stanBossCount > 0)
				{
					this.regain_life = this.life;
				}

				if (this.current.pEvent_getDamage)
				{
					this.current.pEvent_getDamage(damage);
				}
			}
			else
			{
				this.life -= damage.tointeger();

				if (this.regain_life > this.life_max)
				{
					this.regain_life = this.life_max;
				}
				else if (this.regain_life < this.life)
				{
					this.regain_life = this.life;
				}

				if (this.life_max > 1 && this.life > this.life_max)
				{
					this.regain_life = this.life = this.life_max;
				}
			}
		}
		else if (damage > 0)
		{
			this.regain_life -= damage.tointeger();

			if (this.regain_life < 1)
			{
				this.regain_life = 1;
			}

			if (this.regain_life < this.life)
			{
				this.life = this.regain_life;
			}

			if (this.current.pEvent_getDamage)
			{
				this.current.pEvent_getDamage(damage);
			}
		}
		else
		{
			this.life -= damage.tointeger();

			if (this.regain_life < this.life)
			{
				this.life = this.regain_life;
			}
		}

		if (this.life <= 0)
		{
			if (disable_ko)
			{
				this.life = 1;

				if (this.regain_life < this.life)
				{
					this.regain_life = this.life;
				}
			}
			else
			{
				this.life = 0;
				this.regain_life = 0;
			}
		}
	}

	SetDamage_FullRegain = null;
	function SetDamage_FullRegain_Base( damage, disable_ko )
	{
		if (::battle.state != 8)
		{
			return;
		}

		if (this.combo_count == 0)
		{
			this.damage_life = this.life;
		}

		this.life -= damage.tointeger();

		if (damage > 0)
		{
			if (this.regain_life < this.life)
			{
				this.regain_life = this.life;
			}
		}
		else
		{
			if (this.regain_life > this.life_max)
			{
				this.regain_life = this.life_max;
			}
			else if (this.regain_life < this.life)
			{
				this.regain_life = this.life;
			}

			if (this.life_max > 1 && this.life > this.life_max)
			{
				this.regain_life = this.life = this.life_max;
			}
		}

		if (this.life <= 0)
		{
			this.life = 0;

			if (disable_ko)
			{
				this.life = 1;

				if (this.regain_life < this.life)
				{
					this.regain_life = this.life;
				}
			}
			else
			{
				this.regain_life = 0;
			}
		}
	}

	function SetDamage_FullRegain_Story( damage, disable_ko )
	{
		if (::battle.state != 8)
		{
			return;
		}

		if (this.combo_count == 0)
		{
			this.damage_life = this.life;
		}

		this.life -= damage.tointeger();

		if (damage > 0)
		{
			if (this.regain_life < this.life)
			{
				this.regain_life = this.life;
			}
		}
		else
		{
			if (this.regain_life > this.life_max)
			{
				this.regain_life = this.life_max;
			}
			else if (this.regain_life < this.life)
			{
				this.regain_life = this.life;
			}

			if (this.life_max > 1 && this.life > this.life_max)
			{
				this.regain_life = this.life = this.life_max;
			}
		}

		if (this.life <= 0)
		{
			this.life = 0;

			if (disable_ko)
			{
				this.regain_life -= damage;

				if (this.regain_life < 0)
				{
					this.regain_life = 1;
				}

				this.life = 1;

				if (this.regain_life < this.life)
				{
					this.regain_life = this.life;
				}
			}
			else
			{
				this.regain_life = 0;
			}
		}
	}

	function SetComboDamage( atk, damage, min_scale = 0.10000000, disable_kill = false )
	{
		local scale = this.damage_scale;
		scale = scale * this.counter_scale;
		scale = scale * this.base_scale;

		if (scale < min_scale)
		{
			scale = min_scale;
		}

		if (scale < 0.10000000)
		{
			scale = 0.10000000;
		}

		scale = scale * this.kaiki_scale;
		scale = scale * this.GetGutsRate();
		scale = scale * atk.owner.atkRate;
		scale = scale * atk.atkRate_Pat;
		scale = scale * this.current.defRate;
		local d = (damage * scale).tointeger();
		this.combo_damage += d;

		if (this.current != this.master)
		{
			this.AddOP(-d / 4, 0);
		}

		this.SetDamage(d, disable_kill);
		return d;
	}

	function SetDamageScale( scale )
	{
		this.combo_count++;

		if (scale)
		{
			this.damage_scale -= scale;
		}

		if (this.damage_scale <= 0.10000000)
		{
			this.damage_scale = 0.10000000;
		}

		if (this.combo_count)
		{
			this.combo.Activate();
		}
		else
		{
		}
	}

	function ResetCombo()
	{
		if (this.combo_reset_count <= 0)
		{
			this.combo.Deactivate();

			if (this.combo_change >= 2 && this.combo_damage >= 6000)
			{
				::trophy.TeamCombo(this.target.team.index);
			}

			this.base_scale = 1.00000000;
			this.counter_scale = 1.00000000;
			this.combo_count = 0;
			this.combo_damage = 0;
			this.damage_scale = 1.00000000;
			this.kaiki_scale = 1.00000000;
			this.combo_change = 0;
			this.combo_break = false;
			this.combo_reset_count = 0;
			this.combo_stun = 0;
			this.combo_wall = 0;
			this.combo_ground = 0;
			this.combo_hit_id = 0;
			this.target.team.sp_rate = 1.00000000;
			this.target.team.master.hit_id = 0;

			if (this.target.team.slave)
			{
				this.target.team.slave.hit_id = 0;
			}
		}
		else
		{
		}
	}

	function GetGutsRate()
	{
		return 0.75000000 + 0.50000000 * this.life / this.life_max;
	}

	function AddMP( v, stop )
	{
		this.mp += v.tointeger();

		if (this.mp > 1000)
		{
			this.mp = 1000;
		}
		else if (this.mp < 0)
		{
			this.mp = 0;
		}

		if (stop > this.mp_stop)
		{
			this.mp_stop = stop;
		}
	}

	AddSP = null;
	function AddSP_Base( v )
	{
		if (this.spell_active)
		{
			return;
		}

		if (this.sp_rate != 1)
		{
			v = (v * this.sp_rate).tointeger();
		}

		if (this.sp < this.sp_max2 && this.sp + v >= this.sp_max2 && this.sp2_enable)
		{
			this.PlaySE(866);
			local t_ = {};
			t_.owner <- this.current.weakref();
			t_.type <- 1;
			this.current.SetEffect(this.index == 0 ? 40 : 1240, 664, 1.00000000, ::actor.effect_class.EF_SpellCharge, t_);
		}

		if (this.sp < this.sp_max && this.sp + v >= this.sp_max)
		{
			this.PlaySE(865);
			local t_ = {};
			t_.owner <- this.current.weakref();
			t_.type <- 0;
			this.current.SetEffect(this.index == 0 ? 40 : 1240, 664, 1.00000000, ::actor.effect_class.EF_SpellCharge, t_);
		}

		this.sp += v.tointeger();

		if (this.sp2_enable)
		{
			if (this.sp > this.sp_max2)
			{
				this.sp = this.sp_max2;
			}
		}
		else if (this.sp > this.sp_max)
		{
			this.sp = this.sp_max;
		}
	}

	function AddSP_Boss( v_ )
	{
	}

	function AddOP( v, stop )
	{
		if (this.op_stop > 0 && v > 0)
		{
			return;
		}

		this.op += v.tointeger();

		if (this.op > 2000)
		{
			this.op = 2000;
		}

		if (this.op < 0)
		{
			this.op = 0;
		}

		if (stop > this.op_stop)
		{
			this.op_stop = stop;
		}

		if (stop > 0)
		{
			this.op_stop_max = stop;
		}
	}

	function CheckKO()
	{
		return this.life <= 0 && this.current.enableKO;
	}

}

function CreateTeam( index, param )
{
	local t_master = param.master;
	local t_slave = param.slave;
	local t_slave2 = param.slave_sub;
	local team_data = this.PlayerTeamData();
	local t_player = [];
	t_player.append(t_master);

	if (t_slave)
	{
		t_player.append(t_slave);
	}

	if (t_slave2)
	{
		t_player.append(t_slave2);
	}

	foreach( v in t_player )
	{
		local class_data = [
			v.player_class,
			v.shot_class,
			v.collision_object_class,
			v.player_effect_class
		];

		foreach( c in class_data )
		{
			c.team <- team_data;
			c.shot_class <- v.shot_class.weakref();
			c.collision_object_class <- v.collision_object_class.weakref();
			c.player_effect_class <- v.player_effect_class.weakref();
			c.effect_class <- ::actor.effect_class.weakref();
		}

		v.player_class.spellcard <- null;
		v.player_class.lastword <- null;
	}

	this.team[index] = team_data;
	team_data.master_name = t_master.name;

	if (t_slave)
	{
		team_data.slave_name = t_slave.name;
	}

	team_data.SetGroup(index);

	if (t_master.mode == 3)
	{
		team_data.input = ::input.CreatePlayerInputDevicePractice2P(param.device_id);
	}
	else
	{
		team_data.input = ::input.CreatePlayerInputDevice(index, param.device_id);
	}

	team_data.device_id = param.device_id;
	team_data.start_x = param.start_x;
	team_data.start_y = param.start_y;
	local actor = [];
	team_data.master = t_master.mgr.CreateActor2D(t_master.player_class, param.start_x, param.start_y, param.start_direction, null, null);
	team_data.master.spellcard = this.SpellCard();
	team_data.master.lastword = this.SpellCard();
	team_data.master.spellcard.Initialize(param.master_spell, 0, index);
	team_data.master.lastword.Initialize(3, 0, index);
	actor.append(team_data.master);

	if (t_slave)
	{
		team_data.slave = t_slave.mgr.CreateActor2D(t_slave.player_class, param.start_x, param.start_y, param.start_direction, null, null);
		team_data.slave.spellcard = this.SpellCard();
		team_data.slave.spellcard.Initialize(param.slave_spell, 1, index);
		actor.append(team_data.slave);
	}

	if (t_slave2)
	{
		team_data.slave_sub = t_slave2.mgr.CreateActor2D(t_slave2.player_class, param.start_x, param.start_y, param.start_direction, null, null);
		team_data.slave_sub.spellcard = this.SpellCard();
		team_data.slave_sub.spellcard.Initialize(param.slave_sub_spell, 1, index);
		actor.append(team_data.slave_sub);
	}

	team_data.current = team_data.master;

	foreach( i, v in t_player )
	{
		v.shot_class.owner <- actor[i].weakref();
		v.collision_object_class.owner <- actor[i].weakref();
		v.player_effect_class.owner <- actor[i].weakref();
	}

	team_data.combo = this.Combo();
	team_data.combo.Initialize(index);
	::camera.AddTarget(team_data.current);
}

