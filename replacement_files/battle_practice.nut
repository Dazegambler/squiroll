this.time = -1;
this.current <- 0;
this.time_count <- 0;
this.life_max <- [
	10000,
	10000
];
this.regain_max <- [
	10000,
	10000
];
this.mp_max <- [
	10000,
	10000
];
this.op_max <- [
	10000,
	10000
];
this.sp_max <- [
	10000,
	10000
];
this.guard <- [
	5,
	5
];
this.slave_2p <- -1;
this.marisa <- [
	-1,
	-1
];
this.hijiri <- [
	-1,
	-1
];
this.futo <- [
	-1,
	-1
];
this.miko <- [
	-1,
	-1
];
this.mamizou <- [
	-1,
	-1
];
this.kokoro <- [
	-1,
	-1
];
this.udonge <- [
	-1,
	-1
];
this.doremy <- [
	-1,
	-1
];
this.recorder <- null;
this.macro_file_name <- "";
this.version <- 0;
this.macro_dir <- "macro";
this.NONE <- 0;
this.RECORD <- 1;
this.PLAY <- 2;
this.macro_state <- this.NONE;
this.PlayerTeamData.SetDamage <- function ( damage, disable_ko )
{
	this.SetDamageBase(damage, disable_ko);

	if (this.life <= 0)
	{
		this.life = 1;

		if (this.regain_life < this.life)
		{
			this.regain_life = this.life;
		}
	}
};
this.GuardCrash_Check = this.GuardCrash_Check_VS;
function Apply()
{
	local param = ::config.practice;

	for( local i = 0; i < 2; i = ++i )
	{
		this.life_max[i] = ::practice.life[param.life[i]];
		this.regain_max[i] = ::practice.life[param.regain[i]];
		this.mp_max[i] = ::practice.mp[param.mp[i]];
		this.op_max[i] = ::practice.op[param.op[i]];
		this.sp_max[i] = ::practice.sp[param.sp[i]];
		this.guard[i] = ::practice.guard[param.guard[i]];
		this.marisa[i] = ::practice.marisa[param.marisa[i]];
		this.hijiri[i] = ::practice.hijiri[param.hijiri[i]];
		this.futo[i] = ::practice.futo[param.futo[i]];
		this.miko[i] = ::practice.miko[param.miko[i]];
		this.mamizou[i] = ::practice.mamizou[param.mamizou[i]];
		this.kokoro[i] = ::practice.kokoro[param.kokoro[i]];
		this.udonge[i] = ::practice.udonge[param.udonge[i]];
		this.doremy[i] = ::practice.doremy[param.doremy[i]];
	}

	this.slave_2p = ::practice.slave_2p[param.slave_2p];
	this.team[0].input.Lock();
	this.team[1].input.Lock();
}

function Pause()
{
	::sound.PlaySE(111);
	::menu.practice.Initialize();
}

function Begin()
{
	this.Round_Begin();
}

function Round_Begin()
{
	this.demoCount = 0;
	this.endWinDemo = [
		false,
		false
	];
	this.endLoseDemo = [
		false,
		false
	];
	this.skipDemo = [
		false,
		false
	];
	this.enable_contact_test = false;
	this.gauge.Show(0);
	::camera.Reset();
	::camera.SetTarget(640, 340, 2.00000000, true);
	::sound.PlayBGM(null);
	::graphics.FadeIn(60);
	this.team[0].mp = 1000;
	this.team[1].mp = 1000;
	this.team[0].op = 2000;
	this.team[1].op = 2000;
	this.state = 8;
	this.battleUpdate = this.Game_BattleUpdate;
	this.enable_contact_test = true;
	this.time = -1;
	this.time_count = 0;
	::camera.SetTarget(640, 340, 2.00000000, true);
	::camera.SetMode_Battle();
	this.Apply();
}

