function Func_BeginBattle()
{
	if (this.team.master == this && this.team.slave && this.team.slave.type == 8)
	{
		this.BeginBattle_Mamizou(null);
		return;
	}

	this.BeginBattle(null);
}

function Func_Win()
{
	local r_ = this.rand() % 2;

	switch(r_)
	{
	case 0:
		this.WinA(null);
		break;

	case 1:
		this.WinB(null);
		break;
	}
}

function Func_Lose()
{
	this.Lose(null);
}

function BeginBattle_FirePart( t )
{
	this.SetMotion(9000, 5);
	this.rz = this.rand() % 360 * 0.01745329;
	this.rx = (25 - this.rand() % 51) * 0.01745329;
	this.ry = (40 - this.rand() % 81) * 0.01745329;
	this.sx = this.sy = 0.50000000 + this.rand() % 25 * 0.01000000;
	this.SetSpeed_XY((3.00000000 - this.rand() % 9) * this.direction, -(this.rand() % 7));
	this.stateLabel = function ()
	{
		this.VX_Brake(0.10000000);
		this.AddSpeed_XY(-0.05000000 * this.direction, -0.15000001);
		this.rz += 0.01745329;
		this.sx = this.sy += 0.07500000;
		this.alpha -= 0.03500000;

		if (this.alpha <= 1.00000000)
		{
			this.green = this.blue = this.alpha;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		}
	};
}

function BeginBattle_Fire( t )
{
	this.SetMotion(9000, 4);
	this.sx = this.sy = 0.20000000;
	this.rz = -15 * 0.01745329;
	this.func = [
		this.ReleaseActor
	];
	this.alpha = 1.60000002;
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(-2.00000000 * this.direction, -0.05000000);
		local s_ = (5.00000000 - this.sx) * 0.30000001;

		if (s_ < 0.02500000)
		{
			s_ = 0.02500000;
		}

		this.sx = this.sy += s_;
		this.alpha -= 0.15000001;

		if (this.alpha <= 1.00000000)
		{
			this.green = this.blue = this.alpha;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		}
	};
}

function BeginBattle_FireRing( t )
{
	this.SetMotion(9000, 3);
	this.DrawActorPriority(180);
	this.sx = this.sy = 0.20000000;
	this.rx = -70 * 0.01745329;
	this.ry = 40 * 0.01745329 * this.direction;
	this.func = [
		this.ReleaseActor
	];
	this.alpha = 1.60000002;
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, -0.05000000);
		this.anime.radius0 += (this.anime.radius1 - this.anime.radius0) * 0.10000000;
		this.rz -= 12.00000000 * 0.01745329;
		local s_ = (3.00000000 - this.sx) * 0.40000001;

		if (s_ < 0.02500000)
		{
			s_ = 0.02500000;
		}

		this.sx = this.sy += s_;
		this.alpha -= 0.05000000;

		if (this.alpha <= 1.00000000)
		{
			this.green = this.blue = this.alpha;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		}
	};
}

function BeginBattle( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.count = 0;
	this.SetMotion(9000, 0);
	this.demoObject = [];
	this.keyAction = [
		null,
		function ()
		{
			this.PlaySE(3292);
			::camera.Shake(5.00000000);
			local t_ = {};
			this.demoObject.append(this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.BeginBattle_Fire, t_).weakref());
			this.demoObject.append(this.SetFreeObjectDynamic(this.point0_x, this.point0_y, this.direction, this.BeginBattle_FireRing, t_).weakref());
			this.demoObject.append(this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.BeginBattle_FirePart, t_).weakref());
			this.demoObject.append(this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.BeginBattle_FirePart, t_).weakref());
			this.demoObject.append(this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.BeginBattle_FirePart, t_).weakref());
			this.stateLabel = function ()
			{
			};
		},
		function ()
		{
			this.CommonBegin();
			this.EndtoFreeMove();
		}
	];
	this.stateLabel = function ()
	{
	};
}

function BeginBattle_Mamizou( t )
{
	this.LabelClear();
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.freeMap = true;
	this.SetMotion(9001, 0);
	this.team.slave.BeginBattle_Slave(null);
	this.freeMap = true;
	this.Warp(640 - 960 * this.direction, this.y);
	this.flag1 = this.Vector3();
	this.flag1.x = ::battle.start_x[this.team.index];
	this.flag1.y = ::battle.start_y[this.team.index];
	this.func = function ()
	{
		this.SetEffect(this.x, this.y, this.direction, this.EF_DebuffAnimal, {});
		this.SetMotion(9001, 1);
		this.centerStop = -3;
		this.SetSpeed_XY(0.00000000, -6.00000000);
		this.Warp(this.flag1.x, this.y);
		this.stateLabel = function ()
		{
			this.CenterUpdate(0.50000000, null);

			if (this.centerStop * this.centerStop <= 1)
			{
				this.SetMotion(9001, 3);
				this.Warp(this.flag1.x, this.y);
				this.SetSpeed_XY(0.00000000, this.va.y);
				this.count = 0;
				this.stateLabel = function ()
				{
					if (this.count == 120)
					{
						this.SetMotion(9001, 5);
						this.keyAction = function ()
						{
							this.CommonBegin();
						};
						this.stateLabel = function ()
						{
						};
					}
				};
			}
		};
	};
	this.stateLabel = function ()
	{
	};
}

function BeginBattle_Slave( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.freeMap = true;
	this.SetMotion(9001, 0);
	this.func = function ()
	{
		this.SetMotion(3910, 2);
	};
}

function WinA( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();

	if (this.occultCount)
	{
		this.SetMotion(9012, 0);
	}
	else
	{
		this.SetMotion(9010, 0);
	}

	this.keyAction = [
		function ()
		{
			this.PlaySE(3293);
		},
		function ()
		{
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count == 120)
				{
					this.CommonWin();
				}
			};
		}
	];
}

function WinB( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();

	if (this.occultCount)
	{
		this.SetMotion(9013, 0);
	}
	else
	{
		this.SetMotion(9011, 0);
	}

	this.count = 0;
	this.keyAction = [
		function ()
		{
			this.PlaySE(3294);
			this.SetSpeed_XY(0.00000000, -50.00000000);
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count == 60)
				{
					this.CommonWin();
					this.SetSpeed_XY(0.00000000, 0.00000000);
				}
			};
		}
	];
}

function Lose( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.SetMotion(9020, 0);
	this.stateLabel = function ()
	{
		if (this.keyTake == 0)
		{
			this.count = 0;
		}
		else if (this.count == 60)
		{
			this.CommonLose();
		}
	};
}

function Stand_Init( t )
{
	this.LabelClear();
	this.stateLabel = this.Stand;
	this.SetMotion(0, 0);
}

function MoveFront_Init( t )
{
	this.LabelClear();
	this.stateLabel = this.MoveFront;
	this.SetMotion(1, 0);
	this.SetSpeed_XY(6.50000000 * this.direction, this.va.y);
}

function MoveBack_Init( t )
{
	this.LabelClear();
	this.stateLabel = this.MoveBack;
	this.SetMotion(2, 0);
	this.SetSpeed_XY(-5.50000000 * this.direction, this.va.y);
}

function Guard_Stance( t )
{
	local t_ = {};
	t_.v <- 17.50000000;
	this.Guard_Stance_Common(t_);
}

function SlideUp_Init( t )
{
	local t_ = {};
	t_.dash <- 9.00000000;
	t_.front <- 6.00000000;
	t_.back <- -6.00000000;
	t_.front_rev <- 4.50000000;
	t_.back_rev <- -4.50000000;
	t_.v <- -17.50000000;
	t_.v2 <- -8.00000000;
	t_.v3 <- 17.50000000;
	this.SlideUp_Common(t_);
}

function C_SlideUp_Init( t )
{
	local t_ = {};
	t_.dash <- 9.00000000;
	t_.front <- 6.00000000;
	t_.back <- -6.00000000;
	t_.front_rev <- 4.50000000;
	t_.back_rev <- -4.50000000;
	t_.v <- -17.50000000;
	t_.v2 <- -8.00000000;
	t_.v3 <- 17.50000000;
	this.C_SlideUp_Common(t_);
}

function SlideFall_Init( t )
{
	local t_ = {};
	t_.dash <- 9.00000000;
	t_.front <- 6.00000000;
	t_.back <- -6.00000000;
	t_.front_rev <- 4.50000000;
	t_.back_rev <- -4.50000000;
	t_.v <- 17.50000000;
	t_.v2 <- 8.00000000;
	t_.v3 <- 17.50000000;
	this.SlideFall_Common(t_);
}

function C_SlideFall_Init( t )
{
	local t_ = {};
	t_.dash <- 9.00000000;
	t_.front <- 6.00000000;
	t_.back <- -6.00000000;
	t_.front_rev <- 4.50000000;
	t_.back_rev <- -4.50000000;
	t_.v <- 17.50000000;
	t_.v2 <- 8.00000000;
	t_.v3 <- 17.50000000;
	this.C_SlideFall_Common(t_);
}

function Team_Change_AirMoveB( t_ )
{
	this.Team_Change_AirMoveCommon(null);
	this.flag5.vx = 8.00000000;
	this.flag5.vy = 7.50000000;
	this.flag5.g = this.baseGravity;
}

function Team_Change_AirBackB( t_ )
{
	this.Team_Change_AirBackCommon(null);
	this.flag5.vx = -8.00000000;
	this.flag5.vy = 7.50000000;
	this.flag5.g = this.baseGravity;
}

function Team_Change_AirSlideUpperB( t_ )
{
	this.Team_Change_AirSlideUpperCommon(null);
	this.flag5.vx = 0.00000000;
	this.flag5.vy = -8.00000000;
	this.flag5.g = this.baseGravity;
}

function Team_Change_AirSlideUnderB( t_ )
{
	this.Team_Change_AirSlideUnderCommon(null);
	this.flag5.vx = 0.00000000;
	this.flag5.vy = 8.00000000;
	this.flag5.g = this.baseGravity;
}

function GC_SlideUp_Init( t )
{
	local t_ = {};
	t_.dash <- 2.00000000;
	t_.front <- 2.00000000;
	t_.back <- -2.00000000;
	t_.front_rev <- 2.00000000;
	t_.back_rev <- -2.00000000;
	this.GC_SlideUp_Common(t_);
}

function GC_SlideFall_Init( t )
{
	local t_ = {};
	t_.dash <- 2.00000000;
	t_.front <- 2.00000000;
	t_.back <- -2.00000000;
	t_.front_rev <- 2.00000000;
	t_.back_rev <- -2.00000000;
	this.GC_SlideFall_Common(t_);
}

function DashFront_Init( t )
{
	local t_ = {};
	t_.speed <- 8.00000000;
	t_.addSpeed <- 0.40000001;
	t_.maxSpeed <- 15.50000000;
	t_.wait <- 120;
	this.DashFront_Common(t_);
}

function DashFront_Air_Init( t )
{
	local t_ = {};
	t_.speed <- 9.00000000;
	t_.g <- 0.10000000;
	t_.minWait <- 12;
	t_.wait <- 60;
	t_.addSpeed <- 0.12500000;
	t_.maxSpeed <- 14.00000000;
	this.DashFront_Air_Common(t_);
}

