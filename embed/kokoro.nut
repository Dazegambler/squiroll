function Func_BeginBattle()
{
	if (this.team.master == this && this.team.slave && this.team.slave.type == 6)
	{
		this.BeginBattle_Nitori(null);
		return;
	}

	this.BeginBattle(null);
}

function Func_Win()
{
	local r_ = this.rand() % 3;

	switch(r_)
	{
	case 0:
		this.WinA(null);
		break;

	case 1:
		this.WinB(null);
		break;

	case 2:
		this.WinC(null);
		break;
	}
}

function Func_Lose()
{
	this.Lose(null);
}

function BeginBattle( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.count = 0;
	this.SetMotion(9000, 0);
	this.demoObject = [];
	this.masterAlpha = 0.00000000;
	this.PlaySE(2990);
	this.keyAction = [
		null,
		function ()
		{
			this.PlaySE(2992);

			foreach( a in this.demoObject )
			{
				a.func();
			}
		},
		function ()
		{
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count >= 60)
				{
					this.SetMotion(9000, 4);
					this.stateLabel = null;
				}
			};
		},
		null,
		function ()
		{
			this.CommonBegin();
			this.EndtoFreeMove();
		}
	];
	this.stateLabel = function ()
	{
		this.masterAlpha = 0.00000000;

		if (this.count >= 120)
		{
			this.count = 0;
			local j = 5;
			this.PlaySE(2991);

			for( local i = 0; i < 360; i = i + 40 )
			{
				local t_ = {};
				t_.type <- j;
				j++;

				if (j >= 8)
				{
					j = 5;
				}

				t_.rot <- i * 0.01745329;
				this.demoObject.append(this.SetFreeObject(this.x, this.y, this.direction, this.BattleBegin_Mask, t_).weakref());
			}

			this.stateLabel = function ()
			{
				this.masterAlpha += 0.02500000;

				if (this.masterAlpha > 1.00000000)
				{
					this.masterAlpha = 1.00000000;
				}

				if (this.count >= 90)
				{
					this.SetMotion(9000, 1);
					this.stateLabel = function ()
					{
					};
				}
			};
		}
	};
}

function BeginBattle_Nitori( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.SetMotion(9001 + this.rand() % 3, 0);
	this.DrawActorPriority();
	this.count = 0;
	this.team.slave.BeginBattle_Slave(null);
	this.stateLabel = function ()
	{
		if (this.count == 150)
		{
			this.SetMotion(this.motion, 1);
			this.team.slave.func();
		}
	};
	this.keyAction = [
		null,
		function ()
		{
			this.PlaySE(2987);
		},
		null,
		function ()
		{
			this.CommonBegin();
		}
	];
}

function BeginStory( t )
{
	if (this.team.index == 2)
	{
		this.Warp(::battle.start_x[1], this.centerY);
		this.direction = -1.00000000;
	}
	else
	{
		this.Warp(::battle.start_x[0], this.centerY);
		this.direction = 1.00000000;
	}

	this.isVisible = true;
	this.masterAlpha = 0.00000000;
	this.alpha = 0.00000000;
	this.BeginBattle(t);
}

function WinA( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.SetMotion(9010, 0);
	this.keyAction = [
		function ()
		{
			this.PlaySE(2996);
		},
		function ()
		{
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count == 90)
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
	this.SetMotion(9011, 0);
	this.count = 0;
	this.keyAction = [
		function ()
		{
			this.PlaySE(2996);
		},
		null,
		function ()
		{
			this.PlaySE(2996);
		},
		null,
		function ()
		{
			this.PlaySE(2997);
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count == 90)
				{
					this.CommonWin();
				}
			};
		}
	];
}

function WinC( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.SetMotion(9012, 0);
	this.count = 0;
	this.func = function ( dir_ )
	{
		for( local i_ = 0; i_ < 12; i_++ )
		{
			this.SetEffect(this.point0_x, this.point0_y, dir_, this.EF_ApGuardConfetti, {});
		}
	};
	this.keyAction = [
		function ()
		{
			this.func(this.direction);

			if (::battle.state == 32)
			{
				this.PlaySE(2996);
			}
		},
		function ()
		{
			if (::battle.state == 32)
			{
				this.PlaySE(2996);
			}

			this.func(-this.direction);
		},
		function ()
		{
			if (::battle.state == 32)
			{
				this.PlaySE(2996);
			}

			this.SetMotion(9012, 1);
			this.func(this.direction);
		}
	];
	this.stateLabel = function ()
	{
		if (this.count == 120)
		{
			this.CommonWin();
		}
	};
}

function Lose( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.LabelClear();
	this.SetMotion(9020, 0);
	this.DamageMask();
	this.count = 0;
	this.stateLabel = function ()
	{
		if (this.count == 120)
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

function Stand()
{
	this.GetFront();
	this.VX_Brake(0.80000001);
}

function MoveFront_Init( t )
{
	this.LabelClear();
	this.stateLabel = this.MoveFront;
	this.SetMotion(1, 0);

	if (this.emotion == 2)
	{
		this.SetSpeed_XY(5.50000000 * this.direction, this.va.y);
	}
	else
	{
		this.SetSpeed_XY(4.50000000 * this.direction, this.va.y);
		  // [036]  OP_JMP            0      0    0    0
	}
}

function MoveBack_Init( t )
{
	this.LabelClear();
	this.stateLabel = this.MoveBack;
	this.SetMotion(2, 0);

	if (this.emotion == 2)
	{
		this.SetSpeed_XY(-5.50000000 * this.direction, this.va.y);
	}
	else
	{
		this.SetSpeed_XY(-4.50000000 * this.direction, this.va.y);
		  // [036]  OP_JMP            0      0    0    0
	}
}

function SlideUp_Init( t )
{
	local t_ = {};
	t_.dash <- 7.00000000;
	t_.front <- 5.00000000;
	t_.back <- -5.00000000;
	t_.front_rev <- 4.00000000;
	t_.back_rev <- -4.00000000;
	t_.v <- -13.00000000;
	t_.v2 <- -9.00000000;
	t_.v3 <- 13.00000000;

	if (this.emotion == 2)
	{
		t_.front <- 6.00000000;
		t_.back <- -6.00000000;
		t_.front_rev <- 4.50000000;
		t_.back_rev <- -4.50000000;
	}
	else
	{
		t_.front <- 5.00000000;
		t_.back <- -5.00000000;
		t_.front_rev <- 4.00000000;
		t_.back_rev <- -4.00000000;
		  // [066]  OP_JMP            0      0    0    0
	}

	this.SlideUp_Common(t_);
}

function C_SlideUp_Init( t )
{
	local t_ = {};
	t_.dash <- 7.00000000;
	t_.front <- 5.00000000;
	t_.back <- -5.00000000;
	t_.front_rev <- 4.00000000;
	t_.back_rev <- -4.00000000;
	t_.v <- -13.00000000;
	t_.v2 <- -9.00000000;
	t_.v3 <- 13.00000000;

	if (this.emotion == 2)
	{
		t_.front <- 6.00000000;
		t_.back <- -6.00000000;
		t_.front_rev <- 4.50000000;
		t_.back_rev <- -4.50000000;
	}
	else
	{
		t_.front <- 5.00000000;
		t_.back <- -5.00000000;
		t_.front_rev <- 4.00000000;
		t_.back_rev <- -4.00000000;
		  // [066]  OP_JMP            0      0    0    0
	}

	this.C_SlideUp_Common(t_);
}

function SlideFall_Init( t )
{
	local t_ = {};
	t_.dash <- 7.00000000;
	t_.front <- 5.00000000;
	t_.back <- -5.00000000;
	t_.front_rev <- 4.00000000;
	t_.back_rev <- -4.00000000;
	t_.v <- 13.00000000;
	t_.v2 <- 9.00000000;
	t_.v3 <- 13.00000000;

	if (this.emotion == 2)
	{
		t_.front <- 6.00000000;
		t_.back <- -6.00000000;
	}
	else
	{
		t_.front <- 5.00000000;
		t_.back <- -5.00000000;
		  // [052]  OP_JMP            0      0    0    0
	}

	this.SlideFall_Common(t_);
}

function C_SlideFall_Init( t )
{
	local t_ = {};
	t_.dash <- 7.00000000;
	t_.front <- 5.00000000;
	t_.back <- -5.00000000;
	t_.front_rev <- 4.00000000;
	t_.back_rev <- -4.00000000;
	t_.v <- 13.00000000;
	t_.v2 <- 9.00000000;
	t_.v3 <- 13.00000000;

	if (this.emotion == 2)
	{
		t_.front <- 6.00000000;
		t_.back <- -6.00000000;
	}
	else
	{
		t_.front <- 5.00000000;
		t_.back <- -5.00000000;
		  // [052]  OP_JMP            0      0    0    0
	}

	this.C_SlideFall_Common(t_);
}

function Team_Change_AirMoveB( t_ )
{
	this.SummonMask();
	this.Team_Change_AirMoveCommon(null);
	this.flag5.vx = 7.00000000;
	this.flag5.vy = 6.50000000;
	this.flag5.g = this.baseGravity;
}

function Team_Change_AirBackB( t_ )
{
	this.SummonMask();
	this.Team_Change_AirBackCommon(null);
	this.flag5.vx = -7.00000000;
	this.flag5.vy = 6.50000000;
	this.flag5.g = this.baseGravity;
}

function Team_Change_AirSlideUpperB( t_ )
{
	this.SummonMask();
	this.Team_Change_AirSlideUpperCommon(null);
	this.flag5.vx = 0.00000000;
	this.flag5.vy = -7.50000000;
	this.flag5.g = this.baseGravity;
}

function Team_Change_AirSlideUnderB( t_ )
{
	this.SummonMask();
	this.Team_Change_AirSlideUnderCommon(null);
	this.flag5.vx = 0.00000000;
	this.flag5.vy = 7.50000000;
	this.flag5.g = this.baseGravity;
}

function DashFront_Init( t )
{
	local t_ = {};
	t_.speed <- 7.00000000;
	t_.addSpeed <- 0.34999999;
	t_.maxSpeed <- 14.00000000;
	t_.wait <- 120;
	this.DashFront_Common(t_);
}

function DashFront_Air_Init( t )
{
	local t_ = {};
	t_.speed <- 6.75000000;
	t_.g <- 0.10000000;
	t_.minWait <- 12;
	t_.wait <- 60;
	t_.addSpeed <- 0.12500000;
	t_.maxSpeed <- 13.50000000;
	this.DashFront_Air_Common(t_);
}

function DashBack_Init( t )
{
	this.LabelClear();
	this.SetMotion(41, 0);
	this.PlaySE(801);
	this.SetSpeed_XY(-12.50000000 * this.direction, -4.00000000);
	this.centerStop = -2;
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, 0.55000001);

		if (this.y > this.centerY && this.va.y > 0.00000000)
		{
			this.SetMotion(41, 3);
			this.centerStop = 1;
			this.SetSpeed_XY(null, 2.00000000);
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
	t_.speed <- -6.50000000;
	t_.g <- 0.10000000;
	t_.minWait <- 12;
	t_.wait <- 30;
	t_.addSpeed <- 0.10000000;
	t_.maxSpeed <- 13.00000000;
	this.DashBack_Air_Common(t_);
}

function Atk_RushA_Init( t )
{
	this.Atk_Mid_Init(t);
	this.SetMotion(1600, 0);
	this.atk_id = 1;
	return true;
}

function Atk_Low_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1;
	this.combo_func = this.Rush_AAA;
	this.SetMotion(1000, 0);
	this.keyAction = [
		function ()
		{
			this.PlaySE(2800);
		},
		function ()
		{
			this.HitTargetReset();
		},
		function ()
		{
			this.HitTargetReset();
		},
		function ()
		{
			this.HitTargetReset();
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
	};
	return true;
}

function Atk_RushB_Init( t )
{
	this.Atk_RushA_Init(t);
	this.atk_id = 4;
	return true;
}

function Atk_Mid_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 2;
	this.combo_func = this.Rush_Far;
	this.SetMotion(1100, 0);
	this.count = 0;
	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(5.00000000 * this.direction, null);
			this.PlaySE(2802);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		if (this.count == 8)
		{
			this.SetSpeed_XY(10.00000000 * this.direction, null);
		}

		this.VX_Brake(0.50000000);
	};
	return true;
}