function Game_BattleUpdate()
{
	if (this.macro_state == this.PLAY)
	{
		this.team[1].input.b10 = 0;

		if (this.recorder.IsFinished(0))
		{
			this.recorder.SetDevice(0, this.team[1].input);
			this.recorder.BeginPlay(0);
			this.PracticeRestart();
		}
	}

	if (this.team[this.current].input.b3 > 0 && this.team[this.current].input.b4 > 0){
		::input.ClearDeviceAssign(this.team[this.current].input);
		local i = ++this.current != 1 ? this.current = 0 : 1;
		//::debug.print(i+"\n");
		::input.SetDeviceAssign(0, this.team[0].device_id, this.team[i].input);
	}

	local b_ = 0;

	if (this.team[0].input.b0 > 0)
	{
		b_++;
	}

	if (this.team[0].input.b1 > 0)
	{
		b_++;
	}

	if (this.team[0].input.b2 > 0)
	{
		b_++;
	}

	if (this.team[0].input.b3 > 0)
	{
		b_++;
	}

	if (this.team[0].input.b4 > 0)
	{
		b_++;
	}

	if (this.team[0].input.b5 > 0)
	{
		b_++;
	}

	if (b_ >= 4)
	{
		this.PracticeRestart();
		return;
	}

	if (this.team[0].life <= 0)
	{
		this.team[0].life = 1;
	}

	if (this.team[1].life <= 0)
	{
		this.team[1].life = 1;
	}

	this.time_count++;

	if (this.time_count == 1200)
	{
		::trophy.Practice();
	}

	if (this.team[0].current.command)
	{
		this.team[0].current.command.Update(this.team[0].current.direction, this.team[0].current.hitStopTime <= 0 && this.team[0].current.damageStopTime <= 0);
	}

	if (this.team[1].index == 0)
	{
		if (this.team[1].current.command)
		{
			this.team[1].current.command.Update(this.team[1].current.direction, this.team[1].current.hitStopTime <= 0 && this.team[1].current.damageStopTime <= 0);
		}
	}
	else if (::battle.macro_state > 0)
	{
		if (this.team[1].current.command)
		{
			this.team[1].current.command.Update(this.team[1].current.direction, this.team[1].current.hitStopTime <= 0 && this.team[1].current.damageStopTime <= 0);
		}
	}
	else if (!this.team[1].current.cpuState)
	{
		if (::config.practice.player2 == 4 && this.team[1].current.command)
		{
			this.team[1].current.command.Update(this.team[1].current.direction, this.team[1].current.hitStopTime <= 0 && this.team[1].current.damageStopTime <= 0);
		}
	}

	if (this.team[0].current.IsFree() && this.team[1].current.IsFree())
	{
		for( local i = 0; i < 2; i = ++i )
		{
			this.team[0].master.practice_update();
			this.team[0].slave.practice_update();
			this.team[1].master.practice_update();
			this.team[1].slave.practice_update();

			if (this.life_max[i] >= 0)
			{
				this.team[i].life = this.life_max[i];
			}

			if (this.regain_max[i] >= 0)
			{
				this.team[i].regain_life = this.regain_max[i];

				if (this.team[i].regain_life < this.team[i].life)
				{
					this.team[i].regain_life = this.team[i].life;
				}
			}

			if (this.mp_max[i] >= 0)
			{
				this.team[i].mp = this.mp_max[i];
				this.team[i].mp_stop = 0;
			}

			if (this.op_max[i] >= 0)
			{
				if (this.team[i].current == this.team[i].master)
				{
					this.team[i].op = this.op_max[i];
					this.team[i].op_stop = 0;
				}
			}

			if (this.sp_max[i] >= 0)
			{
				if (this.team[i].spell_active == false)
				{
					switch(this.sp_max[i])
					{
					case 0:
						this.team[i].sp = 0;
						break;

					case 1:
						this.team[i].sp = this.team[i].sp_max;
						break;

					case 2:
						this.team[i].sp = this.team[i].sp_max2;
						break;
					}

					this.team[i].sp_stop = 0;
					this.team[i].sp2_enable = true;
				}
			}
		}
	}
}