function DashBack_Init( t )
{
	this.LabelClear();
	this.SetMotion(41, 0);
	this.PlaySE(801);
	this.SetSpeed_XY(-10.00000000 * this.direction, -5.00000000);
	this.centerStop = -3;
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, 0.50000000);

		if (this.y > this.centerY && this.va.y > 0.00000000)
		{
			this.SetMotion(41, 3);
			this.centerStop = 1;
			this.SetSpeed_XY(null, 2.50000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	};
}

function DashBack_Air_Init( t )
{
	local t_ = {};
	t_.speed <- -9.00000000;
	t_.g <- 0.10000000;
	t_.minWait <- 12;
	t_.wait <- 30;
	t_.addSpeed <- 0.10000000;
	t_.maxSpeed <- 14.00000000;
	this.DashBack_Air_Common(t_);
}

function Flight_Assult_Init( t )
{
	this.Flight_Assult_Common(t);
	this.flag2 = 14.50000000;
	this.flag4 = 0.26179937;
}

function Atk_RushA_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1;
	this.SetMotion(1500, 0);
	this.keyAction = [
		function ()
		{
			this.PlaySE(3202);
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
	};
	return true;
}

function Atk_Low_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1;
	this.combo_func = this.Rush_AA;
	this.SetMotion(1000, 0);
	this.keyAction = [
		function ()
		{
			this.PlaySE(3200);
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
	};
	return true;
}

function Atk_Low()
{
	if (this.centerStop == 0)
	{
		this.VX_Brake(0.50000000);
	}
	else
	{
		this.VX_Brake(0.10000000);
	}
}

function Atk_RushB_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 4;

	if (this.occultCount)
	{
		this.SetMotion(1601, 0);
	}
	else
	{
		this.SetMotion(1600, 0);
	}

	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(10.00000000 * this.direction, null);
			this.PlaySE(3206);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
	};
	return true;
}

function Atk_Mid_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 2;
	this.combo_func = this.Rush_Far;

	if (this.occultCount)
	{
		this.SetMotion(1101, 0);
	}
	else
	{
		this.SetMotion(1100, 0);
	}

	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(10.00000000 * this.direction, null);
			this.PlaySE(3204);
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(1.00000000);
	};
	return true;
}

function Atk_Mid_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 8;
	this.combo_func = this.Rush_Air;

	if (this.occultCount)
	{
		this.SetMotion(1111, 0);
	}
	else
	{
		this.SetMotion(1110, 0);
	}

	this.keyAction = [
		function ()
		{
			this.PlaySE(3208);
		},
		null,
		null,
		this.EndtoFreeMove
	];
	this.stateLabel = function ()
	{
		if (this.abs(this.centerStop) <= 1)
		{
			this.SetMotion(this.motion, 4);
			this.GetFront();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	};
	return true;
}

function Atk_RushC_Under_Init( t )
{
	this.LabelClear();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(1711, 0);
	}
	else
	{
		this.SetMotion(1710, 0);
	}

	this.atk_id = 128;
	this.stateLabel = function ()
	{
		this.VX_Brake(0.75000000);
	};
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(200);
			this.PlaySE(3212);
			this.SetSpeed_XY(15.00000000 * this.direction, 0.00000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(this.va.x * this.direction >= 1.00000000 ? 1.50000000 : 0.05000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	];
	return true;
}

function Atk_RushA_Far_Init( t )
{
	this.Atk_HighUnder_Init(t);

	if (this.occultCount)
	{
		this.SetMotion(1741, 0);
	}
	else
	{
		this.SetMotion(1740, 0);
	}

	this.atk_id = 2048;
	return true;
}

function Atk_HighUnder_Init( t )
{
	this.LabelClear();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(1212, 0);
	}
	else
	{
		this.SetMotion(1210, 0);
	}

	this.atk_id = 128;
	this.stateLabel = function ()
	{
		this.VX_Brake(0.75000000);
	};
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(200);
			this.PlaySE(3210);
			this.SetSpeed_XY(15.00000000 * this.direction, 0.00000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(this.va.x * this.direction >= 1.00000000 ? 1.50000000 : 0.05000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	];
	return true;
}

function Atk_HighUnder_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1024;

	if (this.occultCount)
	{
		this.SetMotion(1213, 0);
	}
	else
	{
		this.SetMotion(1211, 0);
	}

	this.stateLabel = function ()
	{
		if (this.abs(this.centerStop) <= 1)
		{
			this.SetMotion(this.motion, 3);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	};
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(200);
			this.PlaySE(3210);
		},
		function ()
		{
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.abs(this.centerStop) <= 1)
				{
					this.VX_Brake(0.75000000);
				}
			};
		}
	];
	return true;
}

function Atk_HighUpper_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 64;
	this.SetEndMotionCallbackFunction(this.EndtoFallLoop);

	if (this.occultCount)
	{
		this.SetMotion(1222, 0);
	}
	else
	{
		this.SetMotion(1220, 0);
	}

	this.stateLabel = function ()
	{
		this.VX_Brake(0.80000001);
	};
	this.keyAction = [
		function ()
		{
			this.PlaySE(3228);
			this.centerStop = -2;
			this.SetSpeed_XY(10.00000000 * this.direction, -10.00000000);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.50000000);
			};
		},
		function ()
		{
			this.HitTargetReset();
		},
		function ()
		{
			this.SetSelfDamage(100);
			this.PlaySE(3214);
			this.SetSpeed_XY(null, -1.00000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(this.va.x * this.direction >= 1.50000000 ? 0.50000000 : 0.02500000);
				this.AddSpeed_XY(0.00000000, 0.20000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.25000000);
			};
		},
		function ()
		{
		}
	];
	return true;
}

function Atk_HighUpper_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 512;
	this.SetEndMotionCallbackFunction(this.EndtoFallLoop);

	if (this.occultCount)
	{
		this.SetMotion(1223, 0);
	}
	else
	{
		this.SetMotion(1221, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.25000000);
	this.flag3 = 5.00000000;
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);

		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(this.motion, 4);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	};
	this.keyAction = [
		function ()
		{
			if (this.centerStop * this.centerStop >= 4 && this.y > this.centerY)
			{
				this.centerStop = -2;
				this.SetSpeed_XY(this.flag3 * this.direction, -10.00000000);
			}
			else
			{
				this.centerStop = -2;
				this.SetSpeed_XY(this.flag3 * this.direction, -6.00000000);
			}

			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.50000000);

				if (this.va.y >= 6.00000000 && this.y > this.centerY)
				{
					this.SetMotion(this.motion, 4);
					this.stateLabel = function ()
					{
						if (this.centerStop * this.centerStop <= 1)
						{
							this.VX_Brake(0.50000000);
						}
					};
				}
			};
		},
		function ()
		{
			this.SetSelfDamage(100);
			this.PlaySE(3214);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.50000000);

				if (this.va.y >= 6.00000000 && this.y > this.centerY)
				{
					this.SetMotion(this.motion, 4);
					this.stateLabel = function ()
					{
						if (this.centerStop * this.centerStop <= 1)
						{
							this.VX_Brake(0.50000000);
						}
					};
				}
			};
		},
		function ()
		{
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.50000000);
				}
			};
		}
	];
	return true;
}

function Atk_HighUpperB_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 512;

	if (this.occultCount)
	{
		this.SetMotion(1225, 0);
	}
	else
	{
		this.SetMotion(1224, 0);
	}

	this.stateLabel = function ()
	{
		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(this.motion, 3);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	};
	this.keyAction = [
		function ()
		{
		},
		function ()
		{
			this.SetSelfDamage(100);
			this.PlaySE(3214);
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.50000000);
				}
			};
		}
	];
	return true;
}

function Atk_RushC_Upper_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 64;

	if (this.occultCount)
	{
		this.SetMotion(1721, 0);
	}
	else
	{
		this.SetMotion(1720, 0);
	}

	this.SetEndMotionCallbackFunction(this.EndtoFallLoop);
	this.keyAction = [
		function ()
		{
			this.PlaySE(3228);
			this.centerStop = -2;
			this.SetSpeed_XY(10.00000000 * this.direction, -10.00000000);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.50000000);
			};
		},
		function ()
		{
			this.HitTargetReset();
		},
		function ()
		{
			this.SetSelfDamage(100);
			this.PlaySE(3217);
			this.SetSpeed_XY(null, -1.00000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(this.va.x * this.direction >= 1.50000000 ? 0.50000000 : 0.02500000);
				this.AddSpeed_XY(0.00000000, 0.20000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.25000000);
			};
		},
		function ()
		{
		}
	];
	this.stateLabel = function ()
	{
		this.Vec_Brake(0.50000000, 2.00000000);
	};
	return true;
}

function Atk_RushC_Front_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 32;

	if (this.occultCount)
	{
		this.SetMotion(1731, 0);
	}
	else
	{
		this.SetMotion(1730, 0);
	}

	this.SetSpeed_XY(20.00000000 * this.direction, 0.00000000);
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(200);
			this.SetSpeed_XY(-15.00000000 * this.direction, null);
			this.PlaySE(3222);
			this.stateLabel = function ()
			{
				this.VX_Brake(this.va.x * this.direction < -1.00000000 ? 1.00000000 : 0.02500000);
				this.CenterUpdate(0.50000000, 2.00000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(1.50000000);
	};
	return true;
}

function Atk_HighFront_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 32;

	if (this.occultCount)
	{
		this.SetMotion(1232, 0);
	}
	else
	{
		this.SetMotion(1230, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(200);
			this.SetSpeed_XY(-15.00000000 * this.direction, null);
			this.PlaySE(3220);
			this.stateLabel = function ()
			{
				this.VX_Brake(this.va.x * this.direction < -1.00000000 ? 1.00000000 : 0.02500000);
				this.CenterUpdate(0.50000000, 2.00000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.40000001);
	};
	return true;
}

function Atk_RushA_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(1751, 0);
	}
	else
	{
		this.SetMotion(1750, 0);
	}

	this.atk_id = 16;
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(200);
			this.PlaySE(3224);
			this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
			this.stateLabel = function ()
			{
				this.CenterUpdate(0.20000000, null);

				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(this.motion, 3);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.75000000);
					};
				}
			};
		},
		function ()
		{
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.75000000);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.20000000, null);

		if (this.abs(this.centerStop) <= 1)
		{
			this.LabelClear();
			this.SetMotion(this.motion - 640, 4);
			this.GetFront();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	};
	return true;
}

function Atk_HighFront_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 256;

	if (this.occultCount)
	{
		this.SetMotion(1233, 0);
	}
	else
	{
		this.SetMotion(1231, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(200);
			this.PlaySE(3224);
		},
		function ()
		{
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.75000000);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.20000000, null);

		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(this.motion, 3);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	};
	return true;
}

function Atk_LowDash_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 4096;

	if (this.occultCount)
	{
		this.SetMotion(1301, 0);
	}
	else
	{
		this.SetMotion(1300, 0);
	}

	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(15.00000000 * this.direction, 0.00000000);
			this.PlaySE(3226);
			this.stateLabel = function ()
			{
				this.VX_Brake(1.50000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.20000000);
	};
	return true;
}