function Atk_Mid_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 8;
	this.combo_func = this.Rush_Air;
	this.SetMotion(1110, 0);
	this.count = 0;
	this.keyAction = [
		function ()
		{
			this.PlaySE(2802);
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
		},
		this.EndtoFreeMove
	];
	this.stateLabel = function ()
	{
		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(1110, 4);
			this.GetFront();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
		}
	};
	return true;
}

function Atk_High_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(1200, 0);
	this.keyAction = [
		function ()
		{
			this.centerStop = -2;
			this.SetSpeed_XY(9.00000000 * this.direction, -6.00000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.15000001);
				this.AddSpeed_XY(0.00000000, 0.03500000);
			};
		},
		function ()
		{
			this.centerStop = 2;
			this.SetSpeed_XY(this.va.x * 0.80000001, 6.00000000);
			this.PlaySE(2804);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.30000001);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.Vec_Brake(0.50000000);
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
		if (this.centerStop == 0)
		{
			this.VX_Brake(0.50000000);
		}
		else
		{
			this.VX_Brake(0.10000000);
		}
	};
	return true;
}

function Atk_RushC_Under_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 128;
	this.hitCount = 0;
	this.flag1 = 0;
	this.centerStop = -2;
	this.SetSpeed_XY(8.50000000 * this.direction, -15.00000000);
	this.SetMotion(1710, 0);
	this.stateLabel = function ()
	{
		this.VX_Brake(0.20000000);
		this.AddSpeed_XY(0.00000000, 0.75000000);
	};
	this.keyAction = [
		function ()
		{
			this.count = 0;
			this.centerStop = 2;
			this.SetSpeed_XY(this.va.x, 15.00000000);
			this.PlaySE(2806);
			this.stateLabel = function ()
			{
				this.HitCycleUpdate(3);
				this.AddSpeed_XY(0.00000000, -0.25000000);

				if (this.count >= 18)
				{
					this.SetMotion(this.motion, 2);
					this.stateLabel = function ()
					{
						this.Vec_Brake(0.50000000, 1.00000000);
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

function Atk_HighUnder_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 128;
	this.hitCount = 0;
	this.flag2 = -1;
	this.centerStop = -2;
	this.SetSpeed_XY(8.50000000 * this.direction, -15.00000000);
	this.SetMotion(1210, 0);
	this.stateLabel = function ()
	{
		this.VX_Brake(0.20000000);
		this.AddSpeed_XY(0.00000000, 0.75000000);
	};
	this.keyAction = [
		function ()
		{
			this.count = 0;
			this.centerStop = 2;
			this.SetSpeed_XY(this.va.x, 15.00000000);
			this.PlaySE(2806);
			this.stateLabel = function ()
			{
				this.HitCycleUpdate(3);
				this.AddSpeed_XY(0.00000000, -0.25000000);

				if (this.count >= 18)
				{
					this.SetMotion(this.motion, 2);
					this.stateLabel = function ()
					{
						this.Vec_Brake(0.50000000, 1.00000000);
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

function Atk_HighUnder_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1024;
	this.SetMotion(1211, 0);
	this.hitCount = 0;
	this.flag2 = 1;
	this.flag3 = 0.00000000;

	if (this.va.x * this.direction < 0.00000000)
	{
		this.flag3 = -3.00000000;
	}

	if (this.va.x * this.direction > 0.00000000)
	{
		this.flag3 = 5.00000000;
	}

	this.SetSpeed_XY(this.va.x * 0.75000000, this.va.y * 0.50000000);
	this.stateLabel = function ()
	{
		this.VX_Brake(0.25000000);
		this.CenterUpdate(0.10000000, null);

		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(1211, 3);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
			return;
		}
	};
	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(this.flag3 * this.direction, 0.00000000);
			this.PlaySE(2806);
			this.count = 0;
			this.stateLabel = function ()
			{
				this.VX_Brake(0.01000000);
				this.CenterUpdate(0.30000001, null);

				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(1211, 3);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.50000000);
					};
					return;
				}

				this.HitCycleUpdate(3);

				if (this.count >= 18)
				{
					this.SetMotion(this.motion, 2);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.05000000);
						this.CenterUpdate(0.30000001, null);

						if (this.centerStop * this.centerStop <= 1)
						{
							this.SetMotion(1211, 3);
							this.stateLabel = function ()
							{
								this.VX_Brake(0.50000000);
							};
							return;
						}
					};
				}
			};
		},
		null,
		function ()
		{
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.50000000);
				}
				else
				{
					this.VX_Brake(0.05000000);
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
	this.SetMotion(1220, 0);
	this.SetEndMotionCallbackFunction(this.EndtoFallLoop);
	this.keyAction = [
		function ()
		{
			this.PlaySE(2808);
			this.centerStop = -2;
			this.SetSpeed_XY(7.50000000 * this.direction, -16.50000000);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.10000000);
				this.AddSpeed_XY(0.00000000, 1.25000000);

				if (this.va.y >= -4.00000000)
				{
					this.stateLabel = function ()
					{
						this.VX_Brake(0.10000000);
						this.AddSpeed_XY(0.00000000, 0.10000000);
					};
				}
			};
		},
		function ()
		{
			this.centerStop = -2;

			if (this.target.y - this.y <= 0)
			{
				this.SetSpeed_XY(null, -10.00000000);
			}
			else
			{
				this.SetSpeed_XY(null, -5.00000000);
			}
		},
		function ()
		{
			this.HitTargetReset();
			this.PlaySE(2810);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.20000000);
				this.AddSpeed_XY(0.00000000, 0.60000002);
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
		this.VX_Brake(0.25000000);
	};
	return true;
}