function PracticeRestart()
{
	this.group_player.Clear(-1 & ~15);
	this.group_effect.Clear(-1);
	this.team[0].ResetRound();
	this.team[1].ResetRound();

	if (this.team[0].master.resetPracticeFunc)
	{
		this.team[0].master.resetPracticeFunc();
	}

	if (this.team[0].slave.resetPracticeFunc)
	{
		this.team[0].slave.resetPracticeFunc();
	}

	if (this.team[1].master.resetPracticeFunc)
	{
		this.team[1].master.resetPracticeFunc();
	}

	if (this.team[1].slave.resetPracticeFunc)
	{
		this.team[1].slave.resetPracticeFunc();
	}

	this.team[0].op = this.op_max[0];
	this.team[0].op_stop = 0;
	this.team[1].op = this.op_max[1];
	this.team[1].op_stop = 0;

	if (this.slave_2p == 1)
	{
		this.team[1].master.Team_Change_Common();
		this.team[1].master.Team_Bench_In();
		this.team[1].slave.EndtoFreeMove();
	}

	if (::config.practice.position[0] > 0)
	{
		this.team[0].master.Warp(1280 * (::config.practice.position[0] - 1) / 20, this.team[0].master.centerY);
		this.team[0].slave.Warp(1280 * (::config.practice.position[0] - 1) / 20, this.team[0].slave.centerY);
	}

	if (::config.practice.position[1] > 0)
	{
		this.team[1].master.Warp(1280 * (::config.practice.position[1] - 1) / 20, this.team[1].master.centerY);
		this.team[1].slave.Warp(1280 * (::config.practice.position[1] - 1) / 20, this.team[1].slave.centerY);
	}

	if (this.team[0].master.x <= this.team[1].master.x)
	{
		this.team[0].master.direction = 1.00000000;
		this.team[0].slave.direction = 1.00000000;
		this.team[1].master.direction = -1.00000000;
		this.team[1].slave.direction = -1.00000000;
	}
	else
	{
		this.team[0].master.direction = -1.00000000;
		this.team[0].slave.direction = -1.00000000;
		this.team[1].master.direction = 1.00000000;
		this.team[1].slave.direction = 1.00000000;
	}

	this.team[0].current.autoGuard = false;
	this.team[1].current.autoGuard = false;
	this.team[0].time_stop_count = 0;
	this.team[1].time_stop_count = 0;
	this.time_stop_count = 0;
	this.slow_count = 0;
	this.demoCount = 0;
	this.enable_contact_test = true;
	this.gauge.Show(0);
	::camera.Reset();
	::camera.SetTarget(640, 340, 2.00000000, true);
	::camera.SetMode_Battle();
	this.team[0].current.SetSpellBackReset();
	this.team[1].current.SetSpellBackReset();
	this.team[0].current.command.ResetAllReserve();
	this.team[0].current.command.Clear();
	this.team[0].current.input.Lock();
	this.team[1].current.command.ResetAllReserve();
	this.team[1].current.command.Clear();
}

function PracticeRestart_Wait()
{
	this.demoCount++;

	if (this.demoCount >= 10)
	{
		this.state = 8;
		this.battleUpdate = this.Game_BattleUpdate;
		return;
	}
}

function PlayMacro( master_name, slave_name, slot_id )
{
	this.macro_file_name = "macro/" + master_name + "_" + slave_name + "_" + (slot_id + 1) + ".mcr";
	this.recorder = ::manbow.InputRecorder();

	if (!this.recorder.Load(this.macro_file_name, this.version))
	{
		return false;
	}

	local param = ::config.practice;

	foreach( key, val in this.recorder.userdata )
	{
		if (!(key in param))
		{
			continue;
		}

		if (typeof param[key] == "array")
		{
			foreach( index, v in val )
			{
				param[key][index] = v;
			}
		}
		else
		{
			param[key] = val;
		}
	}

	::input.ClearDeviceAssign(this.team[0].input);
	::input.ClearDeviceAssign(this.team[1].input);
	::input.SetDeviceAssign(0, this.team[0].device_id, this.team[0].input);
	::input.SetDeviceAssignPractice2P(this.team[1].device_id, this.team[1].input);
	this.recorder.SetDevice(0, this.team[1].input);
	this.recorder.BeginPlay(0);
	this.macro_state = this.PLAY;
	::trophy.Macro();
	return true;
}

function RecordMacro( master_name, slave_name, slot_id )
{
	::input.ClearDeviceAssign(this.team[0].input);
	::input.ClearDeviceAssign(this.team[1].input);
	::input.SetDeviceAssign(0, this.team[0].device_id, this.team[1].input);
	this.recorder = ::manbow.InputRecorder();
	local param = ::config.practice;
	this.recorder.userdata = {};

	foreach( key, val in param )
	{
		if (typeof val == "array")
		{
			this.recorder.userdata[key] <- [];

			foreach( v in val )
			{
				this.recorder.userdata[key].push(v);
			}
		}
		else
		{
			this.recorder.userdata[key] <- val;
		}
	}

	this.recorder.SetDevice(0, this.team[1].input);
	this.recorder.BeginRecord(0);
	this.macro_state = this.RECORD;
	this.macro_file_name = "macro/" + master_name + "_" + slave_name + "_" + (slot_id + 1) + ".mcr";
}

function StopMacro()
{
	if (this.macro_state == this.RECORD)
	{
		this.recorder.Save(this.macro_file_name, this.version);
		this.recorder.ResetDevice(0);
	}
	else if (this.macro_state == this.PLAY)
	{
		this.recorder.ResetDevice(0);
	}

	::input.ClearDeviceAssign(::battle.team[0].input);
	::input.ClearDeviceAssign(::battle.team[1].input);
	::input.SetDeviceAssign(0, ::battle.team[0].device_id, ::battle.team[0].input);
	::input.SetDeviceAssignPractice2P(::battle.team[1].device_id, ::battle.team[1].input);
	this.macro_state = this.NONE;
}