function Atk_HighDash_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 8192;
	this.stateLabel = function ()
	{
		this.VX_Brake(this.va.x * this.direction > 4.00000000 ? 0.30000001 : 0.02500000);
		this.AddSpeed_XY(0.00000000, 0.34999999);

		if (this.va.y > 0 && this.y > this.centerY)
		{
			this.centerStop = 1;
			this.SetMotion(this.motion, 2);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	};

	if (this.occultCount)
	{
		this.SetMotion(1311, 0);
	}
	else
	{
		this.SetMotion(1310, 0);
	}

	this.centerStop = -2;
	this.SetSpeed_XY(12.00000000 * this.direction, -5.00000000);
	this.keyAction = [
		function ()
		{
			this.PlaySE(3224);
			this.SetSelfDamage(200);
		},
		function ()
		{
		},
		null,
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.40000001);
			};
		}
	];
	return true;
}

function Grab_Actor( t )
{
	this.target = this.initTable.pare.target.weakref();
	this.func = [
		function ()
		{
			this.ReleaseActor();
			return;
		}
	];
	this.stateLabel = function ()
	{
		this.target.Warp(this.initTable.pare.point0_x, this.initTable.pare.y);
	};
}

function Atk_Grab_Hit( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(1802, 0);
	this.PlaySE(806);
	this.target.DamageGrab_Common(300, 2, -this.direction);
	this.target.autoCamera = false;
	::battle.enableTimeUp = false;
	this.target.cameraPos.x = this.target.x;
	this.target.cameraPos.y = this.target.y;
	this.flag1 = this.SetFreeObject(this.x, this.y, this.direction, this.Grab_Actor, {}, this.weakref()).weakref();

	if (!this.target.layerSwitch)
	{
		this.layerSwitch = false;
		this.target.layerSwitch = true;
		this.target.ConnectRenderSlot(::graphics.slot.actor, 190);
	}

	this.stateLabel = function ()
	{
		if (this.Atk_Grab_Hit_Update())
		{
			this.flag1.func[0].call(this.flag1);
			this.target.autoCamera = true;
			this.Grab_Blocked(null);
			return;
		}
	};
	this.keyAction = [
		null,
		function ()
		{
			this.PlaySE(3297);
			local t_ = {};
			t_.type <- 1;

			if (this.occultCount > 0)
			{
				t_.type = 2;
			}

			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.Grab_Exp, t_);
			::camera.shake_radius = 5.00000000;
			this.flag1.func[0].call(this.flag1);
			this.SetEffect(this.target.x, this.target.y, this.direction, this.EF_HitSmashC, {});
			this.target.autoCamera = true;
			this.KnockBackTarget(-this.direction);
			this.HitReset();
			this.hitResult = 1;
			this.SetSpeed_XY(-10.00000000 * this.direction, 0.00000000);
			::battle.enableTimeUp = true;
			this.target.team.regain_life -= ((this.target.team.regain_life - this.target.team.life) * 0.50000000).tointeger();
			local t_ = {};
			t_.num <- 10;
			this.target.SetFreeObject(this.target.x, this.target.y, 1.00000000, this.target.Occult_PowerCreatePoint, t_);
			local t_ = {};
			t_.num <- 10;
			this.target.SetFreeObject(this.target.x, this.target.y, 1.00000000, this.target.Occult_PowerCreatePoint, t_);
			local t_ = {};
			t_.num <- 10;
			this.target.SetFreeObject(this.target.x, this.target.y, 1.00000000, this.target.Occult_PowerCreatePoint, t_);
			local t_ = {};
			t_.num <- 10;
			this.target.SetFreeObject(this.target.x, this.target.y, 1.00000000, this.target.Occult_PowerCreatePoint, t_);
			local t_ = {};
			t_.num <- 10;
			this.target.SetFreeObject(this.target.x, this.target.y, 1.00000000, this.target.Occult_PowerCreatePoint, t_);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	];
}

function Shot_Normal_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2004, 0);
	}
	else
	{
		this.SetMotion(2000, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, null);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3230);
			local v_ = 8.00000000;

			if (this.occultCount == 0)
			{
				for( local i = 4; i >= -2; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Normal, t);
				}
			}
			else
			{
				for( local i = 4; i >= -2; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_NormalB, t);
				}
			}

			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.20000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.75000000);
	};
	return true;
}

function Shot_Normal_Air_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2005, 0);
	}
	else
	{
		this.SetMotion(2001, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.40000001, this.va.y * 0.25000000);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3230);
			local v_ = 8.00000000;

			if (this.y <= this.centerY)
			{
				this.flag1 = -1;
			}
			else
			{
				this.flag1 = 1;
			}

			this.centerStop = 3 * this.flag1;
			this.SetSpeed_XY(-7.00000000 * this.direction, 3.00000000 * this.flag1);

			if (this.occultCount == 0)
			{
				for( local i = 5; i >= -1; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Normal, t);
				}
			}
			else
			{
				for( local i = 5; i >= -1; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_NormalB, t);
				}
			}

			this.stateLabel = function ()
			{
				this.CenterUpdate(0.25000000, null);
				this.VX_Brake(0.05000000);

				if (this.centerStop * this.centerStop == 0)
				{
					this.stateLabel = function ()
					{
						this.VX_Brake(0.75000000);
					};
				}
			};
		},
		function ()
		{
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.05000000);

				if (this.centerStop * this.centerStop == 0)
				{
					this.stateLabel = function ()
					{
						this.VX_Brake(0.75000000);
					};
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);
		this.VX_Brake(0.05000000);

		if (this.centerStop * this.centerStop == 0)
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	};
	return true;
}

function Shot_Normal_Under_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2004, 0);
	}
	else
	{
		this.SetMotion(2000, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, null);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3230);
			local v_ = 8.00000000;

			if (this.occultCount == 0)
			{
				for( local i = 5; i >= -1; i-- )
				{
					local t = {};
					t.rot <- (35 + i * 5) * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Normal, t);
				}
			}
			else
			{
				for( local i = 5; i >= -1; i-- )
				{
					local t = {};
					t.rot <- (35 + i * 5) * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_NormalB, t);
				}
			}
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.20000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.75000000);
	};
	return true;
}

function Shot_Normal_Under_Air_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2005, 0);
	}
	else
	{
		this.SetMotion(2001, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.25000000);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3230);
			local v_ = 8.00000000;

			if (this.y <= this.centerY)
			{
				this.flag1 = -1;
			}
			else
			{
				this.flag1 = 1;
			}

			this.centerStop = 3 * this.flag1;
			this.SetSpeed_XY(-7.00000000 * this.direction, 3.00000000 * this.flag1);

			if (this.occultCount == 0)
			{
				for( local i = 5; i >= -1; i-- )
				{
					local t = {};
					t.rot <- (35 + i * 5) * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Normal, t);
				}
			}
			else
			{
				for( local i = 5; i >= -1; i-- )
				{
					local t = {};
					t.rot <- (35 + i * 5) * 0.01745329;
					t.v <- v_;
					v_ = v_ + 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_NormalB, t);
				}
			}

			this.stateLabel = function ()
			{
				this.CenterUpdate(0.25000000, null);
				this.VX_Brake(0.05000000);

				if (this.centerStop * this.centerStop == 0)
				{
					this.stateLabel = function ()
					{
						this.VX_Brake(0.75000000);
					};
				}
			};
		},
		function ()
		{
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.05000000);

				if (this.centerStop * this.centerStop == 0)
				{
					this.stateLabel = function ()
					{
						this.VX_Brake(0.75000000);
					};
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);
		this.VX_Brake(0.05000000);

		if (this.centerStop * this.centerStop == 0)
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	};
	return true;
}

function Shot_Normal_Upper_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2004, 0);
	}
	else
	{
		this.SetMotion(2000, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, null);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3230);
			local v_ = 11.00000000;

			if (this.occultCount == 0)
			{
				for( local i = -5; i >= -11; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ - 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Normal, t);
				}
			}
			else
			{
				for( local i = -5; i >= -11; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ - 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_NormalB, t);
				}
			}
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.20000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.75000000);
	};
	return true;
}

function Shot_Normal_Upper_Air_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2005, 0);
	}
	else
	{
		this.SetMotion(2001, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.25000000);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3230);
			local v_ = 11.00000000;

			if (this.y <= this.centerY)
			{
				this.flag1 = -1;
			}
			else
			{
				this.flag1 = 1;
			}

			this.centerStop = 3 * this.flag1;
			this.SetSpeed_XY(-7.00000000 * this.direction, 3.00000000 * this.flag1);

			if (this.occultCount == 0)
			{
				for( local i = -5; i >= -11; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ - 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Normal, t);
				}
			}
			else
			{
				for( local i = -5; i >= -11; i-- )
				{
					local t = {};
					t.rot <- i * 5 * 0.01745329;
					t.v <- v_;
					v_ = v_ - 0.80000001;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_NormalB, t);
				}
			}

			this.stateLabel = function ()
			{
				this.CenterUpdate(0.25000000, null);
				this.VX_Brake(0.05000000);

				if (this.centerStop * this.centerStop == 0)
				{
					this.stateLabel = function ()
					{
						this.VX_Brake(0.75000000);
					};
				}
			};
		},
		function ()
		{
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.05000000);

				if (this.centerStop * this.centerStop == 0)
				{
					this.stateLabel = function ()
					{
						this.VX_Brake(0.75000000);
					};
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);
		this.VX_Brake(0.05000000);

		if (this.centerStop * this.centerStop == 0)
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	};
	return true;
}

function Shot_Front_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2012, 0);
	}
	else
	{
		this.SetMotion(2010, 0);
	}

	this.count = 0;
	this.flag1 = 4;
	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.25000000);
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(100);
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3232);
			local t_ = {};
			t_.charge <- this.occultCount > 0;
			this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Front, t_);
			this.SetSpeed_XY(-8.00000000 * this.direction, null);
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
	};
	return true;
}

function Shot_Front_Air_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();

	if (this.occultCount)
	{
		this.SetMotion(2013, 0);
	}
	else
	{
		this.SetMotion(2011, 0);
	}

	this.count = 0;
	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.25000000);
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(100);
			this.team.AddMP(-200, 90);
			this.hitResult = 1;
			this.PlaySE(3232);
			local t_ = {};
			t_.charge <- this.occultCount > 0;
			this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Front, t_);
			this.SetSpeed_XY(-8.00000000 * this.direction, 0.00000000);
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				this.CenterUpdate(0.10000000, null);

				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.50000000);
				}
				else
				{
					this.VX_Brake(this.va.x * this.direction < -2.50000000 ? 0.40000001 : 0.02500000);
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.50000000);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);

		if (this.centerStop * this.centerStop <= 1)
		{
			this.VX_Brake(0.50000000);
		}
	};
	return true;
}

function Shot_Charge_Init( t )
{
	this.Shot_Charge_Common(t);
	this.flag2.vx <- 6.50000000;
	this.flag2.vy <- 4.00000000;
	this.flag2.rot <- 0.00000000;
	this.subState = function ()
	{
	};
	return true;
}