function Atk_RushC_Upper_Init( t )
{
	this.Atk_HighUpper_Init(t);
	this.flag1 = 0;
	this.SetMotion(1720, 0);
	this.atk_id = 64;
	return true;
}

function Atk_HighUpper_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 512;
	this.SetMotion(1221, 0);
	this.SetSpeed_XY(this.va.x * 0.75000000, this.va.y * 0.50000000);
	this.keyAction = [
		function ()
		{
			this.PlaySE(2808);
		},
		function ()
		{
		},
		function ()
		{
			this.HitTargetReset();
			this.PlaySE(2810);
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
		this.CenterUpdate(0.20000000, null);

		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(1221, 4);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
			return;
		}
	};
	return true;
}

function Atk_RushC_Front_Init( t )
{
	this.Atk_HighFront_Init(t);
	this.flag1 = 0;
	this.SetMotion(1730, 0);
	this.atk_id = 32;
	return true;
}

function Atk_RushA_Far_Init( t )
{
	this.Atk_HighFront_Init(t);
	this.SetMotion(1740, 0);
	this.atk_id = 2048;
	this.flag1 = false;
	return true;
}

function Atk_HighFront_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 32;
	this.SetSpeed_XY(16.00000000 * this.direction, null);
	this.SetMotion(1230, 0);
	this.keyAction = [
		function ()
		{
		},
		function ()
		{
			this.SetSpeed_XY(-17.50000000 * this.direction, null);
			this.PlaySE(2812);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
			};
		},
		function ()
		{
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
	};
	return true;
}

function Atk_RushA_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 16;
	this.SetMotion(1750, 0);
	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
			this.PlaySE(2998);
			this.stateLabel = function ()
			{
				this.CenterUpdate(0.10000000, 3.00000000);

				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(1750, 3);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.50000000);
					};
					return;
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(1750, 3);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.50000000);
					};
					return;
				}
			};
		},
		this.EndtoFreeMove
	];
	this.stateLabel = function ()
	{
		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(1750, 3);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
			return;
		}
	};
	return true;
}

function Atk_HighFront_Air_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 256;
	this.SetMotion(1231, 0);
	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
			this.PlaySE(2998);
			this.stateLabel = function ()
			{
				this.CenterUpdate(0.10000000, 3.00000000);

				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(1231, 3);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.50000000);
					};
					return;
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.SetMotion(1231, 3);
					this.stateLabel = function ()
					{
						this.VX_Brake(0.50000000);
					};
					return;
				}
			};
		},
		this.EndtoFreeMove
	];
	this.stateLabel = function ()
	{
		if (this.centerStop * this.centerStop <= 1)
		{
			this.SetMotion(1231, 3);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
			};
			return;
		}
	};
	return true;
}

function Atk_LowDash_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 4096;
	this.SetMotion(1300, 0);
	this.keyAction = [
		function ()
		{
			this.stateLabel = function ()
			{
				this.CenterUpdate(0.25000000, null);
			};
			this.SetSpeed_XY(8.00000000 * this.direction, 0.00000000);
			this.PlaySE(2808);
		},
		null,
		function ()
		{
			this.PlaySE(2808);
			this.HitTargetReset();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.33000001);
			};
		},
		function ()
		{
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.20000000);
	};
	return true;
}

function Atk_RushD_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(1740, 0);
	this.keyAction = [
		null,
		function ()
		{
			this.SetSpeed_XY(13.50000000 * this.direction, null);
			this.PlaySE(2812);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.50000000);
				this.CenterUpdate(0.10000000, null);
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.75000000);
				this.CenterUpdate(0.10000000, null);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.50000000);
		this.CenterUpdate(0.10000000, null);
	};
	return true;
}

function Atk_HighDash_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 8192;
	this.SetMotion(1310, 0);
	this.keyAction = [
		function ()
		{
			this.SetSpeed_XY(15.00000000 * this.direction, 0.00000000);
			this.PlaySE(2816);
			this.hitCount = 0;
			this.flag1 = 0;
			this.stateLabel = function ()
			{
				if (this.hitTarget.len() > 0 && this.hitCount <= 2)
				{
					this.flag1++;

					if (this.flag1 >= 3)
					{
						this.flag1 = 0;
						this.HitTargetReset();
					}
				}

				this.VX_Brake(0.50000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.75000000);
	};
}

function Atk_HighDash()
{
	if (this.keyTake == 0)
	{
		this.Vec_Brake(0.50000000);
	}

	if (this.keyTake == 1 || this.keyTake == 2)
	{
		this.VX_Brake(0.25000000);
		this.AddSpeed_XY(null, 0.34999999);
	}

	if (this.keyTake == 3)
	{
		this.VX_Brake(0.40000001);
	}

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
		this.target.Warp(this.initTable.pare.point0_x - (this.target.point0_x - this.target.x), this.initTable.pare.y);
	};
}