function Shot_Charge_Fire( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.count = 0;
	this.SetMotion(2020, 0);
	this.flag1 = null;
	this.flag2 = t.ky;
	this.flag3 = 0;
	this.flag4 = t.charge;
	this.flag5 = null;
	this.keyAction = [
		function ()
		{
			this.count = 0;
			local t_ = {};
			t_.k <- this.flag2;
			t_.charge <- false;
			t_.occult <- this.occultCount;
			this.flag5 = this.SetShot(this.x + 20 * this.direction, this.y - 110, this.direction, this.Shot_Charge, t_).weakref();
			this.flag5.SetParent(this, this.flag5.x - this.x, this.flag5.y - this.y);
			this.lavelClearEvent = function ()
			{
				if (this.flag5)
				{
					this.flag5.func[2].call(this.flag5);
				}
			};
		},
		function ()
		{
			this.PlaySE(3236);

			if (this.flag5)
			{
				this.flag5.func[1].call(this.flag5);
				this.flag5.SetParent(null, 0, 0);
			}

			this.lavelClearEvent = null;
			this.SetSpeed_XY(-12.50000000 * this.direction, 0.00000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.69999999);
				this.CenterUpdate(0.10000000, null);
			};
		},
		function ()
		{
			this.stateLabel = null;
		}
	];
	this.stateLabel = function ()
	{
		this.Vec_Brake(0.50000000);
	};
	return true;
}

function Shot_Charge_Air_Init( t )
{
	this.Shot_Charge_Init(t);
	return true;
}

function Shot_Burrage_Init( t )
{
	this.Shot_Burrage_Common(t);
	this.flag2.vx <- 6.50000000;
	this.flag2.vy <- 4.00000000;
	this.flag2.rot <- 0.00000000;
	this.subState = function ()
	{
		if (this.team.mp > 0)
		{
			local c_ = this.count % 45;

			if (this.occultCount)
			{
				c_ = this.count % 35;
			}

			if (c_ == 10)
			{
				this.flag2.rot = this.atan2(this.target.y - this.y, (this.target.x - this.x) * this.direction);
			}

			if (this.count % 4 == 0 && c_ <= 30 && c_ >= 10)
			{
				this.PlaySE(3304);
				local t_ = {};
				t_.v <- 10.00000000 + this.rand() % 6;
				t_.rot <- this.flag2.rot + (10 - this.rand() % 21) * 0.01745329;
				t_.type <- this.occultCount > 0;
				this.SetShot(this.x + 75 * this.cos(t_.rot) * this.direction, this.y - 20 + 75 * this.sin(t_.rot), this.direction, this.Shot_Barrage, t_).weakref();
			}
		}
	};
	return true;
}

function Occult_FireStart()
{
	for( local i = 0; i < 360; i = i + (20 + this.rand() % 25) )
	{
		local t_ = {};
		t_.rot <- i * 0.01745329;
		this.SetFreeObject(this.x, this.y, this.direction, this.owner.Occult_FireStartB, t_);
	}

	this.PlaySE(3240);
}

function Occult_FireStartB( t )
{
	this.SetMotion(2508, this.rand() % 4);
	this.sx = this.sy = 1.25000000 + this.rand() % 20 * 0.10000000;
	this.rz = this.rand() % 360 * 0.01745329;
	this.SetSpeed_Vec(10.00000000 + this.rand() % 60 * 0.10000000, t.rot, this.direction);
	this.flag2 = (-15 + this.rand() % 31) * 0.01745329;
	this.stateLabel = function ()
	{
		this.sx = this.sy *= 0.97000003;
		this.flag1 -= 0.02500000;
		this.rz += this.flag2;
		this.flag2 *= 0.94000000;
		this.SetSpeed_XY(this.va.x * 0.92000002, this.va.y * 0.92000002 + this.flag1);
		this.alpha = this.green = this.red -= 0.02500000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Occult_BurnBall( t )
{
	this.SetMotion(2509, 2);
	this.DrawActorPriority(188);
	this.SetParent(this.owner, this.x - this.owner.x, this.y - this.owner.y);
	this.stateLabel = function ()
	{
		this.sx = this.sy += 0.10000000;
		this.alpha = this.green = this.red -= 0.06000000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Occult_BurnPilar( t )
{
	this.SetMotion(2509, this.rand() % 2);
	this.rz = this.rand() % 360 * 0.01745329;
	this.DrawActorPriority(191);
	this.SetParent(this.owner, this.x - this.owner.x, this.y - this.owner.y);
	this.sx = this.sy = 0.10000000;
	this.flag1 = this.Vector3();
	this.flag1.x = 0.75000000 + this.rand() % 51 * 0.01000000;
	this.flag1.y = 0.50000000 + this.rand() % 51 * 0.01000000;
	this.flag3 = 0.05000000 - this.rand() % 5 * 0.00500000;
	this.SetFreeObject(this.x, this.y, this.direction, this.owner.Occult_BurnBall, {});
	this.stateLabel = function ()
	{
		this.count++;
		this.sx = this.Math_Bezier(0.10000000, this.flag1.x, this.flag1.x - 0.20000000, this.flag2);
		this.sy = this.Math_Bezier(0.10000000, this.flag1.y, this.flag1.y - 0.20000000, this.flag2);
		this.flag2 += this.flag3;

		if (this.count >= 10)
		{
			this.alpha = this.green = this.red -= this.flag3 * 2.00000000;
		}

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Okult_Init( t )
{
	if (this.occultCount == 0)
	{
		this.team.enable_regain = false;
		this.occultCount = 1;
		this.occult_level = 0;
		this.atkRate = 1.04999995;
		this.occult_cycle = 40;
		this.Occult_FireStart();
	}
	else
	{
		this.occultCount = 0;
		this.occult_level = 0;
	}

	this.team.AddMP(-200, 120);
	this.PlaySE(3240);
	this.SetSelfDamage(200);
	this.Occult_FireStart();
	return true;
}

function OkultB_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(2501, 0);
	this.flag2 = 0;
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.keyAction = [
		function ()
		{
			this.team.op_stop = 300;
			this.team.op_stop_max = 300;
			this.PlaySE(3242);
			this.occultCount = 0;
			this.atkRate = 1.00000000;
			this.occult_level = 0;
			this.team.enable_regain = true;

			for( local i = 0; i < 360; i = i + (20 + this.rand() % 25) )
			{
				local t_ = {};
				t_.rot <- i * 0.01745329;
				this.SetFreeObject(this.x, this.y, this.direction, this.owner.Occult_FireStartB, t_);
			}
		}
	];
	this.stateLabel = function ()
	{
	};
	return true;
}

function SP_A_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1048576;
	this.count = 0;
	this.flag1 = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.SetMotion(3000, 0);
	this.stateLabel = function ()
	{
	};
	this.keyAction = [
		function ()
		{
			this.SP_A_Fall(null);
		}
	];
	return true;
}

function SP_A_Fall( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1048576;
	this.count = 0;
	this.flag1 = 0;
	this.team.AddMP(-200, 120);

	if (this.occultCount)
	{
		this.SetMotion(3001, 1);
	}
	else
	{
		this.SetMotion(3000, 1);
	}

	this.centerStop = 2;
	this.PlaySE(3250);
	this.SetSpeed_XY(12.50000000 * this.direction, 12.50000000);
	this.SetSelfDamage(200);
	this.hitCount = 0;
	local l_ = this.team.regain_life - this.team.life;

	if (l_ >= 2000)
	{
		this.SetMotion(this.motion, 5);
	}
	else if (l_ >= 1000)
	{
		this.SetMotion(this.motion, 3);
	}

	this.stateLabel = function ()
	{
		this.SetSelfDamage(10);

		if (this.hitCount < 10)
		{
			this.HitCycleUpdate(5);
		}

		local t_ = {};
		t_.occult <- this.occultCount;
		this.SetFreeObject(this.x + (48 - 40 + this.rand() % 80) * this.direction, this.y + 25 - 40 + this.rand() % 80, this.direction, this.SPShot_A2, t_);

		if (this.y > this.centerY + 150 && this.count >= 13 || this.y > this.centerY + 50 && this.hitCount >= 4 || this.ground)
		{
			if (this.ground)
			{
				this.SetSpeed_XY(null, 0.00000000);
			}

			this.SP_A_KickEnd();
		}
	};
}

function SP_A_KickEnd()
{
	this.LabelClear();
	this.count = 0;
	this.flag1 = 0;

	if (this.hitResult & 13)
	{
		if (this.motion == 3001)
		{
			this.SetMotion(3004, 0);
		}
		else
		{
			this.SetMotion(3003, 0);
		}

		this.HitTargetReset();
	}
	else
	{
		this.SetMotion(3002, 0);
	}

	local pos_ = this.Vector3();
	this.GetPoint(0, pos_);
	this.SetFreeObject(pos_.x, pos_.y, this.direction, this.SPShot_A, {});
	this.SetSpeed_XY(6.00000000 * this.direction, 6.00000000);
	this.centerStop = 2;
	this.stateLabel = function ()
	{
		this.Vec_Brake(0.50000000);
	};
	this.keyAction = [
		function ()
		{
			this.stateLabel = function ()
			{
			};
		}
	];
}

function SP_A_Jump( t )
{
	this.SetMotion(3003, 0);
	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(5.00000000 * this.direction, -14.00000000);
			this.centerStop = -2;
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.25000000);
			};
		},
		function ()
		{
			this.SP_A_Fall(null);
		}
	];
}

function SP_A_Guard( t )
{
	this.LabelClear();
	this.HitReset();
	this.ResetSpeed();
	this.SetMotion(3000, 3);
	local pos_ = this.Vector3();
	this.GetPoint(0, pos_);
	this.SetFreeObject(pos_.x, pos_.y, this.direction, this.SPShot_A, {});
	this.SetSpeed_XY(-10.00000000 * this.direction, -10.00000000);
	this.centerStop = -2;
	this.count = 0;
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, 0.50000000);
		this.VX_Brake(0.30000001);
	};
	this.keyAction = function ()
	{
		this.EndtoFreeMove();
	};
	return;
}

function SP_A_Hit()
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1048576;
	this.ResetSpeed();
	this.SetMotion(3002, 0);
	local pos_ = this.Vector3();
	this.GetPoint(0, pos_);
	this.SetFreeObject(pos_.x, pos_.y, this.direction, this.SPShot_A, {});
	this.stateLabel = function ()
	{
	};
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(400);
			this.PlaySE(3252);
			this.SetSpeed_XY(-5.00000000 * this.direction, -10.00000000);
			this.centerStop = -2;
			this.count = 0;
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.30000001);

				if (this.count >= 40)
				{
					this.EndtoFreeMove();
					return;
				}
			};
		}
	];
}

function SP_B_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.atk_id = 2097152;
	this.SetMotion(3010, 0);
	this.count = 0;
	this.flag2 = 0;
	this.flag3 = this.array(8);
	this.flag4 = [];
	this.flag3[0] = this.Vector3();
	this.flag3[0].x = 10.00000000 - 3.00000000;
	this.flag3[0].y = -2.00000000;
	this.flag3[1] = this.Vector3();
	this.flag3[1].x = 7.00000000 - 3.00000000;
	this.flag3[1].y = -10.50000000;
	this.flag3[2] = this.Vector3();
	this.flag3[2].x = 8.00000000 - 3.00000000;
	this.flag3[2].y = -4.00000000;
	this.flag3[3] = this.Vector3();
	this.flag3[3].x = 6.00000000 - 3.00000000;
	this.flag3[3].y = -1;
	this.flag3[4] = this.Vector3();
	this.flag3[4].x = 4.00000000 - 3.00000000;
	this.flag3[4].y = -9;
	this.team.AddMP(-200, 120);
	this.PlaySE(3254);
	this.centerStop = -2;
	this.SetSpeed_XY(-25.50000000 * this.direction, -10.00000000);
	this.count = 0;
	this.stateLabel = function ()
	{
		this.VX_Brake(this.va.x * this.direction < -5 ? 1.00000000 : 0.00000000);
		this.AddSpeed_XY(0.00000000, 0.75000000);

		if (this.count % 1 == 0 && this.flag2 < 5)
		{
			local t_ = {};
			t_.v <- this.flag3[this.flag2].weakref();
			t_.count <- 0;
			t_.occult <- this.occultCount;
			this.flag4.append(this.SetShot(this.x, this.y, this.direction, this.SPShot_B, t_).weakref());
			this.flag2++;
		}

		if (this.va.y > 0.00000000)
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(this.va.x * this.direction < -5 ? 1.00000000 : 0.00000000);
				this.AddSpeed_XY(0.00000000, 0.34999999);
			};
		}
	};
	this.keyAction = [
		null,
		function ()
		{
			this.PlaySE(3255);
			local x_ = 0;
			local i_ = 0;

			foreach( a in this.flag4 )
			{
				if (a && a.func[0])
				{
					i_++;
					x_ = x_ + a.x;
					a.func[0].call(a);
				}
			}

			if (i_ > 0)
			{
				x_ = x_ / i_;
				local t_ = {};
				t_.occult <- this.occultCount;
				this.SetShot(x_, this.y, this.direction, this.SPShot_B2, t_);
			}

			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	];
	return true;
}

function SP_B_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.atk_id = 2097152;
	this.SetMotion(3011, 0);
	this.count = 0;
	this.AjustCenterStop();
	this.flag2 = 0;
	this.flag3 = this.array(8);
	this.flag4 = [];
	this.flag3[0] = this.Vector3();
	this.flag3[0].x = 10.00000000 - 3.00000000;
	this.flag3[0].y = -2.00000000;
	this.flag3[1] = this.Vector3();
	this.flag3[1].x = 7.00000000 - 3.00000000;
	this.flag3[1].y = -10.50000000;
	this.flag3[2] = this.Vector3();
	this.flag3[2].x = 8.00000000 - 3.00000000;
	this.flag3[2].y = -4.00000000;
	this.flag3[3] = this.Vector3();
	this.flag3[3].x = 6.00000000 - 3.00000000;
	this.flag3[3].y = -1;
	this.flag3[4] = this.Vector3();
	this.flag3[4].x = 4.00000000 - 3.00000000;
	this.flag3[4].y = -9;
	this.team.AddMP(-200, 120);
	this.PlaySE(3254);

	if (this.centerStop <= -2)
	{
		this.centerStop = -2;
		this.SetSpeed_XY(-20.00000000 * this.direction, -5.00000000);
		this.count = 0;
		this.stateLabel = function ()
		{
			this.VX_Brake(this.va.x * this.direction < -5 ? 0.75000000 : 0.00000000);
			this.CenterUpdate(0.50000000, null);

			if (this.count % 1 == 0 && this.flag2 < 5)
			{
				local t_ = {};
				t_.v <- this.flag3[this.flag2].weakref();
				t_.count <- 0;
				t_.occult <- this.occultCount;
				this.flag4.append(this.SetShot(this.x, this.y, this.direction, this.SPShot_B, t_).weakref());
				this.flag2++;
			}

			if (this.centerStop * this.centerStop <= 1)
			{
				this.stateLabel = function ()
				{
					this.VX_Brake(0.75000000);
				};
			}
		};
	}
	else
	{
		this.centerStop = -2;
		this.SetSpeed_XY(-20.00000000 * this.direction, -10.00000000);
		this.count = 0;
		this.stateLabel = function ()
		{
			this.VX_Brake(this.va.x * this.direction < -5 ? 0.75000000 : 0.00000000);
			this.AddSpeed_XY(0.00000000, 0.50000000);

			if (this.count % 1 == 0 && this.flag2 < 5)
			{
				local t_ = {};
				t_.v <- this.flag3[this.flag2].weakref();
				t_.count <- 0;
				t_.occult <- this.occultCount;
				this.flag4.append(this.SetShot(this.x, this.y, this.direction, this.SPShot_B, t_).weakref());
				this.flag2++;
			}

			if (this.centerStop * this.centerStop <= 1)
			{
				this.stateLabel = function ()
				{
					this.VX_Brake(0.75000000);
				};
			}
		};
	}

	this.keyAction = [
		null,
		function ()
		{
			this.PlaySE(3255);
			local x_ = 0;
			local i_ = 0;

			foreach( a in this.flag4 )
			{
				if (a && a.func[0])
				{
					i_++;
					x_ = x_ + a.x;
					a.func[0].call(a);
				}
			}

			if (i_ > 0)
			{
				x_ = x_ / i_;
				local t_ = {};
				t_.occult <- this.occultCount;
				this.SetShot(x_, this.y, this.direction, this.SPShot_B2, t_);
			}

			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		}
	];
	return true;
}

function SP_C_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 4194304;
	this.count = 0;
	this.flag5 = t.rush;

	if (this.occultCount)
	{
		this.SetMotion(3023, 0);
	}
	else
	{
		this.SetMotion(3020, 0);
	}

	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();

	if (this.centerStop * this.centerStop <= 1)
	{
		this.stateLabel = function ()
		{
			this.VX_Brake(0.50000000);
			this.CenterUpdate(0.50000000, null);
		};
	}
	else
	{
		this.stateLabel = function ()
		{
			this.VX_Brake(0.05000000);
			this.CenterUpdate(0.10000000, null);
		};
	}

	this.keyAction = [
		function ()
		{
			this.PlaySE(3257);
			this.team.AddMP(-200, 120);
			this.SetSelfDamage(200);
			this.SetSpeed_XY(20.00000000 * this.direction, 0.00000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(1.00000000);
				this.CenterUpdate(0.20000000, null);
			};
		},
		function ()
		{
			this.PlaySE(3258);
			this.hitResult = 1;
			local t_ = {};
			t_.rot <- 20 * 0.01745329;
			t_.occult <- this.occultCount;
			local a_ = this.SetShot(this.point0_x + 10 * this.direction, this.point0_y - 20, this.direction, this.SPShot_C, t_);
			local t_ = {};
			t_.rot <- 30 * 0.01745329;
			t_.occult <- this.occultCount;
			local b_ = this.SetShot(this.point0_x + 0 * this.direction, this.point0_y - 0, this.direction, this.SPShot_C, t_);
			b_.hitOwner = a_;
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SPShot_C_Fire, t_);
			local t_ = {};
			t_.rot <- 40 * 0.01745329;
			t_.occult <- this.occultCount;
			b_ = this.SetShot(this.point0_x + 10 * this.direction, this.point0_y + 20, this.direction, this.SPShot_C, t_);
			b_.hitOwner = a_;
			this.count = 0;
			this.stateLabel = function ()
			{
				this.VX_Brake(1.00000000);
				this.CenterUpdate(0.20000000, null);

				if (this.count >= 12)
				{
					if ((this.command.rsv_k2 > 0 || this.flag5 && this.command.rsv_k0 > 0) && ::battle.state == 8)
					{
						this.SP_C2_Init(null);
						return;
					}
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if ((this.command.rsv_k2 > 0 || this.flag5 && this.command.rsv_k0 > 0) && ::battle.state == 8)
				{
					this.SP_C2_Init(null);
					return;
				}

				this.VX_Brake(1.00000000);
				this.CenterUpdate(0.20000000, null);
			};
		},
		function ()
		{
		}
	];
	return true;
}

function SP_C2_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 4194304;
	this.count = 0;

	if (this.occultCount)
	{
		this.SetMotion(3024, 0);
	}
	else
	{
		this.SetMotion(3021, 0);
	}

	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
	this.AjustCenterStop();
	this.stateLabel = function ()
	{
		this.Vec_Brake(0.20000000);
	};
	this.keyAction = [
		function ()
		{
			this.hitResult = 1;
			this.SetSelfDamage(100);
			this.PlaySE(3261);
			local g_ = [];
			local t_ = {};
			t_.rot <- -40 * 0.01745329;
			t_.occult <- this.occultCount;
			local a_ = this.SetShot(this.point0_x - 25 * this.direction, this.point0_y - 20, this.direction, this.SPShot_C2, t_);
			local t_ = {};
			t_.rot <- -30 * 0.01745329;
			t_.occult <- this.occultCount;
			local b_ = this.SetShot(this.point0_x + 0 * this.direction, this.point0_y + 0, this.direction, this.SPShot_C2, t_);
			b_.hitOwner = a_;
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SPShot_C_Fire, t_);
			local t_ = {};
			t_.rot <- -20 * 0.01745329;
			t_.occult <- this.occultCount;
			b_ = this.SetShot(this.point0_x + 25 * this.direction, this.point0_y + 20, this.direction, this.SPShot_C2, t_);
			b_.hitOwner = a_;
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);

				if ((this.command.rsv_k2 > 0 || this.flag5 && this.command.rsv_k0 > 0) && ::battle.state == 8)
				{
					this.SP_C3_Init(null);
					return;
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if ((this.command.rsv_k2 > 0 || this.flag5 && this.command.rsv_k0 > 0) && ::battle.state == 8)
				{
					this.SP_C3_Init(null);
					return;
				}

				this.VX_Brake(0.50000000);
			};
		}
	];
	return true;
}

function SP_C3_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 4194304;
	this.count = 0;

	if (this.occultCount)
	{
		this.SetMotion(3025, 0);
	}
	else
	{
		this.SetMotion(3022, 0);
	}

	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.keyAction = [
		function ()
		{
			this.centerStop = -2;
			this.SetSpeed_XY(7.50000000 * this.direction, -17.50000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.20000000);
				this.AddSpeed_XY(0.00000000, 0.85000002);
			};
		},
		function ()
		{
			this.SetSelfDamage(100);
			this.PlaySE(3263);
			this.hitResult = 1;
			local g_ = [];
			local t_ = {};
			t_.rot <- -70 * 0.01745329;
			t_.occult <- this.occultCount;
			local a_ = this.SetShot(this.point0_x - 25 * this.direction, this.point0_y + -20, this.direction, this.SPShot_C3, t_);
			local t_ = {};
			t_.rot <- -60 * 0.01745329;
			t_.occult <- this.occultCount;
			local b_ = this.SetShot(this.point0_x + 0 * this.direction, this.point0_y + 0, this.direction, this.SPShot_C3, t_);
			b_.hitOwner = a_;
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SPShot_C_Fire, t_);
			local t_ = {};
			t_.rot <- -50 * 0.01745329;
			t_.occult <- this.occultCount;
			b_ = this.SetShot(this.point0_x + 25 * this.direction, this.point0_y + 0, this.direction, this.SPShot_C3, t_);
			b_.hitOwner = a_;
		},
		function ()
		{
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count >= 12 && this.y > this.centerY)
				{
					this.centerStop = 2;
					this.EndtoFreeMove();
					return;
				}
			};
		}
	];
	this.stateLabel = function ()
	{
	};
}