function Grab_Mask( t )
{
	this.SetMotion(1802, 3);
	this.DrawActorPriority(190);
	this.func = [
		function ()
		{
			this.stateLabel = function ()
			{
				this.rz += this.flag1;
				this.flag1 += 0.50000000 * 0.01745329;
				this.AddSpeed_XY(0.00000000, 0.50000000);
				this.alpha = this.red = this.green = this.blue -= 0.03300000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		},
		function ()
		{
			this.SetSpeed_XY(-20.00000000 * this.direction, -35.00000000);
			this.stateLabel = function ()
			{
				this.rz -= 0.10471975;
				this.alpha = this.red = this.green = this.blue -= 0.03300000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.stateLabel = function ()
	{
	};
}

function Atk_Grab_Hit( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(1802, 0);
	this.PlaySE(806);

	if (this.x > ::battle.corner_right - 80 && this.direction == 1.00000000)
	{
		this.Warp(::battle.corner_right - 80, this.y);
	}

	if (this.x < ::battle.corner_left + 80 && this.direction == -1.00000000)
	{
		this.Warp(::battle.corner_left + 80, this.y);
	}

	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.target.DamageGrab_Common(300, 2, -this.direction);
	this.target.autoCamera = false;
	::battle.enableTimeUp = false;
	this.target.cameraPos.x = this.x;
	this.target.cameraPos.y = this.y;
	this.flag1 = this.SetFreeObject(this.x, this.y, this.direction, this.Grab_Actor, {}, this.weakref()).weakref();
	this.flag2 = this.SetFreeObject(this.point0_x, this.point0_y, -this.direction, this.Grab_Mask, {}).weakref();
	this.DrawActorPriority(190);
	this.target.Warp(this.point0_x - (this.target.point0_x - this.target.x), this.y);
	this.stateLabel = function ()
	{
		if (this.Atk_Grab_Hit_Update())
		{
			this.flag1.func[0].call(this.flag1);
			this.flag2.func[0].call(this.flag2);
			this.target.autoCamera = true;
			this.Grab_Blocked(null);
			return;
		}
	};
	this.keyAction = [
		function ()
		{
			this.Atk_Throw(null);
		}
	];
}

function Atk_Throw( t )
{
	this.LabelClear();
	this.SetMotion(1802, 1);

	if (this.flag1)
	{
		this.flag1.func[0].call(this.flag1);
	}

	this.SetSpeed_XY(-10.00000000 * this.direction, 0.00000000);
	this.stateLabel = function ()
	{
		this.VX_Brake(0.25000000);
	};
	this.keyAction = [
		null,
		function ()
		{
			this.count = 0;
			this.PlaySE(2986);
			::camera.shake_radius = 3.00000000;
			this.SetEffect(this.target.x, this.target.y, this.direction, this.EF_HitSmashC, {});
			this.KnockBackTarget(-this.direction);
			::battle.enableTimeUp = true;
			::camera.SetTarget(this.x, this.y, 2.00000000, false);

			if (this.flag2)
			{
				this.flag2.func[1].call(this.flag2);
			}

			this.HitReset();
			this.hitResult = 1;
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
			this.stateLabel = function ()
			{
				this.VX_Brake(2.50000000);

				if (this.count == 75)
				{
					::camera.ResetTarget();
					this.target.team.master.autoCamera = true;

					if (this.target.team.slave)
					{
						this.target.team.slave.autoCamera = true;
					}
				}
			};
		},
		function ()
		{
			this.EndtoFreeMove();
		}
	];
}

function Shot_Normal_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.hitResult = 1;
	this.SetMotion(2000, 0);
	this.flag1 = 0;
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.PlaySE(2820);

			if (this.mask)
			{
				local c_ = 0;

				foreach( a in this.mask )
				{
					if (a && a.motion == 5990)
					{
						if (a.flag5)
						{
							c_++;
						}
					}
				}

				if (c_ >= 3)
				{
					local t_ = {};
					t_.rot <- 0.00000000;

					foreach( a in this.mask )
					{
						switch(this.emotion)
						{
						case 1:
							if (this.flag1 > 0)
							{
								t_.rot = 10 * 0.01745329;
							}

							if (this.flag1 < 0)
							{
								t_.rot = -10 * 0.01745329;
							}

							this.NormalShot_D.call(a, t_);
							break;

						case 0:
							if (this.flag1 > 0)
							{
								t_.rot = 30 * 0.01745329;
							}

							if (this.flag1 < 0)
							{
								t_.rot = -30 * 0.01745329;
							}

							this.NormalShot_S.call(a, t_);
							break;

						case 2:
							this.NormalShot_B.call(a, null);
							break;

						default:
							if (this.flag1 > 0)
							{
								t_.rot = 60 * 0.01745329;
							}

							if (this.flag1 < 0)
							{
								t_.rot = -60 * 0.01745329;
							}

							this.NormalShot.call(a, t_);
							break;
						}
					}
				}
			}
		},
		function ()
		{
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
	this.hitResult = 1;
	this.AjustCenterStop();
	this.SetMotion(2001, 0);
	this.SetSpeed_XY(this.va.x * 0.25000000, this.va.y * 0.25000000);
	this.flag1 = 0;
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 90);
			this.PlaySE(2820);

			if (this.mask)
			{
				local c_ = 0;

				foreach( a in this.mask )
				{
					if (a && a.motion == 5990)
					{
						if (a.flag5)
						{
							c_++;
						}
					}
				}

				if (c_ >= 3)
				{
					local t_ = {};
					t_.rot <- 0.00000000;

					foreach( a in this.mask )
					{
						switch(this.emotion)
						{
						case 1:
							if (this.flag1 > 0)
							{
								t_.rot = 10 * 0.01745329;
							}

							if (this.flag1 < 0)
							{
								t_.rot = -10 * 0.01745329;
							}

							this.NormalShot_D.call(a, t_);
							break;

						case 0:
							if (this.flag1 > 0)
							{
								t_.rot = 30 * 0.01745329;
							}

							if (this.flag1 < 0)
							{
								t_.rot = -30 * 0.01745329;
							}

							this.NormalShot_S.call(a, t_);
							break;

						case 2:
							this.NormalShot_B.call(a, null);
							break;

						default:
							if (this.flag1 > 0)
							{
								t_.rot = 60 * 0.01745329;
							}

							if (this.flag1 < 0)
							{
								t_.rot = -60 * 0.01745329;
							}

							this.NormalShot.call(a, t_);
							break;
						}
					}
				}
			}
		},
		function ()
		{
			this.stateLabel = function ()
			{
				if (this.centerStop * this.centerStop <= 1)
				{
					this.VX_Brake(0.50000000);
				}
				else
				{
					this.VX_Brake(0.05000000);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);

		if (this.centerStop * this.centerStop <= 0)
		{
			this.VX_Brake(0.50000000);
		}
		else
		{
			this.VX_Brake(0.05000000);
		}
	};
	return true;
}

function Shot_Normal_Upper_Init( t )
{
	this.Shot_Normal_Init.call(this, t);
	this.flag1 = -1;
	return true;
}

function Shot_Normal_Upper_Air_Init( t )
{
	this.Shot_Normal_Air_Init.call(this, t);
	this.flag1 = -1;
	return true;
}

function Shot_Normal_Under_Init( t )
{
	this.Shot_Normal_Init.call(this, t);
	this.flag1 = 1;
	return true;
}

function Shot_Normal_Under_Air_Init( t )
{
	this.Shot_Normal_Air_Init.call(this, t);
	this.flag1 = 1;
	return true;
}

function Shot_Front_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.SetMotion(2010, 0);
	this.count = 0;
	this.flag1 = 0;
	this.flag2 = 0;
	this.flag3 = true;
	this.flag4 = 0;
	this.flag5 = null;
	this.SetSpeed_XY(this.va.x * 0.50000000, null);
	this.keyAction = [
		function ()
		{
			this.count = 0;

			if (this.emotion == 1)
			{
				local t_ = {};
				t_.rot <- 0.00000000;
				this.flag5 = this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_FrontD, t_).weakref();
				this.stateLabel = function ()
				{
					this.VX_Brake(0.50000000);

					if (this.count >= 10)
					{
						this.SetMotion(2010, 2);
						this.stateLabel = function ()
						{
							this.VX_Brake(0.50000000);
						};
					}
				};
			}
			else
			{
				this.stateLabel = function ()
				{
					this.VX_Brake(0.50000000);

					if (this.count >= 4)
					{
						this.SetMotion(2010, 2);
						this.stateLabel = function ()
						{
							this.VX_Brake(0.50000000);
						};
					}
				};
			}
		},
		null,
		function ()
		{
			this.PlaySE(2822);

			if (this.flag5)
			{
				this.flag5.func[1].call(this.flag5);
				this.flag5 = null;
			}
		},
		function ()
		{
			this.count = 0;
			this.team.AddMP(-200, 90);

			switch(this.emotion)
			{
			case 2:
				local t_ = {};
				t_.scale <- 0.25000000;
				t_.rot <- 0.00000000;
				t_.group <- [];
				t_.root <- this.weakref();
				this.SetShot(this.x, this.y, this.direction, this.Shot_FrontB, t_, this.weakref());
				this.hitResult = 1;
				this.stateLabel = function ()
				{
					this.CenterUpdate(0.10000000, null);
					this.VX_Brake(0.10000000);

					if (this.count >= 20)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.VX_Brake(0.50000000);
						};
					}
				};
				break;

			case 1:
				this.hitResult = 1;
				this.stateLabel = function ()
				{
					this.CenterUpdate(0.10000000, null);
					this.VX_Brake(0.10000000);

					if (this.count >= 30)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.VX_Brake(0.50000000);
						};
					}
				};
				break;

			case 0:
				this.flag1 = this.GetTargetAngle(this.target, this.direction);
				this.flag1 = this.Math_MinMax(this.flag1, -30.00000000 * 0.01745329, 30.00000000 * 0.01745329);
				this.flag2 = 15 * 0.01745329;
				this.stateLabel = function ()
				{
					if (this.count % 5 == 1 && this.count <= 16)
					{
						this.hitResult = 1;
						local t_ = {};
						t_.rot <- this.flag1 + this.flag2;
						this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_FrontS, t_);
						local t_ = {};
						t_.rot <- this.flag1 - this.flag2;
						this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_FrontS, t_);
						this.flag2 += 10 * 0.01745329;
					}

					this.CenterUpdate(0.10000000, null);
					this.VX_Brake(0.10000000);

					if (this.count >= 25)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.VX_Brake(0.50000000);
						};
					}
				};
				break;

			default:
				this.stateLabel = function ()
				{
					if (this.count % 5 == 1 && this.count <= 21)
					{
						this.hitResult = 1;
						local t_ = {};
						t_.rot <- this.GetTargetAngle(this.target, this.direction);
						t_.rot = this.Math_MinMax(t_.rot, -20.00000000 * 0.01745329, 20.00000000 * 0.01745329);
						t_.type <- this.flag4;
						this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Front, t_);
						this.flag4++;
					}

					this.CenterUpdate(0.10000000, null);
					this.VX_Brake(0.10000000);

					if (this.count >= 25)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.VX_Brake(0.50000000);
						};
					}
				};
				break;
			}

			this.ChangeEmotion(-1);
		},
		null,
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
	this.hitResult = 1;
	this.SetMotion(2011, 0);
	this.count = 0;
	this.flag1 = 0;
	this.flag2 = 0;
	this.flag3 = true;
	this.flag4 = 0;
	this.flag5 = null;
	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.34999999);
	this.keyAction = [
		function ()
		{
			this.count = 0;

			if (this.emotion == 1)
			{
				local t_ = {};
				t_.rot <- 0.00000000;
				this.flag5 = this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_FrontD, t_).weakref();
				this.stateLabel = function ()
				{
					this.CenterUpdate(0.10000000, null);
					this.VX_Brake(0.10000000);

					if (this.count >= 10)
					{
						this.SetMotion(2011, 2);
						this.stateLabel = function ()
						{
							this.CenterUpdate(0.10000000, null);

							if (this.centerStop * this.centerStop <= 1)
							{
								this.VX_Brake(0.50000000);
							}
							else
							{
								this.VX_Brake(0.10000000);
							}
						};
					}
				};
			}
			else
			{
				this.stateLabel = function ()
				{
					this.CenterUpdate(0.10000000, null);
					this.VX_Brake(0.10000000);

					if (this.count >= 4)
					{
						this.SetMotion(2011, 2);
						this.stateLabel = function ()
						{
							this.CenterUpdate(0.10000000, null);

							if (this.centerStop * this.centerStop <= 1)
							{
								this.VX_Brake(0.50000000);
							}
							else
							{
								this.VX_Brake(0.10000000);
							}
						};
					}
				};
			}
		},
		null,
		function ()
		{
			this.PlaySE(2822);

			if (this.flag5)
			{
				this.flag5.func[1].call(this.flag5);
				this.flag5 = null;
			}
		},
		function ()
		{
			this.count = 0;
			this.team.AddMP(-200, 90);

			switch(this.emotion)
			{
			case 2:
				local t_ = {};
				t_.scale <- 0.25000000;
				t_.rot <- 0.00000000;
				t_.root <- this.weakref();
				t_.group <- [];
				this.SetShot(this.x, this.y, this.direction, this.Shot_FrontB, t_, this.weakref());
				this.stateLabel = function ()
				{
					this.CenterUpdate(0.10000000, null);

					if (this.centerStop * this.centerStop <= 1)
					{
						this.VX_Brake(0.50000000);
					}
					else
					{
						this.VX_Brake(0.10000000);
					}

					if (this.count >= 20)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.CenterUpdate(0.10000000, null);

							if (this.centerStop * this.centerStop <= 1)
							{
								this.VX_Brake(0.50000000);
							}
							else
							{
								this.VX_Brake(0.10000000);
							}
						};
					}
				};
				break;

			case 1:
				this.stateLabel = function ()
				{
					this.CenterUpdate(0.10000000, null);

					if (this.centerStop * this.centerStop <= 1)
					{
						this.VX_Brake(0.50000000);
					}
					else
					{
						this.VX_Brake(0.10000000);
					}

					if (this.count >= 30)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.CenterUpdate(0.10000000, null);

							if (this.centerStop * this.centerStop <= 1)
							{
								this.VX_Brake(0.50000000);
							}
							else
							{
								this.VX_Brake(0.10000000);
							}
						};
					}
				};
				break;

			case 0:
				this.flag1 = this.GetTargetAngle(this.target, this.direction);
				this.flag1 = this.Math_MinMax(this.flag1, -30.00000000 * 0.01745329, 30.00000000 * 0.01745329);
				this.flag2 = 15 * 0.01745329;
				this.stateLabel = function ()
				{
					if (this.count % 5 == 1 && this.count <= 16)
					{
						local t_ = {};
						t_.rot <- this.flag1 + this.flag2;
						this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_FrontS, t_);
						local t_ = {};
						t_.rot <- this.flag1 - this.flag2;
						this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_FrontS, t_);
						this.flag2 += 10 * 0.01745329;
					}

					this.CenterUpdate(0.10000000, null);

					if (this.centerStop * this.centerStop <= 1)
					{
						this.VX_Brake(0.50000000);
					}
					else
					{
						this.VX_Brake(0.10000000);
					}

					if (this.count >= 25)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.CenterUpdate(0.10000000, null);

							if (this.centerStop * this.centerStop <= 1)
							{
								this.VX_Brake(0.50000000);
							}
							else
							{
								this.VX_Brake(0.10000000);
							}
						};
					}
				};
				break;

			default:
				this.stateLabel = function ()
				{
					if (this.count % 5 == 1 && this.count <= 21)
					{
						local t_ = {};
						t_.rot <- this.GetTargetAngle(this.target, this.direction);
						t_.rot = this.Math_MinMax(t_.rot, -20.00000000 * 0.01745329, 20.00000000 * 0.01745329);
						t_.type <- this.flag4;
						this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Front, t_);
						this.flag4++;
					}

					this.CenterUpdate(0.10000000, null);

					if (this.centerStop * this.centerStop <= 1)
					{
						this.VX_Brake(0.50000000);
					}
					else
					{
						this.VX_Brake(0.10000000);
					}

					if (this.count >= 25)
					{
						this.SetMotion(this.motion, this.keyTake + 1);
						this.stateLabel = function ()
						{
							this.CenterUpdate(0.10000000, null);

							if (this.centerStop * this.centerStop <= 1)
							{
								this.VX_Brake(0.50000000);
							}
							else
							{
								this.VX_Brake(0.10000000);
							}
						};
					}
				};
				break;
			}

			this.ChangeEmotion(-1);
		},
		null,
		function ()
		{
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.10000000);
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
		else
		{
			this.VX_Brake(0.10000000);
		}
	};
	return true;
}

function Shot_Charge_Init( t )
{
	this.Shot_Charge_Common(t);
	this.flag2 = {};
	this.flag2.vx <- 4.75000000;
	this.flag2.vy <- 2.75000000;
	this.subState = function ()
	{
	};
}

function Shot_Charge_Fire( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.count = 0;
	this.flag1 = 0;
	this.ChangeEmotion(0);
	this.SetMotion(2020, 0);
	this.keyAction = [
		function ()
		{
			this.PlaySE(2902);

			for( local i = 0; i < 4; i++ )
			{
				local t_ = {};
				t_.rot <- i * 90 * 0.01745329;
				t_.keyTake <- 0;
				this.SetShot(this.x, this.y, this.direction, this.Shot_Charge, t_);
			}
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
		this.Vec_Brake(0.75000000);
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
	this.flag2.cycle <- 0;
	this.subState = function ()
	{
		if (!this.mask){
			this.SummonMask();
			return;
		}
		if (this.count > 10 && this.team.mp > 0)
		{
			switch(this.emotion)
			{
			case 1:
				if (this.count % 3 == 1 && this.count % 30 <= 17 && this.count % 30 > 10)
				{
					foreach( a in this.mask )
					{
						this.BurrageShot_D.call(a);
					}
				}

				break;

			case 0:
				if (this.count % 6 == 1 && this.count % 48 <= 25 && this.count % 48 > 10)
				{
					foreach( a in this.mask )
					{
						this.BurrageShot_S.call(a);
					}
				}

				break;

			case 2:
				if (this.count % 5 == 1)
				{
					foreach( a in this.mask )
					{
						a.BurrageShot_B();
					}
				}

				break;

			default:
				if (this.count % 10 == 1)
				{

					this.mask[this.flag2.cycle].BurrageShot();
					this.flag2.cycle++;

					if (this.flag2.cycle > 2)
					{
						this.flag2.cycle = 0;
					}
				}

				break;
			}
		}
	};
	return true;
}

function Okult_Init( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.SetMotion(2500, 5);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.count = 0;
	this.keyAction = [
		function ()
		{
			this.SetMotion(2500, 1);
			this.team.AddMP(-200, 120);
			this.team.op_stop = 300;
			this.team.op_stop_max = 300;
			this.SetEffect(this.point0_x, this.point0_y, this.direction, this.EF_ChargeO, {});
			this.PlaySE(2925);
			this.stateLabel = function ()
			{
				if (this.hitResult & 16)
				{
					this.Okult_Catch(null);
					return;
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
			};
		},
		this.EndtoFreeMove,
		function ()
		{
			this.keyAction[0].call(this);
		},
		function ()
		{
			this.keyAction[0].call(this);
		},
		function ()
		{
			this.keyAction[0].call(this);
		}
	];
}

function Okult_Catch( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(2501, 0);
	this.atk_id = 524288;
	this.SetTimeStop(45);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.faceMask = false;
	this.BackColorFilter(0.50000000, 0.00000000, 0.00000000, 0.00000000, 2);
	this.SetFreeObject(this.x, this.y - 125, 1.00000000, this.Occult_Mark, {});
	this.PlaySE(2926);
	this.keyAction = [
		function ()
		{
			this.PlaySE(2927);
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.Occult_Mask, {});
		},
		function ()
		{
			this.BackColorFilterOut(0.50000000, 0.00000000, 0.00000000, 0.00000000, 2);
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.Occult_Face, {});
		}
	];
	this.stateLabel = function ()
	{
	};
}

function Okult_B_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(2502, 0);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.PlaySE(2927);
	this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.Occult_Mask, {});
	this.keyAction = [
		function ()
		{
			this.BackColorFilterOut(0.50000000, 0.00000000, 0.00000000, 0.00000000, 2);
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.Occult_Face, {});
		}
	];
	this.stateLabel = function ()
	{
	};
}