function SP_D_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.hitResult = 1;
	this.atk_id = 8388608;
	this.SetMotion(3030, 0);
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(100);
			this.team.AddMP(-200, 120);
			this.PlaySE(3265);
			this.centerStop = -2;
			this.SetSpeed_XY(-10.00000000 * this.direction, -15.00000000);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.60000002);
				this.VX_Brake(0.20000000);
			};
			local t_ = {};
			t_.occult <- this.occultCount;
			this.SetShot(this.point0_x, this.point0_y, this.direction, this.SPShot_D, t_);
			return;
		},
		function ()
		{
			this.SP_D_Flight(null);
		}
	];
	this.stateLabel = function ()
	{
	};
	return true;
}

function SP_D_Air_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.hitResult = 1;
	this.SetMotion(3031, 0);
	this.atk_id = 8388608;
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.keyAction = [
		function ()
		{
			this.SetSelfDamage(100);
			this.team.AddMP(-200, 120);
			this.PlaySE(3265);
			this.centerStop = -2;

			if (this.y < this.centerY - 150)
			{
				this.SetSpeed_XY(-8.00000000 * this.direction, -5.00000000);
			}
			else
			{
				this.SetSpeed_XY(-8.00000000 * this.direction, -15.00000000);
			}

			this.stateLabel = function ()
			{
				if (this.y < this.centerY)
				{
					this.AddSpeed_XY(0.00000000, 0.50000000);
					this.VX_Brake(0.25000000);
				}
			};
			local t_ = {};
			t_.occult <- this.occultCount;
			this.SetShot(this.point0_x, this.point0_y, this.direction, this.SPShot_D, t_);
		},
		function ()
		{
			this.SP_D_Flight(null);
		}
	];
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, 0.10000000);
	};
	return true;
}

function SPShot_D_Wing2( t )
{
	this.DrawActorPriority(180);

	if (t.occult)
	{
		this.SetMotion(3036, 0);
	}
	else
	{
		this.SetMotion(3037, 0);
	}

	this.SetParent(this.owner, 0, 0);
	this.func = [
		function ()
		{
			this.SetParent(null, 0, 0);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, -0.25000000);
				this.alpha -= 0.05000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
}

function SP_D_Flight( t )
{
	this.SetMotion(3030, 2);
	this.flag1 = ::manbow.Actor2DProcGroup();
	local t_ = {};
	t_.occult <- this.occultCount;
	this.flag2 = this.SetFreeObject(this.x, this.y, this.direction, this.SPShot_D_Wing2, t_).weakref();
	this.SetEndMotionCallbackFunction(function ()
	{
		this.EndtoFallLoop();
	});
	this.lavelClearEvent = function ()
	{
		if (this.flag2)
		{
			this.flag2.func[0].call(this.flag2);
		}
	};
	this.count = 0;
	this.subState = function ()
	{
		if (this.count % 3 == 1)
		{
			this.SetSelfDamage(5);
		}

		this.CenterUpdate(this.baseGravity, 1.50000000);

		if (this.centerStop * this.centerStop <= 1)
		{
			this.lavelClearEvent = null;

			if (this.flag2)
			{
				this.flag2.func[0].call(this.flag2);
			}

			this.SetSpeed_XY(null, 3.00000000);
			this.SetMotion(this.motion, 3);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	};
	this.stateLabel = function ()
	{
		if (this.subState())
		{
			return;
		}

		if (this.input.x == 0)
		{
			this.VX_Brake(0.50000000);
		}
		else if (this.input.x > 0)
		{
			this.AddSpeed_XY(this.va.x < 6.00000000 ? 0.50000000 : 0.00000000, 0.00000000);
		}
		else
		{
			this.AddSpeed_XY(this.va.x > -6.00000000 ? -0.50000000 : 0.00000000, 0.00000000);
		}

		if (this.input.b0 > 0)
		{
			if (this.input.y > 0)
			{
				this.Atk_HighUnder_Air_Init(null);
				this.command.ResetReserve();
				return true;
			}

			if (this.input.y < 0)
			{
				this.Atk_HighUpper_Air_Init(null);
				this.command.ResetReserve();
				return true;
			}

			if (this.input.x * this.direction > 0)
			{
				this.Atk_HighFront_Air_Init(null);
				this.command.ResetReserve();
				return true;
			}

			this.Atk_Mid_Air_Init(null);
			this.command.ResetReserve();
			return true;
		}

		if (this.input.b2 > 0)
		{
			this.SP_D_Kick(null);
			return;
		}

		if (this.count >= 120 || (this.input.b2 > 0 || ::battle.state != 8) && this.count >= 6)
		{
			this.SetMotion(this.motion, 3);
			this.lavelClearEvent = null;

			if (this.flag2)
			{
				this.flag2.func[0].call(this.flag2);
			}

			this.stateLabel = function ()
			{
				if (this.centerStop == 0)
				{
					this.VX_Brake(0.50000000);
				}
			};
		}
	};
}

function SP_D_Fire( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.hitResult = 1;
	this.SetMotion(3035, 0);
	this.keyAction = [
		function ()
		{
			this.PlaySE(3267);
			this.centerStop = -2;
			this.SetSpeed_XY(-15.00000000 * this.direction, -9.50000000);
			this.stateLabel = function ()
			{
				if (this.Vec_Brake(0.85000002, 1.75000000))
				{
					this.stateLabel = function ()
					{
						this.AddSpeed_XY(0.00000000, 0.50000000);
					};
				}
			};
			this.SetShot(this.x + (50 - 30) * this.direction, this.y + 65, this.direction, this.SPShot_D2, {});
			this.SetShot(this.x + (50 + 30) * this.direction, this.y + 65, this.direction, this.SPShot_D2, {});
		},
		function ()
		{
			this.stateLabel = null;
		}
	];
	this.stateLabel = function ()
	{
		this.Vec_Brake(0.40000001);
	};
}

function SP_D_Kick( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.atk_id = 8388608;
	this.SetMotion(3032, 0);

	if (this.y <= this.centerY)
	{
		this.SetSpeed_XY(7.50000000 * this.direction, -1.00000000);
		this.centerStop = -3;
	}
	else
	{
		this.SetSpeed_XY(7.50000000 * this.direction, 1.00000000);
		this.centerStop = 3;
	}

	this.keyAction = [
		function ()
		{
			this.PlaySE(3306);
			this.SetSelfDamage(200);
			this.stateLabel = function ()
			{
				this.CenterUpdate(0.50000000, null);
				this.VX_Brake(0.10000000);

				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(3032, 3);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.50000000);
					};
				}
			};
		},
		null,
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.50000000);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);
		this.VX_Brake(0.10000000);
	};
}


#5C
function SP_E_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.SetMotion(3040, 0);
	this.atk_id = 16777216;
	this.count = 0;
	this.flag1 = null;
	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
	this.occultCount = 0;
	this.flag2 = null;
	this.flag3 = 0.10000000;
	this.flag4 = ::manbow.Actor2DProcGroup();
	this.flag5 = {};
	this.flag5.priority <- 210;
	this.flag5.size <- 1.00000000;
	this.flag5.level <- 0;
	this.flag5.occult <- this.occultCount > 0;
	this.flag5.level = (this.team.regain_life - this.team.life) / 1000;

	if (this.flag5.level > 4)
	{
		this.flag5.level = 4;
	}

	this.flag5.size = 1.00000000 + this.flag5.level * 0.25000000;

	if (this.flag5.level > 0)
	{
		this.invin = 20;
		this.invinObject = 20;
	}

	this.keyAction = [
		null,
		function ()
		{
			this.team.AddMP(-200, 120);
			this.PlaySE(3269);
			this.SetSpeed_XY(0.00000000, 0.00000000);
			this.count = 0;
			this.centerStop = -2;
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, this.va.y > -7.50000000 ? -0.25000000 : 0.00000000);

				if (this.y < this.centerY - 200)
				{
					this.SetSpeed_XY(0.00000000, 0.00000000);
				}

				if (this.count % 6 == 1)
				{
					local t_ = {};
					t_.scale <- this.flag5.size;
					t_.occult <- this.flag5.occult;
					this.flag4.Add(this.SetFreeObjectDynamic(this.x, ::battle.scroll_bottom - this.rand() % 360, this.direction, this.SPShot_E_Vortex, t_));
				}

				if (this.count >= 35)
				{
					this.SetMotion(this.motion, 3);
					this.count = 0;
					this.stateLabel = function ()
					{
						this.AddSpeed_XY(0.00000000, this.va.y > -15.00000000 ? -0.75000000 : 0.00000000);

						if (this.y < this.centerY - 200)
						{
							this.SetSpeed_XY(0.00000000, 0.00000000);
						}

						if (this.count == 27)
						{
							this.Warp(this.x, 160);
							this.PlaySE(3271);
							local t_ = {};
							t_.occult <- this.flag5.occult;
							this.flag4.Add(this.SetFreeObjectDynamic(this.x, this.y, this.direction, this.SPShot_E_ResFireDyna, t_));
						}

						if (this.count >= 36)
						{
							this.flag3 += 0.02500000;

							if (this.count % 6 == 1)
							{
								local t_ = {};
								t_.scale <- this.flag3;
								t_.priority <- this.flag5.priority;
								t_.occult <- this.flag5.occult;
								this.flag5.priority--;
								this.flag4.Add(this.SetFreeObject(this.x, this.y, this.direction, this.SPShot_E_ResFire, t_));
							}
						}

						if (this.count == 65)
						{
							this.occultCount = 0;
							this.atkRate = 1.00000000;
							this.occult_level = 0;
							this.team.enable_regain = true // modified line
							this.LifeRecover();
							this.PlaySE(3272);
							this.flag4.Foreach(function ()
							{
								this.func[0].call(this);
							});
							this.SetSpeed_XY(0.00000000, -6.00000000);
							this.SetMotion(this.motion, 5);
							this.stateLabel = function ()
							{
								this.AddSpeed_XY(0.00000000, 0.20000000);
							};
						}
					};
					return;
				}

				if (this.count % 5 == 1)
				{
					local t_ = {};
					t_.take <- 4 + this.rand() % 4;
					t_.occult <- this.flag5.occult;

					if (this.count % 4 <= 1)
					{
						this.SetFreeObject(this.x, ::battle.scroll_bottom, this.direction, this.SPShot_E_FirePart, t_);
					}
					else
					{
						this.SetFreeObject(this.x, ::battle.scroll_bottom, -this.direction, this.SPShot_E_FirePart, t_);
					}
				}

				if (this.count % 10 == 1)
				{
					local t_ = {};
					t_.level <- this.flag5.level;
					t_.occult <- this.flag5.occult;
					this.flag2 = this.SetShot(this.x, ::battle.scroll_bottom + 1024, 1.00000000 - this.rand() % 2 * 2, this.SPShot_E_FirePilar, t_).weakref();
				}
			};
		},
		null,
		function ()
		{
		},
		function ()
		{
			this.stateLabel = null;
		},
		null,
		function ()
		{
			this.centerStop = -2;
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(this.motion, 8);
					this.stateLabel = null;
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
		this.CenterUpdate(0.10000000, 2.00000000);
	};
	return true;
}