function Okult_InitB( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.hitResult = 1;
	this.faceMask = true;
	this.count = 0;
	this.flag1 = ::manbow.Actor2DProcGroup();

	if (this.command.rsv_y == 0)
	{
		this.flag2 = 0;
	}

	if (this.command.rsv_y > 0)
	{
		this.flag2 = 25 * 0.01745329;
	}

	if (this.command.rsv_y < 0)
	{
		this.flag2 = -25 * 0.01745329;
	}

	this.SetMotion(2502, 0);
	this.count = 0;
	this.PlaySE(2934);

	for( local i = 0; i < 360; i = i + 45 )
	{
		local t_ = {};
		t_.rot <- i * 0.01745329;
		t_.pos <- this.Vector3();
		t_.shotRot <- this.flag2;
		t_.pos.x = 100;
		t_.pos.RotateByRadian(t_.rot);
		t_.priority <- t_.pos.y >= 0 ? 200 : 180;
		this.flag1.Add(this.SetShot(this.x + t_.pos.x * this.direction, this.y - 100 + t_.pos.y * 0.25000000, this.direction, this.Okult_Shot, t_));
	}

	this.lavelClearEvent = function ()
	{
		this.flag1.Foreach(function ()
		{
			this.func[0].call(this);
		});
	};
	this.keyAction = [
		function ()
		{
			this.PlaySE(2929);
			this.team.AddMP(-200, 120);
			this.team.op_stop = 300;
			this.team.op_stop_max = 300;
			this.flag1.Foreach(function ()
			{
				this.func[1].call(this);
			});
			this.lavelClearEvent = null;
		},
		function ()
		{
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.75000000);
	};
	return true;
}

function Okult_InitB_Air( t )
{
	this.LabelClear();
	this.GetFront();
	this.HitReset();
	this.hitResult = 1;
	this.faceMask = true;
	this.count = 0;
	this.flag1 = ::manbow.Actor2DProcGroup();

	if (this.command.rsv_y == 0)
	{
		this.flag2 = 0;
	}

	if (this.command.rsv_y > 0)
	{
		this.flag2 = 25 * 0.01745329;
	}

	if (this.command.rsv_y < 0)
	{
		this.flag2 = -25 * 0.01745329;
	}

	this.SetMotion(2503, 0);
	this.SetSpeed_XY(this.va.x * 0.25000000, this.va.y * 0.25000000);
	this.count = 0;
	this.PlaySE(2934);

	for( local i = 0; i < 360; i = i + 45 )
	{
		local t_ = {};
		t_.rot <- i * 0.01745329;
		t_.pos <- this.Vector3();
		t_.shotRot <- this.flag2;
		t_.pos.x = 100;
		t_.pos.RotateByRadian(t_.rot);
		t_.priority <- t_.pos.y >= 0 ? 200 : 180;
		this.flag1.Add(this.SetShot(this.x + t_.pos.x * this.direction, this.y - 100 + t_.pos.y * 0.25000000, this.direction, this.Okult_Shot, t_));
	}

	this.lavelClearEvent = function ()
	{
		this.flag1.Foreach(function ()
		{
			this.func[0].call(this);
		});
	};
	this.keyAction = [
		function ()
		{
			this.PlaySE(2929);
			this.team.AddMP(-200, 120);
			this.team.op_stop = 300;
			this.team.op_stop_max = 300;
			this.flag1.Foreach(function ()
			{
				this.func[1].call(this);
			});
			this.lavelClearEvent = null;
		},
		function ()
		{
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				if (this.centerStop == 0)
				{
					this.VX_Brake(0.50000000);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.10000000, null);

		if (this.centerStop == 0)
		{
			this.VX_Brake(0.50000000);
		}
	};
	return true;
}

function SP_A_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.atk_id = 1048576;
	this.SetMotion(3000, 0);
	this.ChangeEmotion(2);
	this.flag1 = 0;
	this.flag2 = {};
	this.flag2.vx <- 10.00000000;
	this.flag2.vy <- -16.00000000;
	this.flag2.count <- 30;
	this.SetSpeed_XY(this.va.x * 0.20000000, this.va.y * 0.20000000);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 120);
			this.centerStop = -2;
			this.SetSpeed_XY(this.flag2.vx * this.direction, this.flag2.vy);
			this.count = 0;
			local t_ = {};
			t_.rot <- this.atan2(this.va.y, this.va.x * this.direction);
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SPShot_A, t_);
			this.PlaySE(2900);
			this.subState = function ()
			{
				if (this.y < this.centerY)
				{
					this.AddSpeed_XY(0.00000000, 0.75000000);
				}

				if (this.va.y > 10.00000000)
				{
					this.SetSpeed_XY(null, 10.00000000);
				}

				if (this.count % 2 == 1)
				{
					this.SetFreeObject(this.point0_x + 75 - this.rand() % 150, this.point0_y + 75 - this.rand() % 150, this.direction, this.SPShot_A_Aura, {});
				}
			};
			this.stateLabel = function ()
			{
				if (this.count % 4 == 0 && this.count < 21)
				{
					local t_ = {};
					t_.rot <- this.atan2(this.va.y, this.va.x * this.direction);
					this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SPShot_A, t_);
				}

				this.HitCycleUpdate(8);
				this.subState();

				if (this.va.y > 0.00000000)
				{
					this.count = 0;
					this.SetMotion(this.motion, this.keyTake + 1);
					this.stateLabel = function ()
					{
						this.HitCycleUpdate(8);
						this.subState();

						if (this.va.y > 0.00000000 && this.y > this.centerY - 75)
						{
							this.HitTargetReset();
							this.SetMotion(this.motion, 4);
							this.stateLabel = function ()
							{
								this.VY_Brake(0.50000000);
								this.VX_Brake(0.50000000);
								this.SetSpeed_XY(null, this.va.y < 1.00000000 ? 1.00000000 : null);
							};
						}
					};
				}
			};
		},
		null,
		function ()
		{
		},
		null,
		function ()
		{
			this.stateLabel = function ()
			{
				this.VX_Brake(0.25000000);
			};
		}
	];
	return true;
}

function SP_B_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.ChangeEmotion(2);
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.flag5 = t.rush;

	if (this.capture)
	{
		this.SetMotion(3011, 0);
		this.GetFront();
		this.keyAction = [
			function ()
			{
				this.team.AddMP(-200, 120);
				this.SetSpeed_XY(-8.00000000 * this.direction, null);
				this.stateLabel = function ()
				{
					this.VX_Brake(0.25000000);
				};
				this.PlaySE(2909);
				this.SetShot(this.target.x, this.target.y, -this.direction, this.SPShot_B_Pull, {});
				this.capture = null;
			}
		];
	}
	else
	{
		this.SetMotion(3010, 0);
		this.flag1 = 0.00000000;
		this.keyAction = [
			function ()
			{
				this.team.AddMP(-200, 120);
				this.PlaySE(2907);
				this.count = 0;
				local t_ = {};
				t_.rot <- this.flag1;
				this.SetShot(this.x, this.y, this.direction, this.SPShot_B_Web, t_);
			},
			function ()
			{
				this.stateLabel = function ()
				{
					this.VX_Brake(0.50000000);

					if (this.capture && (this.command.rsv_k2 > 0 || this.flag5 && this.command.rsv_k0 > 0))
					{
						local t_ = {};
						t_.rush <- false;
						this.SP_B_Init(t_);
						return;
					}
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
			this.VX_Brake(0.50000000);
		};
	}

	return true;
}

function SP_C_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.count = 0;
	this.flag1 = 0;
	this.ChangeEmotion(0);
	this.SetMotion(3020, 0);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 120);
			this.PlaySE(2902);

			for( local i = 0; i < 4; i++ )
			{
				local t_ = {};
				t_.rot <- i * 90 * 0.01745329;
				t_.keyTake <- 0;
				this.SetShot(this.x, this.y, this.direction, this.SPShot_C, t_);
			}
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
		this.Vec_Brake(0.75000000);
	};
	return true;
}

function SP_D_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.ChangeEmotion(0);
	this.count = 0;
	this.flag1 = this.Vector3();
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.flag1.x = 400;
	this.flag1.y = 0;

	if (this.shadow)
	{
		this.SetMotion(3031, 0);
		this.keyAction = [
			function ()
			{
				if (this.shadow)
				{
					this.shadow.func[1].call(this.shadow);
				}
			}
		];
	}
	else
	{
		this.SetMotion(3030, 0);
		this.keyAction = [
			function ()
			{
				this.team.AddMP(-200, 120);
				this.shadow = this.SetShot(this.x + this.flag1.x * this.direction, this.y + this.flag1.y, this.direction, this.SPShot_D_Shadow, {}).weakref();
			},
			function ()
			{
			}
		];
	}

	return true;
}

function SP_E_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.SetMotion(3040, 0);
	this.SetSpeed_XY(this.va.x * 0.25000000, this.va.y * 0.25000000);
	this.ChangeEmotion(1);

	if (this.centerStop * this.centerStop >= 4 && this.y < this.centerY)
	{
		this.flag1 = -0.02500000;
		this.flag2 = 60;
	}
	else
	{
		this.flag1 = -0.02000000;
		this.flag2 = 30;
	}

	this.keyAction = [
		function ()
		{
		},
		function ()
		{
			this.team.AddMP(-200, 120);
			this.SetSpeed_XY(-6.00000000 * this.direction, -4.00000000);
			this.centerStop = -2;
			local t_ = {};
			t_.rot <- this.flag2 * 0.01745329;
			t_.addRot <- this.flag1;
			this.SetShot(this.point0_x, this.point0_y, this.direction, this.SPShot_E, t_);
			this.PlaySE(2905);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.10000000);
				this.VX_Brake(0.05000000);
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
				else
				{
					this.VX_Brake(0.05000000);
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

function SP_F_Init( t )
{
	this.LabelClear();
	this.ChangeEmotion(1);
	this.HitReset();
	this.hitResult = 1;
	this.SetMotion(3050, 0);
	this.count = 0;
	this.flag1 = 80;
	this.SetSpeed_XY(this.va.x * 0.25000000, this.va.y * 0.15000001);
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 120);
			this.PlaySE(2917);

			for( local i = 0; i < 3; i++ )
			{
				local t_ = {};
				t_.v <- 17.50000000;
				t_.rot <- (-this.flag1 + i * 10) * 0.01745329;
				t_.count <- 10 + i * 6;
				t_.se <- false;

				if (i == 0)
				{
					t_.se = true;
				}

				this.SetShot(this.x + 100 * this.cos(t_.rot) * this.direction, this.y + 100 * this.sin(t_.rot), this.direction, this.SPShot_F, t_);
			}
		},
		function ()
		{
			this.HitTargetReset();
			this.PlaySE(2917);

			for( local i = 0; i < 3; i++ )
			{
				local t_ = {};
				t_.v <- 17.50000000;
				t_.rot <- (-this.flag1 + i * 10) * 0.01745329;
				t_.count <- 10 + i * 6;
				t_.se <- false;

				if (i == 0)
				{
					t_.se = true;
				}

				this.SetShot(this.x - 100 * this.cos(t_.rot) * this.direction, this.y + 100 * this.sin(t_.rot), -this.direction, this.SPShot_F, t_);
			}
		},
		function ()
		{
			this.AjustCenterStop();
			this.stateLabel = function ()
			{
				this.VX_Brake(0.20000000);
			};
		}
	];
	this.stateLabel = function ()
	{
		this.CenterUpdate(0.02500000, null);
		this.VX_Brake(0.20000000);
	};
	return true;
}

function SP_G_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.hitResult = 1;
	this.SetMotion(3060, 0);
	this.count = 0;
	this.flag2 = [];
	this.flag3 = {};
	this.flag3.rot <- 0.00000000;
	this.flag3.range <- 0.00000000;
	this.flag4 = false;
	this.SetSpeed_XY(this.va.x * 0.50000000, this.va.y * 0.50000000);
	this.stateLabel = function ()
	{
		if (this.centerStop == 0)
		{
			this.VX_Brake(0.50000000);
		}
		else
		{
			this.VX_Brake(0.05000000);
		}

		this.CenterUpdate(0.10000000, 5.00000000);
	};
	this.subState = function ()
	{
		this.flag3.rot += 4.00000000 * 0.01745329;
		this.flag3.range += (125 - this.flag3.range) * 0.30000001;

		foreach( a in this.flag2 )
		{
			if (a)
			{
				a.Warp(this.point0_x + this.flag3.range * this.cos(this.flag3.rot + a.initTable.rot) * this.direction, this.point0_y + this.flag3.range * 0.20000000 * this.sin(this.flag3.rot + a.initTable.rot));

				if (a.drawPriority == 180)
				{
					if (this.sin(this.flag3.rot + a.initTable.rot) >= 0.00000000)
					{
						a.DrawActorPriority(200);
					}
				}
				else if (this.sin(this.flag3.rot + a.initTable.rot) <= 0.00000000)
				{
					a.DrawActorPriority(180);
				}
			}
		}
	};
	this.keyAction = [
		function ()
		{
			this.team.AddMP(-200, 120);
			this.PlaySE(2921);
			this.count = 0;
			this.flag2 = [];
			local r_ = this.rand() % 360 * 0.01745329;
			local bet_ = this.rand() % 6;

			for( local i = 0; i < 6; i++ )
			{
				local t_ = {};
				t_.rot <- i * 60 * 0.01745329 + r_;
				t_.keyTake <- i % 3;
				t_.hit <- false;

				if (i == bet_)
				{
					t_.hit = true;
				}

				this.flag2.append(this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SPShot_G_Mask, t_).weakref());
			}

			this.ChangeEmotion(-1);
			this.stateLabel = function ()
			{
				this.VX_Brake(0.01000000);
				this.CenterUpdate(0.10000000, 5.00000000);

				if (this.subState)
				{
					this.subState();
				}

				if (this.count >= 25)
				{
					if (this.count >= 120 || this.input.b2 == 0 || ::battle.state != 8)
					{
						this.SetMotion(this.motion, 2);
						this.stateLabel = function ()
						{
							this.VX_Brake(0.05000000);
							this.CenterUpdate(0.10000000, 5.00000000);

							if (this.subState)
							{
								this.subState();
							}
						};
					}
				}
			};
		},
		null,
		function ()
		{
			this.PlaySE(2922);
			local max_ = 0.00000000;
			local maxNum_ = 0;

			foreach( val, a in this.flag2 )
			{
				if (a)
				{
					local c_ = this.cos(this.flag3.rot + a.initTable.rot);

					if (c_ > max_)
					{
						max_ = c_;
						maxNum_ = val;
					}
				}
			}

			foreach( val, a in this.flag2 )
			{
				if (a)
				{
					if (val == maxNum_)
					{
						a.func[1].call(a);

						if (a.motion == 6064)
						{
							this.flag4 = true;
						}
					}
					else
					{
						a.func[2].call(a);
					}
				}
			}

			this.SetSpeed_XY(0.00000000, 0.00000000);
			this.stateLabel = function ()
			{
			};
			this.subState = null;
			this.flag2 = null;
		}
	];
	return true;
}

function Spell_A_Func( t )
{
	this.spellA_Charge = 0;

	if (this.spellA_Aura)
	{
		this.spellA_Aura.func[0].call(this.spellA_Aura);
		this.spellA_Aura = null;
	}

	this.spellA_Aura = this.SetFreeObject(this.x, this.y, this.direction, this.SpellShot_A_Aura, {}).weakref();
}