function Spell_A_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 67108864;
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.flag1 = null;
	this.flag2 = ::manbow.Actor2DProcGroup();

	if (this.occultCount > 0)
	{
		this.SetMotion(4002, 0);
		this.flag3 = true;
	}
	else
	{
		this.SetMotion(4000, 0);
		this.flag3 = false;
	}

	this.keyAction = [
		function ()
		{
			this.UseSpellCard(60, -this.team.sp_max);
			local rate_ = 1.00000000 + (this.team.regain_life - this.team.life) / 5000.00000000 * 0.60000002;

			if (rate_ < 1.00000000)
			{
				rate_ = 1.00000000;
			}

			if (rate_ > 1.60000002)
			{
				rate_ = 1.60000002;
			}

			this.atkRate_Pat *= rate_;
		},
		function ()
		{
			this.SetSpeed_XY(12.50000000 * this.direction, 0.00000000);
		},
		function ()
		{
			this.PlaySE(3273);
			this.count = 0;
			this.stateLabel = function ()
			{
				this.CenterUpdate(0.10000000, null);
				this.VX_Brake(this.va.x * this.direction > 2.00000000 ? 0.50000000 : 0.01000000);

				if (this.count % 8 == 1)
				{
					this.SetSelfDamage(100);
					local t_ = {};
					t_.occult <- this.flag3;
					this.flag2.Add(this.SetFreeObjectDynamic(this.x, this.y + 50, this.direction, this.SpellShotA_VortexA, t_));
				}

				this.HitCycleUpdate(10);

				if (this.count >= 90)
				{
					this.occultCount = 0;
					this.atkRate = 1.00000000;
					this.occult_level = 0;
					this.team.enable_regain = true;
					this.HitTargetReset();
					this.hitResult = 1;
					local t_ = {};
					t_.occult <- this.flag3;
					this.SetFreeObject(this.x, this.y, this.direction, this.SpellShotA_VortexLost, t_);

					if (this.flag1)
					{
						this.flag1.func();
					}

					this.flag2.Foreach(function ()
					{
						this.func[0].call(this);
					});
					this.SetMotion(this.motion, 4);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.05000000);
						this.CenterUpdate(0.10000000, null);
					};
				}
			};
		},
		null,
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.05000000);
			};
		}
	];
	return true;
}

function Spell_A_Hit( t )
{
	this.LabelReset();
	this.HitReset();
	this.atk_id = 67108864;
	this.SetMotion(4001, 0);
	this.count = 0;
	this.flag2 = this.Vector3();
	this.flag3 = ::manbow.Actor2DProcGroup();
	this.stateLabel = function ()
	{
		if (this.flag1)
		{
			this.flag1.x = this.x;
			this.flag1.y = this.y;
		}

		if (this.count % 10 == 1)
		{
			this.SetFreeObjectDynamic(this.x, this.y + 50, this.direction, this.SpellShotA_VortexA, {});
		}

		this.HitCycleUpdate(10);

		if (this.count >= 60)
		{
			if (this.flag1)
			{
				this.flag1.func();
			}

			this.SetMotion(4001, 1);
			this.target.DamageGrab_Common(300, 0, this.target.direction);
			this.GetPoint(0, this.flag2);
			this.target.x = this.flag2.x;
			this.target.y = this.flag2.y;
			this.count = 0;
			this.stateLabel = function ()
			{
				this.GetPoint(0, this.flag2);
				this.target.x = this.flag2.x;
				this.target.y = this.flag2.y;
			};
		}
	};
	this.keyAction = [
		null,
		function ()
		{
			this.count = 0;
			this.PlaySE(3275);
			this.stateLabel = function ()
			{
				if (this.count % 10 == 1)
				{
					this.flag3.Add(this.SetShot(this.x, ::battle.scroll_bottom + 1024, 1.00000000 - this.rand() % 2 * 2, this.SpellShotA_FirePilar, {}));
				}

				if (this.count % 5 == 1)
				{
					local t_ = {};
					t_.take <- 4 + this.rand() % 4;

					if (this.count % 4 <= 1)
					{
						this.SetFreeObject(this.x, ::battle.scroll_bottom, this.direction, this.SpellShotA_FirePart, t_);
					}
					else
					{
						this.SetFreeObject(this.x, ::battle.scroll_bottom, -this.direction, this.SpellShotA_FirePart, t_);
					}
				}

				this.target.x = this.flag2.x;
				this.target.y = this.flag2.y;

				if (this.count % 8 == 1)
				{
					this.SetSelfDamage(200);
					this.PlaySE(3276);
					this.SetEffect(this.target.x - 40 + this.rand() % 81, this.target.y - 40 + this.rand() % 81, this.direction, this.EF_HitSmashC, {});
					this.KnockBackTarget(-this.direction);
				}

				if (this.count == 90)
				{
					if (this.flag1)
					{
						this.flag1.func();
					}

					this.SetMotion(4001, 3);
					this.count = 0;
					this.stateLabel = function ()
					{
					};
				}
			};
		},
		null,
		function ()
		{
			this.KnockBackTarget(-this.direction);
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count >= 30)
				{
					this.SetMotion(4001, 5);
					this.stateLabel = null;
				}
			};
		}
	];
}

function Spell_B_Init( t )
{
	if (this.centerStop * this.centerStop > 0)
	{
		if (this.y < this.centerY)
		{
			this.Spell_B2_Init(t);
			return;
		}
		else if (this.occultCount > 0)
		{
			this.SetMotion(4015, 0);
		}
		else
		{
			this.SetMotion(4013, 0);
		}
	}
	else if (this.occultCount > 0)
	{
		this.SetMotion(4014, 0);
	}
	else
	{
		this.SetMotion(4010, 0);
	}

	this.LabelClear();
	this.HitReset();
	this.atk_id = 67108864;
	this.count = 0;
	this.flag1 = null;
	this.flag2 = ::manbow.Actor2DProcGroup();
	this.flag3 = this.occultCount > 0;
	this.flag5 = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.stateLabel = function ()
	{
	};
	this.keyAction = [
		function ()
		{
			this.centerStop = -2;
			this.PlaySE(3277);
			this.SetSpeed_XY(0.00000000, -17.50000000);
			this.stateLabel = function ()
			{
				if (this.y <= this.centerY)
				{
					this.VY_Brake(this.va.y < -0.50000000 ? 0.75000000 : 0.00000000);
				}
			};
		},
		function ()
		{
			this.ResetSpeed();
			this.UseSpellCard(60, -this.team.sp_max);
			this.stateLabel = null;
		},
		function ()
		{
			this.Spell_B_Kick(null);
		}
	];
	return true;
}

function Spell_B2_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 67108864;
	this.SetMotion(4011, 0);
	this.count = 0;
	this.flag1 = null;
	this.flag3 = this.occultCount > 0;
	this.flag5 = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.stateLabel = function ()
	{
	};
	this.keyAction = [
		function ()
		{
			this.ResetSpeed();
			this.UseSpellCard(60, -this.team.sp_max);
			this.stateLabel = null;
		},
		function ()
		{
			this.Spell_B_Kick(null);
		}
	];
	return true;
}

function SpellShot_B_KichEffect( t )
{
	if (t.occult)
	{
		this.SetMotion(4018, 10);
	}
	else
	{
		this.SetMotion(4018, 0);
	}

	this.sx = this.sy = 0.25000000;
	this.alpha = 0.00000000;
	this.SetParent(this.owner, this.x - this.owner.x, this.y - this.owner.y);
	this.rz = 45 * 0.01745329;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		}
	];
	this.stateLabel = function ()
	{
		this.flag1 += 0.05000000;

		if (this.flag1 > 1.00000000)
		{
			this.flag1 = 0.00000000;
		}

		this.sx = this.sy = this.Math_Bezier(0.25000000, 2.25000000, 2.25000000, this.flag1);
		this.alpha = this.Math_Bezier(0.00000000, 0.00000000, 1.00000000, this.flag1);
	};
}

function SpellShot_B_KichEffectB( t )
{
	if (t.occult)
	{
		this.SetMotion(4018, 7);
	}
	else
	{
		this.SetMotion(4018, 1);
	}

	this.SetParent(this.owner, this.x - this.owner.x, this.y - this.owner.y);
	this.sx = this.sy = 2.00000000;
	this.rz = 45 * 0.01745329;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		}
	];
	this.stateLabel = function ()
	{
	};
}

function SpellShot_B_KichStone( t )
{
	this.SetMotion(4018, 2);
	this.sx = this.sy = 0.25000000;
	this.DrawActorPriority(180);
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.flag1 = 0.50000000;
			this.stateLabel = function ()
			{
				this.sx = this.sy += this.flag1;
				this.flag1 -= 0.03500000;

				if (this.flag1 <= 0.00000000)
				{
					this.flag1 = 0.00000000;
				}

				this.alpha = this.red = this.green = this.blue -= 0.05000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.sx = this.sy += (1.00000000 - this.sx) * 0.25000000;
		this.count++;

		if (this.count >= 90)
		{
			this.alpha -= 0.05000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		}
	};
}

function Spell_B_Kick( t )
{
	this.LabelReset();
	this.HitReset();
	this.atk_id = 67108864;
	this.SetMotion(4010, 3);
	this.count = 0;
	this.flag1 = null;
	this.flag2 = ::manbow.Actor2DProcGroup();
	this.flag5 = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.HitReset();
	local t_ = {};
	t_.occult <- this.flag3;
	this.flag2.Add(this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SpellShot_B_KichEffect, t_));
	this.flag2.Add(this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SpellShot_B_KichEffectB, t_));
	this.lavelClearEvent = function ()
	{
		this.flag2.Foreach(function ()
		{
			this.func[0].call(this);
		});
	};
	this.SetSpeed_Vec(35.00000000, 45 * 0.01745329, this.direction);
	this.PlaySE(3279);
	this.centerStop = 2;
	this.stateLabel = function ()
	{
		this.HitCycleUpdate(3);

		if (this.ground)
		{
			this.LabelReset();
			this.HitReset();
			this.flag2.Foreach(function ()
			{
				this.func[0].call(this);
			});
			this.lavelClearEvent = null;
			this.count = 0;
			this.SetMotion(4012, 0);
			this.ResetSpeed();
			::camera.Shake(10.00000000);
			this.PlaySE(3281);
			local t_ = {};
			t_.rate <- this.atkRate_Pat;
			this.flag1 = this.SetShot(this.x, ::battle.scroll_bottom, this.direction, this.SpellShot_B_KichStone, t_).weakref();
			this.SetEndMotionCallbackFunction(function ()
			{
				this.EndtoFallLoop();
			});
			this.keyAction = [
				null,
				null,
				function ()
				{
					this.hitResult = 1;
					this.centerStop = -2;
					this.SetSpeed_XY(-17.50000000 * this.direction, -20.00000000);
					this.PlaySE(3282);
					this.flag1.func[1].call(this.flag1);
					local t_ = {};
					t_.rate <- this.atkRate_Pat;
					t_.occult <- this.flag3;
					this.SetShot(this.x, ::battle.scroll_bottom, this.direction, this.Spell_B_Fiji, t_);
					this.stateLabel = function ()
					{
						this.AddSpeed_XY(0.00000000, 0.60000002);
						this.VX_Brake(0.25000000);
					};
				}
			];
			this.stateLabel = function ()
			{
				if (this.count >= 20)
				{
					this.SetMotion(4012, 2);
					this.stateLabel = function ()
					{
					};
				}
			};
		}
	};
	return true;
}