function Spell_A_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(4000, 0);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.flag2 = 0;
	this.spellA_Charge = 0;
	this.func = [
		function ()
		{
			this.SetMotion(this.motion, 2);

			if (this.flag1)
			{
				this.flag1.SetMotion(4009, 3);
			}

			this.stateLabel = function ()
			{
				if (this.subState && this.subState())
				{
					return;
				}

				this.flag2 -= 1.50000000;

				if (this.flag2 < -7.00000000)
				{
					this.flag2 = -7.00000000;
				}

				if (this.keyTake == 3 && this.input.y > 0)
				{
					this.func[1].call(this);
					return;
				}
			};
		},
		function ()
		{
			this.SetMotion(this.motion, 4);

			if (this.flag1)
			{
				this.flag1.SetMotion(4009, 1);
			}

			this.stateLabel = function ()
			{
				if (this.subState && this.subState())
				{
					return;
				}

				this.flag2 += 1.50000000;

				if (this.flag2 > 7.00000000)
				{
					this.flag2 = 7.00000000;
				}

				if (this.keyTake == 5 && this.input.y < 0)
				{
					this.func[0].call(this);
					return;
				}
			};
		}
	];
	this.subState = function ()
	{
		if (this.y > this.centerY)
		{
			this.centerStop = 2;
		}
		else
		{
			this.centerStop = -2;
		}

		if (this.y < ::battle.scroll_top && this.flag2 < 0.00000000)
		{
			this.SetSpeed_XY(this.va.x, 0.00000000);
		}
		else
		{
			this.SetSpeed_XY(this.va.x, this.flag2);
		}

		if (this.count % 4 == 0)
		{
			local t_ = {};
			t_.rot <- this.atan2(this.va.y, this.va.x * this.direction);
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.SPShot_A, t_);
		}

		if (this.count % 2 == 1)
		{
			this.SetFreeObject(this.point0_x + 75 - this.rand() % 150, this.point0_y + 75 - this.rand() % 150, this.direction, this.SPShot_A_Aura, {});
		}

		if (this.count >= 120)
		{
			if (this.flag1)
			{
				this.flag1.func();
				this.flag1 = null;
			}

			this.SetMotion(this.motion, 6);
			this.stateLabel = function ()
			{
				this.VY_Brake(0.50000000);
				this.VX_Brake(0.25000000);
				this.SetSpeed_XY(null, this.va.y < 1.00000000 ? 1.00000000 : null);
			};
			return true;
		}

		return false;
	};
	this.keyAction = [
		function ()
		{
			if (this.spellA_Aura)
			{
				this.spellA_Aura.func[0].call(this.spellA_Aura);
				this.spellA_Aura = null;
			}

			this.UseSpellCard(60, -this.team.sp_max);
		},
		function ()
		{
			this.hitResult = 1;
			local t_ = {};
			t_.scale <- 1.00000000 + this.spellA_Charge * 0.20000000;
			t_.rate <- 1.00000000;
			this.flag1 = this.SetShot(this.point0_x, this.point0_y, this.direction, this.SpellShot_A, t_).weakref();
			this.count = 0;
			this.PlaySE(2951);
			this.SetSpeed_Vec(12.50000000, -15 * 0.01745329, this.direction);
			this.flag2 = this.va.y;
			this.centerStop = -2;
			this.func[0].call(this);
		},
		function ()
		{
			if (this.flag1)
			{
				this.flag1.SetMotion(4009, 0);
			}
		},
		null,
		function ()
		{
			if (this.flag1)
			{
				this.flag1.SetMotion(4009, 2);
			}
		}
	];
	return true;
}

function Spell_B_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(4010, 0);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.keyAction = [
		function ()
		{
			this.UseSpellCard(60, -this.team.sp_max);
		},
		function ()
		{
			this.count = 0;
			this.PlaySE(2953);
			this.hitResult = 1;
			local t_ = {};

			if (this.emotion >= 0)
			{
				t_.type <- this.emotion;
				this.ChangeEmotion(-1);
			}
			else
			{
				t_.type <- 3;
			}

			t_.rate <- this.atkRate_Pat;
			this.SetShot(this.point0_x, this.point0_y, this.direction, this.SpellShot_B, t_);
			this.stateLabel = function ()
			{
				if (this.count >= 40)
				{
					this.SetMotion(this.motion, 3);
					this.stateLabel = null;
				}
			};
		}
	];
	return true;
}

function Spell_C_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(4020, 0);
	this.count = 0;
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.AjustCenterStop();
	this.keyAction = [
		function ()
		{
			this.UseSpellCard(60, -this.team.sp_max);
		},
		function ()
		{
			this.hitResult = 1;
			this.count = 0;
			this.PlaySE(2955);
			local t_ = {};
			t_.rate <- this.atkRate_Pat;
			this.SetShot(this.target.x, this.centerY, this.direction, this.SpellShot_C_Pilar, t_);
			this.stateLabel = function ()
			{
				if (this.count >= 80)
				{
					this.stateLabel = null;
					this.SetMotion(this.motion, this.keyTake + 1);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
	};
	return true;
}

function Spell_Climax_Init( t )
{
	this.LabelClear();
	this.HitReset();
	this.SetMotion(4900, 0);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.flag1 = null;
	this.flag2 = false;
	this.keyAction = [
		function ()
		{
			this.UseClimaxSpell(60, "���\x2592��\x253c���A�^�V�A�L���C��\x2566�H��");
			this.PlaySE(2935);
			::battle.enableTimeUp = false;
			this.lavelClearEvent = function ()
			{
				this.lastword.Deactivate();
				::battle.enableTimeUp = true;
			};
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.count == 60)
				{
					this.keyAction[1].call(this);
					this.SetMotion(4900, 2);
					this.stateLabel = function ()
					{
						if (this.hitResult & 1)
						{
							this.Spell_Climax_Hit(null);
							return;
						}
					};
				}
			};
		},
		function ()
		{
			this.BackFadeIn(0.00000000, 0.00000000, 0.00000000, 0);
			this.PlaySE(2980);
		},
		function ()
		{
			this.flag1 = this.SetFreeObject(this.point0_x, this.point0_y, this.direction, this.Climax_Shot, {}).weakref();
			this.SetParent.call(this.flag1, this, this.flag1.x - this.x, this.flag1.y - this.y);
			this.lavelClearEvent = function ()
			{
				this.lastword.Deactivate();
				::battle.enableTimeUp = true;

				if (this.flag1)
				{
					this.flag1.func[0].call(this.flag1);
				}
			};
		},
		function ()
		{
			this.lavelClearEvent = function ()
			{
				this.lastword.Deactivate();
				::battle.enableTimeUp = true;
			};

			if (this.flag1)
			{
				this.flag1.func[0].call(this.flag1);
			}
		},
		function ()
		{
			this.SetFreeObject(this.point0_x, this.point0_y, this.direction, function ( t_ )
			{
				this.SetMotion(7900, 4);
				this.stateLabel = function ()
				{
					this.AddSpeed_XY(0.00000000, 0.50000000);
					this.rz += 2.50000000 * 0.01745329;
					this.alpha -= 0.05000000;

					if (this.alpha <= 0.00000000)
					{
						this.ReleaseActor();
					}
				};
			}, {});
			this.stateLabel = null;
		}
	];
	this.stateLabel = function ()
	{
		this.SetSpeed_XY(0.00000000, 0.00000000);
	};
	return true;
}

function Spell_Climax_Hit( t )
{
	this.LabelReset();
	this.HitReset();
	this.SetMotion(4901, 0);
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.count = 0;
	::battle.enableTimeUp = false;
	this.flag2 = null;
	this.target.DamageGrab_Common(300, 0, this.target.direction);
	this.stateLabel = function ()
	{
		if (this.count == 30)
		{
		}

		if (this.count == 90)
		{
			this.ClearMask();
			this.SetMotion(4901, 4);

			if (this.flag1)
			{
				this.flag1.func[3].call(this.flag1);
			}

			this.target.DamageGrab_Common(308, 0, this.target.direction);
			this.BackFadeOut(0.00000000, 0.00000000, 0.00000000, 1);
			this.flag2 = this.SetFreeObject(600, 360, 1.00000000, this.Climax_Cut, {}).weakref();
			this.PlaySE(2931);
		}

		if (this.count == 190 + 60)
		{
			this.PlaySE(2932);
			this.flag2.func[1].call(this.flag2);
			local t_ = {};
			t_.count <- 120;
			t_.priority <- 520;
			this.SetEffect(640, 360, 1.00000000, this.EF_SpeedLine, t_);
		}

		if (this.count == 280 + 60)
		{
			this.PlaySE(2933);
			this.flag2.func[0].call(this.flag2);
			this.SetMotion(4903, 0);
			this.x = 640;
			this.y = this.centerY;
			this.target.x = 640;
			this.target.y = this.y;
			this.camera.ForceTarget();
			this.centerStop = -2;
			this.SetSpeed_XY(-20.00000000 * this.direction, -12.00000000);
			this.KnockBackTarget(-this.direction);
			this.FadeIn(1.00000000, 1.00000000, 1.00000000, 30);
			this.BackFadeIn(1.00000000, 1.00000000, 1.00000000, 30);
			this.count = 0;
			this.stateLabel = function ()
			{
				this.Vec_Brake(5.00000000, 1.00000000);

				if (this.count == 60)
				{
					::battle.enableTimeUp = true;
					this.SetSpeed_XY(this.va.x * 2.00000000, this.va.y * 2.00000000);
					this.SetMotion(4903, 2);
					this.stateLabel = function ()
					{
						this.AddSpeed_XY(0.00000000, 0.25000000);
					};
				}
			};
		}
	};
}