function Spell_C_Core( t )
{
	this.stateLabel = function ()
	{
		this.initTable.count--;

		if (this.initTable.count <= 0)
		{
			local se_ = false;

			foreach( a in this.initTable.pareList )
			{
				if (a && a.func[1])
				{
					se_ = true;
					a.func[1].call(a);
				}
			}

			if (se_)
			{
				this.PlaySE(3285);
			}

			this.ReleaseActor();
		}
	};
}

function Spell_C2_Core( t )
{
	this.stateLabel = function ()
	{
		this.initTable.count--;

		if (this.initTable.count <= 0)
		{
			local se_ = false;

			foreach( a in this.initTable.pareList )
			{
				if (a && a.func[1])
				{
					se_ = true;
					a.func[1].call(a);
				}
			}

			if (se_)
			{
				this.PlaySE(3295);
			}

			this.ReleaseActor();
		}
	};
}

function Spell_C_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.atk_id = 67108864;
	this.SetMotion(4020, 0);
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.flag1 = 0.00000000;
	this.flag2 = this.Vector3();
	this.flag2.x = 80.00000000;
	this.flag3 = 180;
	this.keyAction = [
		function ()
		{
			this.UseSpellCard(60, -this.team.sp_max);
			this.flag3 = 90;
		},
		null,
		function ()
		{
			local t_ = {};
			t_.scale <- 1.00000000;
			t_.rot <- this.Vector3();
			t_.rot.x = 60.00000000 * 0.01745329;
			t_.rot.y = 30.00000000 * 0.01745329;
			t_.rot.z = 0.00000000 * 0.01745329;
			this.SetFreeObject(this.x, this.y, this.direction, this.Spell_C_Swing, t_);
			this.count = 0;
			this.PlaySE(3284);

			while (this.flag1 < 6.28318548)
			{
				local a_ = [];

				if (this.flag1 < 6.28318548)
				{
					this.flag1 += 15.00000000 * 0.01745329;
					this.flag2.RotateByDegree(15.00000000);
					local t_ = {};
					t_.rot <- this.flag1;
					t_.rate <- this.atkRate_Pat;
					a_.append(this.SetShot(this.x + this.flag2.x * this.direction, this.y + this.flag2.y, this.direction, this.Spell_C_Amulet, t_).weakref());
				}

				local t_ = {};
				t_.pareList <- a_;
				t_.count <- this.flag3;
				this.SetFreeObject(this.x, this.y, this.direction, this.Spell_C_Core, t_);
			}

			this.stateLabel = function ()
			{
				if (this.count == 0)
				{
					local t_ = {};
					t_.scale <- 0.80000001;
					t_.rot <- this.Vector3();
					t_.rot.x = -30.00000000 * 0.01745329;
					t_.rot.y = 150.00000000 * 0.01745329;
					t_.rot.z = 30.00000000 * 0.01745329;
					this.SetFreeObject(this.x, this.y, this.direction, this.Spell_C_Swing, t_);
				}

				if (this.count == 1)
				{
					local t_ = {};
					t_.scale <- 1.20000005;
					t_.rot <- this.Vector3();
					t_.rot.x = 45.00000000 * 0.01745329;
					t_.rot.y = -120.00000000 * 0.01745329;
					t_.rot.z = -60.00000000 * 0.01745329;
					this.SetFreeObject(this.x, this.y, this.direction, this.Spell_C_Swing, t_);
				}

				if (this.count == 2)
				{
					local t_ = {};
					t_.scale <- 1.10000002;
					t_.rot <- this.Vector3();
					t_.rot.x = 0.00000000 * 0.01745329;
					t_.rot.y = 0.00000000 * 0.01745329;
					t_.rot.z = -0.00000000 * 0.01745329;
					this.SetFreeObject(this.x, this.y, this.direction, this.Spell_C_Swing, t_);
				}

				if (this.count == 3)
				{
					local t_ = {};
					t_.scale <- 1.29999995;
					t_.rot <- this.Vector3();
					t_.rot.x = 10.00000000 * 0.01745329;
					t_.rot.y = -10.00000000 * 0.01745329;
					t_.rot.z = -160.00000000 * 0.01745329;
					this.SetFreeObject(this.x, this.y, -this.direction, this.Spell_C_Swing, t_);
				}
			};
		},
		function ()
		{
			this.flag1 = 0.00000000;
			local a_ = [];

			while (this.flag1 < 6.28318548)
			{
				if (this.flag1 < 6.28318548)
				{
					this.flag1 += 12.00000000 * 0.01745329;
					this.flag2.RotateByDegree(12.00000000);
					local t_ = {};
					t_.rot <- this.flag1 + 3.14159203;
					t_.count <- this.flag3;
					t_.rate <- this.atkRate_Pat;
					a_.append(this.SetShot(this.x + this.flag2.x * -2 * this.direction, this.y + this.flag2.y * -2, this.direction, this.Spell_C_Amulet, t_).weakref());
				}
			}

			this.flag3 += 6;
			local t_ = {};
			t_.pareList <- a_;
			t_.count <- this.flag3;
			this.SetFreeObject(this.x, this.y, this.direction, this.Spell_C2_Core, t_);
			this.stateLabel = function ()
			{
			};
		},
		function ()
		{
			this.flag1 = 0.00000000;
			local a_ = [];

			while (this.flag1 < 6.28318548)
			{
				if (this.flag1 < 6.28318548)
				{
					this.flag1 += 8.00000000 * 0.01745329;
					this.flag2.RotateByDegree(8.00000000);
					local t_ = {};
					t_.rot <- this.flag1 + 3.14159203;
					t_.count <- this.flag3;
					t_.rate <- this.atkRate_Pat;
					a_.append(this.SetShot(this.x + this.flag2.x * -3 * this.direction, this.y + this.flag2.y * -3, this.direction, this.Spell_C_Amulet, t_).weakref());
				}
			}

			this.flag3 += 6;
			local t_ = {};
			t_.pareList <- a_;
			t_.count <- this.flag3;
			this.SetFreeObject(this.x, this.y, this.direction, this.Spell_C2_Core, t_);
			this.stateLabel = function ()
			{
			};
		},
		function ()
		{
		}
	];
	return true;
}

function Spell_Climax_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 134217728;
	this.SetMotion(4900, 0);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.flag1 = ::manbow.Actor2DProcGroup();
	this.flag2 = null;
	this.flag3 = null;
	this.func = [
		function ()
		{
			this.count = 29;
			this.stateLabel = function ()
			{
				local t_ = 210;

				if (this.count == 30)
				{
					::battle.enableTimeUp = false;
					this.PlaySE(3288);
					this.EraceBackGround();
					this.SetTimeStop(180);
					this.flag3 = this.SetFreeObject(640 + 640 * this.direction, 920, this.direction, this.Climax_Cut, {}).weakref();
				}

				if (this.count >= t_)
				{
					this.SetSelfDamage(200);
				}

				if (this.count == t_ - 30)
				{
					this.FadeOut(1.00000000, 1.00000000, 1.00000000, 25);
				}

				if (this.count == t_)
				{
					this.PlaySE(3290);
					this.EraceBackGround(false);
					this.FadeIn(1.00000000, 1.00000000, 1.00000000, 30);
					this.flag3.func[0].call(this.flag3);
				}

				if (this.count == t_)
				{
					if (this.flag2)
					{
						this.flag2.func[2].call(this.flag2);
					}
				}

				if (this.count == t_ + 60)
				{
					this.func[1].call(this);
					return;
				}
			};
		},
		function ()
		{
			this.SetMotion(4900, 6);
			this.count = 0;
			this.stateLabel = function ()
			{
				this.SetSelfDamage(200);

				if (this.count == 60)
				{
					this.func[2].call(this);
				}
			};
		},
		function ()
		{
			if (this.flag2)
			{
				this.flag2.func[3].call(this.flag2);
			}

			this.count = 0;
			this.Spell_Climax_Reborn(null);
			return;
			this.stateLabel = function ()
			{
				if (this.count == 20)
				{
					this.Spell_Climax_Reborn(null);
					return;
				}
			};
		}
	];
	this.keyAction = [
		function ()
		{
			this.occultCount = 0;
			this.atkRate = 1.00000000;
			this.occult_level = 0;
			this.UseClimaxSpell(60, "ÅñÇ±ÇÒÇ»ê¢ÇÕîRÇ¶êsÇ´ÇƒÇµÇ‹Ç¶ÅIÅñ");
			::battle.enableTimeUp = false;
			this.lavelClearEvent = function ()
			{
				if (this.flag2)
				{
					this.flag2.func[0].call(this.flag2);
				}

				::battle.enableTimeUp = true;
				this.lastword.Deactivate();
			};
			local t_ = {};
			t_.rate <- this.atkRate_Pat;
			this.flag2 = this.SetShot(this.point0_x, this.point0_y, this.direction, this.Climax_Ball, t_).weakref();
			this.stateLabel = function ()
			{
				if (this.flag2)
				{
					this.flag2.x += (this.point0_x - this.flag2.x) * 0.25000000;
					this.flag2.y += (this.point0_y - this.flag2.y) * 0.25000000;
				}
			};
		},
		function ()
		{
		},
		function ()
		{
		},
		function ()
		{
			this.PlaySE(3287);
			this.func[0].call(this);
		}
	];
	return true;
}

function Spell_Climax_Reborn( t )
{
	this.LabelReset();
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.SetMotion(4901, 3);
	this.occultCount = 0;
	this.flag2;
	this.flag3 = 0.10000000;
	this.flag4 = ::manbow.Actor2DProcGroup();
	this.flag5 = {};
	this.flag5.priority <- 210;
	this.flag5.size <- 1.00000000;
	this.flag5.level <- 0;
	this.count = 0;
	this.keyAction = [
		null,
		null,
		null,
		null,
		null,
		null,
		function ()
		{
			this.centerStop = -2;
			this.EndtoFallLoop();
		}
	];
	this.stateLabel = function ()
	{
		if (this.count == 27)
		{
			this.PlaySE(3271);
			local t_ = {};
			t_.occult <- false;
			this.flag4.Add(this.SetFreeObjectDynamic(this.x, this.y, this.direction, this.SPShot_E_ResFireDyna, t_));
		}

		if (this.count >= 36)
		{
			this.flag3 += 0.02500000;

			if (this.count % 6 == 1)
			{
				local t_ = {};
				t_.scale <- this.flag3;
				t_.priority <- this.flag5.priority;
				t_.occult <- false;
				this.flag5.priority--;
				this.flag4.Add(this.SetFreeObject(this.x, this.y, this.direction, this.SPShot_E_ResFire, t_));
			}
		}

		if (this.count == 65)
		{
			this.LifeRecover();
			this.PlaySE(3272);
			this.flag4.Foreach(function ()
			{
				this.func[0].call(this);
			});
			this.SetSpeed_XY(0.00000000, -6.00000000);
			this.centerStop = -3;
			this.SetMotion(this.motion, 5);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.20000000);
			};
		}
	};
}

