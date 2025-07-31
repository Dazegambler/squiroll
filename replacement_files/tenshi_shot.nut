function Drop_Stone( t )
{
	this.SetMotion(0, 3);
	this.DrawActorPriority(188);
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, 0.50000000);
		this.alpha = this.red = this.green = this.blue -= 0.05000000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Foot_Stone( t )
{
	this.SetMotion(0, 2);
	this.DrawActorPriority(188);
	this.SetParent(this.owner, 0, 0);
	this.func = [
		function ()
		{
			if (this.isVisible)
			{
				this.isVisible = false;
				this.SetFreeObject(this.x, this.y, this.direction, this.Drop_Stone, {});
				this.stateLabel = function ()
				{
					if (this.isVisible)
					{
						if (this.owner.centerStop * this.owner.centerStop > 2 && this.owner.motion != 2025)
						{
							this.func[0].call(this);
						}
					}
					else if (this.team.current == this.owner && this.owner.centerStop * this.owner.centerStop <= 1)
					{
						this.func[1].call(this);
					}
				};
			}
		},
		function ()
		{
			if (this.isVisible == false)
			{
				this.direction = this.owner.direction;
				this.isVisible = true;
				this.SetMotion(0, 1);
				this.stateLabel = function ()
				{
					if (this.isVisible)
					{
						if (this.owner.centerStop * this.owner.centerStop > 2 && this.owner.motion != 2025)
						{
							this.func[0].call(this);
						}
					}
					else if (this.team.current == this.owner && this.owner.centerStop * this.owner.centerStop <= 1)
					{
						this.func[1].call(this);
					}
				};
			}
		},
		function ()
		{
			if (this.isVisible == false)
			{
				this.direction = this.owner.direction;
				this.isVisible = true;
				this.SetMotion(0, 1);
				this.Warp(this.owner.x, this.owner.y);
			}

			this.stateLabel = function ()
			{
				if (this.owner.IsDamage())
				{
					this.func[0].call(this);
					return;
				}

				if (this.owner.centerStop * this.owner.centerStop <= 1)
				{
					this.stateLabel = function ()
					{
						if (this.isVisible)
						{
							if (this.owner.centerStop * this.owner.centerStop > 2 && this.owner.motion != 2025)
							{
								this.func[0].call(this);
							}
						}
						else if (this.owner.centerStop * this.owner.centerStop <= 1)
						{
							this.func[1].call(this);
						}
					};
				}
			};
		},
		function ()
		{
			this.isVisible = false;
			this.stateLabel = function ()
			{
				if (this.isVisible)
				{
					if (this.owner.centerStop * this.owner.centerStop > 2 && this.owner.motion != 2025)
					{
						this.func[0].call(this);
					}
				}
				else if (this.owner.centerStop * this.owner.centerStop <= 1)
				{
					this.func[1].call(this);
				}
			};
		},
		function ()
		{
			this.isVisible = false;
			this.stateLabel = function ()
			{
			};
		},
		function ()
		{
			this.isVisible = false;
			this.stateLabel = function ()
			{
				if (this.owner == this.team.current)
				{
					this.func[1].call(this);
				}
			};
		}
	];

	if (this.team.current == this.owner)
	{
		this.stateLabel = function ()
		{
			if (this.isVisible)
			{
				if (this.owner.centerStop * this.owner.centerStop > 2 && this.owner.motion != 2025)
				{
					this.func[0].call(this);
				}
			}
			else if (this.owner.centerStop * this.owner.centerStop <= 1)
			{
				this.func[1].call(this);
			}
		};
	}
	else
	{
		this.func[4].call(this);
	}
}

function Shot_Dash( t )
{
	this.SetMotion(1310, 3);
	this.SetParent(this.owner, 0, 0);
	this.SetSpeed_XY(12.50000000 * this.direction, 0.00000000);
	this.cancelCount = 3;
	this.atk_id = 8192;
	this.func = [
		function ()
		{
			this.SetParent(null, 0, 0);
			this.SetMotion(1310, 5);
			this.stateLabel = function ()
			{
				this.alpha = this.green = this.blue -= 0.10000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.VX_Brake(0.60000002, 1.00000000 * this.direction);
	};
}

function Shot_Normal( t )
{
	this.SetMotion(2009, 0);
	this.rz = t.rot;
	this.SetCollisionRotation(0, 0, this.rz);
	this.SetSpeed_Vec(5.00000000, this.rz, this.direction);
	this.cancelCount = 1;
	this.atk_id = 16384;
	this.Warp(this.x + this.va.x * 5, this.y + this.va.y * 5);
	this.flag1 = null;
	this.flag2 = false;
	this.func = function ()
	{
		this.SetSpeed_XY(this.va.x * 0.10000000, this.va.y * 0.10000000);
		this.SetMotion(this.motion, 2);

		if (this.flag1)
		{
			this.flag1.ReleaseActor();
		}

		this.stateLabel = function ()
		{
			this.AddSpeed_XY(0.00000000, 0.50000000);
			this.rz += (-90 * 0.01745329 - this.rz) * 0.07500000;
			this.alpha = this.green = this.blue = this.red -= 0.07500000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	};
	this.stateLabel = function ()
	{
		if (this.IsScreen(200) || this.Damage_ConvertOP(this.x, this.y, 3))
		{
			if (this.flag1)
			{
				this.flag1.ReleaseActor();
			}

			this.ReleaseActor();
			return true;
		}

		this.Vec_Brake(1.00000000, 1.50000000);
		this.count++;

		if (this.count >= this.initTable.wait)
		{
			local t_ = {};
			t_.rot <- this.rz;
			this.flag1 = this.SetShot(this.x, this.y, this.direction, this.Shot_Normal_Trail, t_, this.weakref()).weakref();
			this.SetMotion(this.motion, 1);
			this.count = 0;
			this.SetSpeed_Vec(8.00000000, this.rz, this.direction);
			this.stateLabel = this.subState;
			return;
		}
	};
	this.subState = function ()
	{
		if (this.IsScreen(200) || this.Damage_ConvertOP(this.x, this.y, 3))
		{
			if (this.flag1)
			{
				this.flag1.ReleaseActor();
			}

			this.ReleaseActor();
			return true;
		}

		if (this.hitCount >= 4 || this.cancelCount <= 0 || this.grazeCount >= 3)
		{
			this.func();
			return true;
		}

		if (this.hitResult)
		{
			if (this.HitCycleUpdate(3))
			{
				this.SetSpeed_Vec(8.00000000, this.rz, this.direction);
			}
			else if (this.hitInterval > 0 && this.hitTarget.len() > 0)
			{
				this.SetSpeed_Vec(1.00000000, this.rz, this.direction);
			}
		}

		return false;
	};
}

function Shot_Normal_Trail( t )
{
	this.DrawActorPriority(199);
	this.SetMotion(2009, 3);
	this.rz = t.rot;
	this.SetCollisionScaling(this.sx, this.sy, 1.00000000);
	this.SetCollisionRotation(0, 0, this.rz);
	this.hitOwner = this.initTable.pare.weakref();
	this.SetParent(this.initTable.pare, 0, 0);
	this.stateLabel = function ()
	{
		if (this.hitOwner)
		{
			if (this.hitOwner.count == 0)
			{
				this.sx += 0.04000000;
			}
		}

		this.SetCollisionScaling(this.sx, this.sy, 1.00000000);
	};
}

function Shot_FrontTrail( t )
{
	this.SetMotion(2019, 3);
	this.stateLabel = function ()
	{
		this.sx = this.sy += 0.05000000;
		this.alpha = this.green = this.blue -= 0.05000000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Shot_FrontTrail_R( t )
{
	this.SetMotion(2019, 4);
	this.stateLabel = function ()
	{
		this.sx = this.sy += 0.05000000;
		this.alpha = this.green = this.blue -= 0.05000000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Shot_Front( t )
{
	this.SetMotion(2019, 0);
	this.SetSpeed_Vec(20.00000000, t.rot, this.direction);
	this.cancelCount = 3;
	this.atk_id = 65536;
	this.hitCount = 0;
	this.flag1 = this.Vector3();
	this.func = function ()
	{
		this.SetSpeed_XY(0.00000000, 0.00000000);
		this.stateLabel = function ()
		{
			this.alpha = this.green = this.blue -= 0.10000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
		this.SetMotion(2019, 2);
	};
	this.subState = function ()
	{
		this.count++;

		if (this.count % 4 == 1)
		{
			this.SetFreeObject(this.x, this.y, this.direction, this.Shot_FrontTrail, {});
		}

		if (this.cancelCount <= 0 || ::battle.state != 8)
		{
			this.func();
		}
	};
	this.stateLabel = function ()
	{
		if (this.Damage_ConvertOP(this.x, this.y, 10))
		{
			this.ReleaseActor();
			return true;
		}

		if (this.hitCount < 3)
		{
			this.HitCycleUpdate(2);
		}

		if (this.IsScreen(300))
		{
			this.PlaySE(4213);

			if (this.hitCount <= 0 && this.grazeCount <= 0)
			{
				this.hitCount = 0;
				this.stateLabel = function ()
				{
					if (this.Damage_ConvertOP(this.x, this.y, 10))
					{
						this.ReleaseActor();
						return true;
					}

					if (this.hitCount < 3)
					{
						this.HitCycleUpdate(2);
					}

					this.flag1.x = this.owner.x - this.x;
					this.flag1.y = this.owner.y - 25 - this.y;

					if (this.flag1.Length() <= 50)
					{
						this.owner.sword = null;
						this.owner.Shot_FrontCatch_Init(null);
						this.ReleaseActor();
						return;
					}

					this.flag1.SetLength(12.50000000);
					this.SetSpeed_XY(this.flag1.x, this.flag1.y);
					this.subState();
				};
				return;
			}
			else
			{
				this.callbackGroup = 0;
				this.subState = function ()
				{
					this.count++;

					if (this.count % 4 == 1)
					{
						this.SetFreeObject(this.x, this.y, this.direction, this.Shot_FrontTrail_R, {});
					}

					if (::battle.state != 8)
					{
						this.func();
					}
				};
				this.stateLabel = function ()
				{
					if (this.Damage_ConvertOP(this.x, this.y, 10))
					{
						this.ReleaseActor();
						return true;
					}

					this.flag1.x = this.owner.x - this.x;
					this.flag1.y = this.owner.y - 25 - this.y;

					if (this.flag1.Length() <= 50)
					{
						this.owner.sword = null;
						this.owner.Shot_FrontCatch_Init(null);
						this.ReleaseActor();
						return;
					}

					this.flag1.SetLength(12.50000000);
					this.SetSpeed_XY(this.flag1.x, this.flag1.y);
					this.subState();
				};
				return;
			}
		}

		this.subState();
	};
}

function Shot_Barrage( t )
{
	this.SetMotion(2026, t.type);
	local func_ = function ()
	{
		this.ReleaseActor();
	};
	this.rz = t.rot;
	this.SetSpeed_Vec(15.00000000, this.rz, this.direction);
	this.keyAction = this.ReleaseActor;
	this.cancelCount = 1;
	this.atk_id = 262144;
	this.subState = function ()
	{
		if (this.Vec_Brake(0.75000000, 3.00000000))
		{
			this.subState = function ()
			{
			};
		}
	};
	this.func = function ()
	{
		this.SetMotion(2027, this.keyTake);
		this.stateLabel = function ()
		{
			this.sy *= 0.92000002;
			this.alpha -= 0.10000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	};
	this.stateLabel = function ()
	{
		if (this.IsScreen(100) || this.Damage_ConvertOP(this.x, this.y, 1))
		{
			this.ReleaseActor();
			return true;
		}

		if (this.cancelCount <= 0 || this.hitCount > 0 || this.grazeCount > 0)
		{
			this.func();
			return true;
		}

		this.subState();
	};
}

function Shot_Charge( t )
{
	this.SetMotion(2029, 0);
	this.cancelCount = 3;
	this.atk_id = 131072;
	this.SetSpeed_Vec(15.00000000, t.rot, this.direction);
	this.func = [
		function ()
		{
			if (this.owner.shot_charge == this)
			{
				this.owner.shot_charge = null;
			}

			this.SetMotion(2029, 2);
			this.stateLabel = function ()
			{
				this.Vec_Brake(0.75000000, 0.50000000);
				this.alpha = this.blue = this.green -= 0.10000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		if (this.IsScreen(100) || this.Damage_ConvertOP(this.x, this.y, 10))
		{
			this.ReleaseActor();
			return true;
		}

		if (this.hitCount >= 4 || this.cancelCount <= 0 || this.grazeCount >= 5)
		{
			this.func[0].call(this);
			return;
		}

		this.sx = this.sy += 0.00500000;
		this.SetCollisionScaling(this.sx, this.sy, 1.00000000);
		this.Vec_Brake(0.50000000, 6.00000000);

		if (this.hitCount < 4)
		{
			this.HitCycleUpdate(3);
		}
	};
}

function Shot_Occult_WindBack( t )
{
	this.SetMotion(2509, 2);
	this.DrawActorPriority(10);
	this.rz = (5 + this.rand() % 5) * 0.01745329;
	this.sx = 1.00000000 + this.rand() % 10 * 0.10000000;
	this.sy = 1.00000000 + this.rand() % 10 * 0.10000000;
	this.SetSpeed_Vec(100.00000000, this.rz, this.direction);
	this.stateLabel = function ()
	{
		this.alpha -= 0.03300000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Shot_Occult_Wind( t )
{
	this.SetMotion(2509, 2);
	this.DrawActorPriority(300);
	this.rz = (10 + this.rand() % 10) * 0.01745329;
	this.sx = 1.00000000 + this.rand() % 10 * 0.10000000;
	this.sy = 1.00000000 + this.rand() % 10 * 0.10000000;
	this.SetSpeed_Vec(150.00000000, this.rz, this.direction);
	this.rz += (2 + this.rand() % 2) * 0.01745329;
	this.stateLabel = function ()
	{
		this.alpha -= 0.02500000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function Shot_Occult_Back( t )
{
	this.SetMotion(2509, 1);
	this.DrawBackActorPriority(80);
	this.alpha = 0.00000000;
	this.func = [
		function ()
		{
			this.stateLabel = function ()
			{
				this.alpha -= 0.02500000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.alpha += 0.01250000;

		if (this.alpha >= 1.00000000)
		{
			this.alpha = 1.00000000;
		}
	};
}

function Shot_Occult_Clowd( t )
{
	this.SetMotion(2509, 0);
	this.DrawActorPriority(10);
	this.flag1 = this.SetFreeObject(0, 0, 1.00000000, this.Shot_Occult_Back, {}).weakref();
	this.flag2 = 40;
	this.anime.vertex_alpha1 = 0.75000000;
	this.alpha = 0.00000000;
	this.func = [
		function ()
		{
			this.flag1.func[0].call(this.flag1);
			this.stateLabel = function ()
			{
				this.anime.left += 0.50000000;
				this.AddSpeed_XY(0.00000000, -0.05000000);
				this.alpha -= 0.03300000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.SetSpeed_XY(0.00000000, -this.y * 0.01000000);
		this.alpha += 0.02500000;

		if (this.alpha >= 1.00000000)
		{
			this.alpha = 1.00000000;
		}

		this.anime.left += 0.50000000;
		this.count++;

		if (this.count % this.flag2 == this.flag2 - 1)
		{
			this.count = 0;
			this.SetFreeObject(0, 200 + this.rand() % 420, 1.00000000, this.Shot_Occult_Wind, {});
			this.flag2 = 15 + this.rand() % 21;
		}
	};
}

function Shot_Occult_Lightning( t )
{
	this.SetMotion(2509, 4);
	this.PlaySE(4264);
	this.keyAction = this.ReleaseActor;
	this.cancelCount = 3;
	this.atk_id = 524288;
	this.stateLabel = function ()
	{
		this.count++;

		if (this.count == 30)
		{
			this.PlaySE(4276);
			::camera.Shake(10.00000000);
		}
	};
}

function Shot_Change( t )
{
	this.SetMotion(3929, 0);
	this.DrawActorPriority(180);
	local func_ = function ()
	{
		this.ReleaseActor();
	};
	this.rz = t.rot;
	this.SetSpeed_Vec(20.00000000, this.rz, this.direction);
	this.cancelCount = 1;
	this.atk_id = 536870911;
	this.flag2 = 0;
	this.func = [
		function ()
		{
			this.SetSpeed_XY(this.va.x * 0.10000000, this.va.y * 0.10000000);
			this.SetMotion(this.motion, 2);

			if (this.flag1)
			{
				this.flag1.ReleaseActor();
			}

			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.50000000);
				this.rz += (-90 * 0.01745329 - this.rz) * 0.07500000;
				this.alpha = this.green = this.blue = this.red -= 0.07500000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		},
		function ()
		{
			this.DrawActorPriority(200);
			this.count = 0;
			this.SetMotion(this.motion, 2);
			this.stateLabel = function ()
			{
				if (this.Damage_ConvertOP(this.x, this.y, 1))
				{
					this.ReleaseActor();
					return true;
				}

				this.count++;
				this.Vec_Brake(2.50000000);

				if (this.count <= 20)
				{
					local r_ = this.atan2(this.owner.target.y - this.y, (this.owner.target.x - this.x) * this.direction);
					this.rz += (r_ - this.rz) * 0.40000001;
				}

				if (this.count >= 25 && this.count % 2 == 0 && this.flag2 < 4)
				{
					this.PlaySE(4268);
					local t_ = {};
					t_.rot <- this.rz;
					t_.type <- 0;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_ChangeB, t_);
					this.flag2++;
				}

				if (this.count == 50)
				{
					this.func[2].call(this);
				}
			};
		},
		function ()
		{
			this.SetMotion(this.motion, 1);
			this.PlaySE(4274);
			this.grazeCount = 0;
			this.SetSpeed_Vec(20.00000000, this.rz, this.direction);
			this.stateLabel = function ()
			{
				if (this.IsScreen(200) || this.Damage_ConvertOP(this.x, this.y, 1))
				{
					this.ReleaseActor();
					return true;
				}

				if (this.cancelCount <= 0 || this.hitCount > 0 || this.grazeCount > 0)
				{
					this.func[0].call(this);
					return true;
				}

				this.TargetHoming(this.team.target, 0.75000000 * 0.01745329, this.direction);
				this.rz = this.atan2(this.va.y, this.va.x * this.direction);

				if (this.hitResult & (13 | 32))
				{
					this.SetSpeed_Vec(1.00000000, this.rz, this.direction);
					this.count++;

					if (this.count >= 3)
					{
						this.count = 0;
						this.HitReset();
						this.SetSpeed_Vec(15.00000000, this.rz, this.direction);
					}
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		if (this.Damage_ConvertOP(this.x, this.y, 1))
		{
			this.ReleaseActor();
			return true;
		}

		this.count++;

		if (this.count == 6)
		{
			this.func[1].call(this);
			return;
		}

		this.TargetHoming(this.team.target, 0.75000000 * 0.01745329, this.direction);
		this.rz = this.atan2(this.va.y, this.va.x * this.direction);

		if (this.cancelCount <= 0)
		{
			this.func[0].call(this);
			return true;
		}
	};
}

function Shot_ChangeB( t )
{
	this.SetMotion(3927, t.type);
	local func_ = function ()
	{
		this.ReleaseActor();
	};
	this.rz = t.rot;
	this.SetSpeed_Vec(25.00000000, this.rz, this.direction);
	this.SetCollisionRotation(0.00000000, 0.00000000, this.rz);
	this.keyAction = this.ReleaseActor;
	this.cancelCount = 1;
	this.atk_id = 536870912;
	this.func = function ()
	{
		this.callbackGroup = 0;
		this.stateLabel = function ()
		{
			this.sy *= 0.92000002;
			this.alpha -= 0.10000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	};
	this.stateLabel = function ()
	{
		if (this.IsScreen(200) || this.Damage_ConvertOP(this.x, this.y, 1))
		{
			this.ReleaseActor();
			return true;
		}

		if (this.cancelCount <= 0 || this.hitCount > 0 || this.grazeCount > 0)
		{
			this.func();
			return true;
		}
	};
}

function Shot_ChangeFin( t )
{
	this.SetMotion(3939, 1);
	this.flag1 = {};
	this.flag1.trail <- null;
	local t_ = {};
	t_.rot <- t.rot;
	this.flag1.trail = this.SetFreeObject(this.x, this.y, this.direction, this.owner.Shot_ChangeFinTrail, t_).weakref();
	this.cancelCount = 3;
	this.atk_id = 536870912;
	this.SetSpeed_Vec(15.00000000, this.initTable.rot, this.direction);
	this.subState = function ()
	{
		if (this.IsScreen(100 * this.sx) || this.Damage_ConvertOP(this.x, this.y, 10))
		{
			if (this.flag1.trail)
			{
				this.flag1.trail.func[0].call(this.flag1.trail);
			}

			this.ReleaseActor();
			return true;
		}
	};
	this.func = [
		function ()
		{
			if (this.flag1.trail)
			{
				this.flag1.trail.func[0].call(this.flag1.trail);
			}

			this.flag1.trail = null;
			this.SetMotion(this.motion, 1);
			this.SetSpeed_XY(-5.00000000 * this.direction, -5.00000000);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(null, 0.25000000);
				this.rz -= 10 * 0.01745329;
				this.alpha -= 0.05000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		if (this.subState())
		{
			return;
		}

		if (this.hitCount >= 1 || this.cancelCount <= 0)
		{
			this.func[0].call(this);
			return;
		}

		this.rz += 0.17453292;
		this.HitCycleUpdate(0);
		this.sx = this.sy += 0.02500000;
		this.SetCollisionScaling(this.sx, this.sy, 1.00000000);
	};
}

function Shot_ChangeFinTrail( t )
{
	this.rz = t.rot;
	this.SetMotion(3939, 2);
	this.alpha = 0.00000000;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.sx = 0.50000000;
			this.sy = 1.00000000;
			this.alpha = 0.00000000;
			this.red = this.blue = this.green = 1.00000000;
			this.subState = function ()
			{
				this.alpha += 0.20000000;

				if (this.alpha >= 1.00000000)
				{
					this.subState = function ()
					{
						this.alpha = this.green = this.blue -= 0.02500000;

						if (this.alpha <= 0.00000000)
						{
							this.func[1].call(this);
						}
					};
				}
			};
		}
	];
	this.func[1].call(this);
	this.stateLabel = function ()
	{
		this.sx += (1.50000000 - this.sx) * 0.10000000;
		this.sy *= 0.99000001;
		this.subState();
	};
}

function Shot_BarrageBit( t )
{
	this.SetMotion(2028, 0);
	this.DrawActorPriority(180);
	local func_ = function ()
	{
		this.ReleaseActor();
	};
	this.rz = t.rot;
	this.SetSpeed_Vec(20.00000000, this.rz, this.direction);
	this.cancelCount = 1;
	this.atk_id = 262144;
	this.flag2 = 0;
	this.flag3 = t.rot <= 0 ? 0.05235988 : -0.05235988;
	this.func = [
		function ()
		{
			this.SetSpeed_XY(this.va.x * 0.10000000, this.va.y * 0.10000000);
			this.SetMotion(this.motion, 2);

			if (this.flag1)
			{
				this.flag1.ReleaseActor();
			}

			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.50000000);
				this.rz += (-90 * 0.01745329 - this.rz) * 0.07500000;
				this.alpha = this.green = this.blue = this.red -= 0.07500000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		},
		function ()
		{
			this.DrawActorPriority(200);
			this.count = 0;
			this.SetMotion(this.motion, 2);
			this.stateLabel = function ()
			{
				if (this.Damage_ConvertOP(this.x, this.y, 1))
				{
					this.ReleaseActor();
					return true;
				}

				this.count++;
				this.Vec_Brake(2.50000000);

				if (this.count <= 20)
				{
					local r_ = this.atan2(this.owner.target.y - this.y, (this.owner.target.x - this.x) * this.direction);
					this.rz += (r_ - this.rz) * 0.40000001;
				}

				if (this.count >= 26)
				{
					this.rz += this.flag3;
				}

				if (this.count >= 25 && this.count % 2 == 0 && this.flag2 < 7)
				{
					if (this.flag2 == 0)
					{
						this.PlaySE(4268);
					}

					local t_ = {};
					t_.rot <- this.rz;
					t_.type <- this.flag2;
					this.SetShot(this.point0_x, this.point0_y, this.direction, this.Shot_Barrage, t_);
					this.flag2++;
				}

				if (this.count == 50)
				{
					this.func[2].call(this);
				}
			};
		},
		function ()
		{
			this.SetMotion(this.motion, 2);
			this.SetSpeed_Vec(20.00000000, this.rz, this.direction);
			this.count = 0;
			this.stateLabel = function ()
			{
				if (this.IsScreen(200))
				{
					this.ReleaseActor();
					return true;
				}

				if (this.count <= 30)
				{
					this.rz += 0.10471975;
					this.va.RotateByRadian(0.10471975);
					this.ConvertTotalSpeed();
				}

				this.count++;
			};
		}
	];
	this.stateLabel = function ()
	{
		if (this.Damage_ConvertOP(this.x, this.y, 1))
		{
			this.ReleaseActor();
			return true;
		}

		this.count++;

		if (this.count == 6)
		{
			this.func[1].call(this);
			return;
		}

		this.TargetHoming(this.team.target, 0.75000000 * 0.01745329, this.direction);
		this.rz = this.atan2(this.va.y, this.va.x * this.direction);

		if (this.cancelCount <= 0)
		{
			this.func();
			return true;
		}
	};
}

function Shot_Barrage( t )
{
	this.SetMotion(2026, t.type);
	local func_ = function ()
	{
		this.ReleaseActor();
	};
	this.rz = t.rot;
	this.SetSpeed_Vec(15.00000000, this.rz, this.direction);
	this.keyAction = this.ReleaseActor;
	this.cancelCount = 1;
	this.subState = function ()
	{
		if (this.Vec_Brake(0.75000000, 5.00000000))
		{
			this.subState = function ()
			{
			};
		}
	};
	this.func = function ()
	{
		this.SetMotion(2027, this.keyTake);
		this.stateLabel = function ()
		{
			this.sy *= 0.92000002;
			this.alpha -= 0.10000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	};
	this.stateLabel = function ()
	{
		if (this.IsScreen(100) || this.Damage_ConvertOP(this.x, this.y, 1))
		{
			this.ReleaseActor();
			return true;
		}

		if (this.cancelCount <= 0 || this.hitCount > 0 || this.grazeCount > 0)
		{
			this.func();
			return true;
		}

		this.subState();
	};
}

function SP_Hisou_Stone( t )
{
	this.SetMotion(3009, 0);
	this.alpha = 0.00000000;
	this.SetParent(this.owner, this.x - this.owner.x, this.y - this.owner.y);
	this.SetSpeed_XY(0.00000000, -3.00000000);
	this.flag1 = ::manbow.Actor2DProcGroup();
	this.flag2 = 0.00000000;
	this.flag3 = this.Vector3();
	this.flag3.y = -50.00000000;
	this.flag3.RotateByDegree(4.50000000);
	this.flag4 = (-90 + 4.50000000) * 0.01745329;
	this.func = [
		function ()
		{
			this.alpha = 1.00000000;
			this.SetParent(null, 0, 0);
			this.flag1.Foreach(function ()
			{
				this.func[0].call(this);
			});
			this.stateLabel = function ()
			{
				this.rz += (-60 * 0.01745329 - this.rz) * 0.05000000;
				this.AddSpeed_XY(0.00000000, 0.50000000);
				this.alpha -= 0.05000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		},
		function ()
		{
			this.SetSpeed_XY(0.00000000, 0.00000000);
			this.alpha = 1.00000000;
			this.count = 0;
			this.PlaySE(4223);
			this.stateLabel = function ()
			{
				if (this.Damage_ConvertOP(this.x, this.y, 10) || this.owner.motion != 3000 && this.owner.motion != 3001)
				{
					this.func[0].call(this);
					return;
				}

				this.count++;

				if (this.count % 2 == 1 && this.count <= 19)
				{
					local t_ = {};
					t_.rot <- 0.10471975 * this.sin(this.flag4);
					this.flag1.Add(this.SetShotDynamic(this.x + this.flag3.x * 0.25000000 * this.direction, this.y + this.flag3.y, this.direction, this.SP_Hisou_Laser_B, t_));
					local t_ = {};
					t_.rot <- 0.10471975 * this.sin(this.flag4 + 3.14159203);
					this.flag1.Add(this.SetShotDynamic(this.x - this.flag3.x * 0.25000000 * this.direction, this.y - this.flag3.y, this.direction, this.SP_Hisou_Laser_F, t_));
					this.flag4 += 18 * 0.01745329;
					this.flag3.RotateByDegree(18);
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		if (this.Damage_ConvertOP(this.x, this.y, 10) || this.owner.motion != 3000 && this.owner.motion != 3001)
		{
			this.func[0].call(this);
			return;
		}

		this.VY_Brake(0.25000000);
		this.alpha += 0.10000000;
	};
}

function SP_Hisou_Laser_Common( t )
{
	this.SetMotion(3009, 1);
	this.SetParent(this.owner, this.x - this.owner.x, this.y - this.owner.y);
	this.anime.left = 0;
	this.anime.top = 0;
	this.anime.width = 1600;
	this.anime.height = 32;
	this.anime.center_x = 0;
	this.anime.center_y = 16;
	this.rz = t.rot;
	this.SetCollisionRotation(0.00000000, 0.00000000, this.rz);
	this.sy = 0.05000000;
	this.cancelCount = 1;
	this.atk_id = 1048576;
	this.flag1 = null;
	this.func = [
		function ()
		{
			this.SetParent(null, 0, 0);
			this.SetMotion(3009, 1);

			if (this.flag1)
			{
				this.flag1.func[0].call(this.flag1);
			}

			this.stateLabel = function ()
			{
				this.anime.left -= 6;
				this.alpha = this.blue = this.green -= 0.05000000;
				this.sy *= 0.69999999;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		},
		function ()
		{
			this.SetMotion(3009, 2);

			if (this.flag1)
			{
				this.flag1.func[1].call(this.flag1);
			}

			this.stateLabel = function ()
			{
				this.anime.left -= 30;
				this.sy += (1.00000000 - this.sy) * 0.40000001;
				this.count++;

				if (this.cancelCount <= 0 || this.count >= 19)
				{
					this.func[0].call(this);
					return;
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.anime.left -= 30;
		this.sy += 0.00750000;

		if (this.sy >= 0.20000000)
		{
			this.func[1].call(this);
		}
	};
}

function SP_Hisou_Laser_F( t )
{
	this.SP_Hisou_Laser_Common(t);
	this.DrawActorPriority(200);
	this.flag1 = this.SetFreeObject(this.x, this.y, this.direction, this.SP_Hisou_Ball_F, {}, this.weakref()).weakref();
}

function SP_Hisou_Laser_B( t )
{
	this.SP_Hisou_Laser_Common(t);
	this.DrawActorPriority(199);
	this.flag1 = this.SetFreeObject(this.x, this.y, this.direction, this.SP_Hisou_Ball_B, {}, this.weakref()).weakref();
}

function SP_Hisou_Ball_B( t )
{
	this.SetMotion(3009, 3);
	this.DrawActorPriority(199);
	this.SetParent(t.pare, 0, 0);
	this.sx = this.sy = 0.10000000;
	this.func = [
		function ()
		{
			this.SetParent(null, 0, 0);
			this.alpha = 2.00000000;
			this.stateLabel = function ()
			{
				this.sx *= 0.89999998;
				this.sy *= 0.89999998;
				this.alpha -= 0.10000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.sx = this.sy += (1.00000000 - this.sx) * 0.10000000;
			};
		}
	];
	this.stateLabel = function ()
	{
		this.sx = this.sy += (0.25000000 - this.sx) * 0.10000000;
	};
}

function SP_Hisou_Ball_F( t )
{
	this.SetMotion(3009, 3);
	this.SetParent(t.pare, 0, 0);
	this.sx = this.sy = 0.10000000;
	this.func = [
		function ()
		{
			this.SetParent(null, 0, 0);
			this.alpha = 2.00000000;
			this.stateLabel = function ()
			{
				this.sx *= 0.89999998;
				this.sy *= 0.89999998;
				this.alpha -= 0.10000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.sx = this.sy += (1.00000000 - this.sx) * 0.10000000;
			};
		}
	];
	this.stateLabel = function ()
	{
		this.sx = this.sy += (0.25000000 - this.sx) * 0.10000000;
	};
}

function SPShot_Kaname_Drop( t )
{
	this.SetMotion(3029, 0);
	this.cancelCount = 3;
	this.atk_id = 8388608;
	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, 0.75000000, 0.00000000, 17.50000000);

		if (this.y > ::battle.scroll_bottom || this.Damage_ConvertOP(this.x, this.y, 15))
		{
			this.ReleaseActor();
			return;
		}

		if (this.cancelCount <= 0)
		{
			this.SetMotion(3029, 1);
			this.stateLabel = function ()
			{
				this.alpha = this.red = this.green = this.blue -= 0.20000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	};
}

function SP_Kaname_Crash_Stone( t )
{
	this.SetMotion(3019, 0);
	this.alpha = 0.00000000;
	this.flag1 = this.Vector3();
	this.flag1.y = 200 * t.y;
	this.flag2 = 4.00000000;
	this.cancelCount = 99;
	this.atk_id = 4194304;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.SetMotion(3019, 1);
			this.subState = function ()
			{
				this.flag2 -= 4;

				if (this.flag2 < -16)
				{
					this.flag2 = -16;
				}

				if (this.initTable.y == -1 && this.rz - this.flag2 * 0.01745329 >= 90 * 0.01745329 || this.initTable.y == 1 && this.rz + this.flag2 * 0.01745329 <= -90 * 0.01745329)
				{
					this.func[2].call(this);
				}
			};
		},
		function ()
		{
			this.owner.hitResult = 1;

			if (this.initTable.y == -1)
			{
				::camera.shake_radius = 6.00000000;
				this.PlaySE(4226);
				this.SetShot(this.owner.x + 200 * this.direction, this.owner.y, this.direction, this.SP_Kaname_Crash_Wave, {});
			}

			this.ReleaseActor();
		}
	];
	this.subState = function ()
	{
		this.flag2 *= 0.89999998;
	};
	this.stateLabel = function ()
	{
		if (this.Damage_ConvertOP(this.x, this.y, 5))
		{
			this.func[0].call(this);
			return;
		}

		this.alpha += 0.10000000;
		this.subState();
		this.flag1.RotateByDegree(this.flag2 * this.initTable.y);
		this.Warp(this.owner.x + this.flag1.x * this.direction, this.owner.y + this.flag1.y);
		this.rz += this.flag2 * 0.01745329 * this.initTable.y;
		this.SetCollisionRotation(0.00000000, 0.00000000, this.rz);
	};
}

function SP_Kaname_Crash_Wave( t )
{
	this.SetMotion(3019, 2);
	this.cancelCount = 3;
	this.atk_id = 4194304;
	this.alpha = 1.25000000;
	this.stateLabel = function ()
	{
		this.sx = this.sy += (2.00000000 - this.sx) * 0.15000001;
		this.alpha -= 0.05000000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function SP_Hisou_Slash_Blade( t )
{
	this.SetMotion(3039, 0);
	this.SetParent(this.owner, 0, 0);
	this.actorType = 4;
	this.cancelCount = 6;
	this.atk_id = 16777216;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		}
	];
	this.keyAction = [
		function ()
		{
			this.sx = this.sy = t.scale;
			this.SetCollisionScaling(this.sx, this.sy, 1.00000000);
		},
		function ()
		{
			this.ReleaseActor();
		}
	];
	this.stateLabel = function ()
	{
		if (this.hitResult & 13 && (this.owner.motion == 3030 || this.owner.motion == 3031))
		{
			this.owner.hitResult = this.hitResult;
		}
	};
}

function SP_Koma_Shot( t )
{
	this.SetMotion(3049, 0);
	this.SetSpeed_XY(15.00000000 * this.direction, -1.00000000);
	this.flag1 = this.y + 60;
	this.rz = -0.17453292;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.SetMotion(3049, 1);
			this.SetSpeed_XY(this.va.x, -7.50000000);
			this.stateLabel = function ()
			{
				this.AddSpeed_XY(0.00000000, 0.50000000);
				this.alpha = this.red = this.green = this.blue -= 0.10000000;

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.cancelCount = 3;
	this.atk_id = 2097152;
	this.subState = function ()
	{
		this.VX_Brake(0.50000000, 2.00000000 * this.direction);
		this.AddSpeed_XY(0.00000000, 0.50000000);

		if (this.y > this.flag1)
		{
			this.SetSpeed_XY(this.va.x, 1.50000000);
			this.subState = function ()
			{
				this.VX_Brake(0.50000000);
				this.AddSpeed_XY(0.00000000, -0.50000000);

				if (this.va.y < 0 && this.y < this.flag1)
				{
					this.SetSpeed_XY(0.00000000, 0.00000000);
					this.count = 0;
					this.subState = function ()
					{
						this.count++;
						this.rz = 0.10471975 * this.sin(this.count * 0.10471975);
						this.SetSpeed_XY(3.00000000 * this.direction * this.sin(this.count * 0.10471975), 0.00000000);
					};
				}
			};
		}
	};
	this.stateLabel = function ()
	{
		if (this.Damage_ConvertOP(this.x, this.y, 8))
		{
			this.func[0].call(this);
			return;
		}

		if (this.cancelCount <= 0 || this.hitCount >= 4 || this.count >= 90)
		{
			this.func[1].call(this);
			return;
		}

		this.HitCycleUpdate(3);
		this.subState();
	};
}

function SPShot_A( t )
{
	this.rz = t.rot;
	this.SetMotion(3009, 0);
	this.flag1 = 0;
	this.SetSpeed_Vec(30.00000000, t.rot, this.direction);
	this.cancelCount = 3;
	this.FitBoxfromSprite();
	this.func = [
		function ()
		{
			this.SetMotion(3009, 1);
			this.keyAction = this.ReleaseActor;
			this.stateLabel = function ()
			{
				this.SetSpeed_XY(this.va.x * 0.94999999, this.va.y * 0.94999999);
			};
		}
	];
	this.stateLabel = function ()
	{
		if (this.IsScreen(200) || this.Damage_ConvertOP(this.x, this.y, 4))
		{
			this.ReleaseActor();
			return true;
		}

		if (this.cancelCount <= 0)
		{
			this.func[0].call(this);
			return;
		}

		if (this.hitResult)
		{
			if (this.hitResult & 31)
			{
				this.SetSpeed_Vec(1.00000000, this.rz, this.direction);
				this.stateLabel = function ()
				{
					if (this.count >= 15 || this.hitCount >= 4 || this.hitResult & 8)
					{
						this.owner.SPShot_A_Exp.call(this, null);
						return;
					}

					this.HitCycleUpdate(4);
					this.count++;
				};
			}

			this.HitCycleUpdate(4);
		}

		this.count++;
	};
}

function SPShot_A_Exp( t )
{
	this.SetSpeed_XY(0.00000000, 0.00000000);
	this.SetMotion(3009, 2);
	this.HitReset();
	this.stateLabel = null;
	this.keyAction = this.ReleaseActor;
}

function SPShot_A_Release( t )
{
	this.rz = t.rz;
	this.SetMotion(3009, 3);
	this.keyAction = this.ReleaseActor;
}

function SPShot_B( t )
{
	this.SetMotion(3019, 3);
	this.cancelCount = 9;
	this.flag1 = [];
	this.flag2 = {};
	this.flag2.range <- 0.00000000;
	this.flag3 = 8.00000000;
	this.SetSpeed_XY(15.00000000 * this.direction, 0.00000000);

	for( local i = 0; i < 4; i++ )
	{
		local t_ = {};
		t_.rot <- (45 + 90 * i) * 0.01745329;

		if (i <= 1)
		{
			t_.rotRate <- 1.00000000;
		}
		else
		{
			t_.rotRate <- -1.00000000;
		}

		this.flag1.append(this.SetObject(this.x, this.y, this.direction, this.owner.SPShot_B_Point, t_).weakref());
	}

	this.func = function ()
	{
		foreach( a in this.flag1 )
		{
			if (a)
			{
				a.func();
			}
		}

		this.callbackGroup = 0;
		this.stateLabel = function ()
		{
			this.sx = this.sy *= 0.92000002;
			this.alpha -= 0.10000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	};
	this.stateLabel = function ()
	{
		if (this.owner.motion == 3010 && this.owner.keyTake == 0)
		{
			this.func();
			return;
		}

		this.count++;

		foreach( a in this.flag1 )
		{
			if (a)
			{
				a.Warp(this.x + this.flag2.range * a.flag1.x * this.direction, this.y + this.flag2.range * a.flag1.y);
			}
			else
			{
				this.func();
				return;
			}
		}

		this.flag2.range += this.flag3;

		if (this.flag2.range >= 160.00000000)
		{
			this.PlaySE(1102);
			this.SetMotion(3019, 2);
			this.SetSpeed_XY(0.00000000, 0.00000000);
			this.count = 0;
			this.flag2.range = 160.00000000;
			this.sx = this.sy = 1.00000000;
			this.FitBoxfromSprite();

			foreach( a in this.flag1 )
			{
				if (a)
				{
					a.SetMotion(3019, 1);
					this.SetFreeObject(a.x, a.y, this.direction, this.owner.SPShot_B_SetEffect, {});
				}
			}

			this.stateLabel = function ()
			{
				this.count++;

				if (this.count >= 300 || this.hitCount >= 3 || this.cancelCount <= 0 || this.flag2.range <= 25 || this.owner.motion == 3010 && this.owner.keyTake == 0 || this.Damage_ConvertOP(this.x, this.y, 10, 2))
				{
					this.func();
					return;
				}

				this.flag2.range -= 0.50000000;

				if (this.hitResult & 32)
				{
					this.flag2.range -= 3.00000000;
				}

				this.sx = this.flag2.range / 160.00000000;
				this.sy = this.flag2.range / 160.00000000;
				this.SetCollisionScaling(this.sx, this.sy, 1.00000000);

				foreach( val, a in this.flag1 )
				{
					if (a)
					{
						a.Warp(this.x + this.flag2.range * a.flag1.x * this.direction, this.y + this.flag2.range * a.flag1.y);

						if (a.life <= 0)
						{
							a.func();
							this.func();
							return;
						}
					}
					else
					{
						this.func();
						return;
					}
				}

				this.HitCycleUpdate(7);
			};
		}
	};
}

function SPShot_B_SetEffect( t )
{
	this.SetMotion(3019, 0);
	this.stateLabel = function ()
	{
		this.sx = this.sy += 0.02500000;
		this.rz += 13.00000000 * 0.01745329;
		this.alpha -= 0.05000000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function SPShot_B_Point( t )
{
	this.SetMotion(3019, 0);
	this.life = 1;
	this.flag1 = this.Vector3();
	this.flag1.x = this.cos(t.rot);
	this.flag1.y = this.sin(t.rot);
	this.stateLabel = function ()
	{
		this.count++;

		if (this.keyTake == 0)
		{
			if (this.Damage_ConvertOP(this.x, this.y, 2, 1))
			{
				this.ReleaseActor();
				return;
			}

			this.rz += 18 * 0.01745329 * this.initTable.rotRate;

			if (this.count % 2 == 1)
			{
				local t_ = {};
				t_.rot <- this.rz;
				this.SetFreeObject(this.x, this.y, this.direction, this.owner.SPShot_B_Trail, t_);
			}
		}
		else
		{
			this.rz += 0.01745329 * this.initTable.rotRate;
		}
	};
	this.func = function ()
	{
		this.owner.SPShot_B_PointFade.call(this, null);
	};
}

function SPShot_B_Trail( t )
{
	this.SetMotion(3019, 0);
	this.rz = t.rot;
	this.stateLabel = function ()
	{
		this.sx = this.sy += 0.02500000;
		this.alpha = this.green = this.blue -= 0.07500000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function SPShot_B_PointFade( t )
{
	this.SetMotion(3019, 4);
	this.sx = this.sy = 2.00000000;
	local i = 0;

	while (i < 6)
	{
		i++;
		this.SetFreeObject(this.x, this.y, this.direction, this.owner.SPShot_B_Ball, {});
	}

	this.stateLabel = function ()
	{
		this.AddSpeed_XY(0.00000000, -0.20000000);

		if (this.rand() % 100 <= 25)
		{
			this.SetFreeObject(this.x, this.y, this.direction, this.owner.SPShot_B_Ball, {});
		}

		this.sx = this.sy *= 0.92000002;
		this.alpha -= 0.05000000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function SPShot_B_Ball( t )
{
	this.SetMotion(3019, 5 + this.rand() % 4);
	this.rz = this.rand() % 360 * 0.01745329;
	this.sx = this.sy = 0.75000000 + this.rand() % 6 * 0.10000000;
	this.SetSpeed_Vec(4 + this.rand() % 4, this.rand() % 360 * 0.01745329, this.direction);
	this.stateLabel = function ()
	{
		this.VX_Brake(0.25000000);
		this.AddSpeed_XY(0.00000000, -0.25000000);
		this.sx = this.sy *= 0.98000002;
		this.alpha = this.blue -= 0.03500000;

		if (this.alpha <= 0.00000000)
		{
			this.ReleaseActor();
		}
	};
}

function SPShot_G( t )
{
	this.SetMotion(3069, 0);
	this.DrawActorPriority(180);
	this.rz = t.rot;
	this.keyAction = this.ReleaseActor;
	local t_ = {};
	t_.rot <- this.rz;
	this.SetFreeObject(this.x, this.y, this.direction, function ( t_ )
	{
		this.SetMotion(3069, 3);
		this.DrawActorPriority(180);
		this.rz = t.rot;
		this.stateLabel = function ()
		{
			this.sx = this.sy += 0.05000000;
			this.alpha = this.green = this.blue -= 0.20000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	}, t_);
}

function SPShot_G_Head( t )
{
	this.SetMotion(3069, 1);
	this.func = function ()
	{
		this.SetSpeed_XY(this.initTable.pare.va.x, this.initTable.pare.va.y);
		this.stateLabel = function ()
		{
			this.sx = this.sy *= 0.98000002;
			this.alpha = this.green = this.blue -= 0.10000000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	};
	this.stateLabel = function ()
	{
		if (this.initTable.pare.hitStopTime == 0)
		{
			this.rz -= 10.00000000 * 0.01745329;
		}

		if (this.initTable.pare.motion >= 3060 && this.initTable.pare.motion <= 3064)
		{
			this.Warp(this.initTable.pare.point1_x, this.initTable.pare.point1_y);
		}
		else
		{
			this.ReleaseActor();
		}
	};
}

function SPShot_G_Trail( t )
{
	this.rz = t.rot;
	this.alpha = 0.00000000;
	this.SetMotion(3069, 2);
	this.DrawActorPriority(180);
	this.sx = 0.25000000;
	this.func = function ()
	{
		this.SetSpeed_XY(this.initTable.pare.va.x, this.initTable.pare.va.y);
		this.stateLabel = function ()
		{
			this.sy *= 0.94999999;
			this.alpha = this.green = this.blue -= 0.07500000;

			if (this.alpha <= 0.00000000)
			{
				this.ReleaseActor();
			}
		};
	};
	this.stateLabel = function ()
	{
		this.alpha += 0.20000000;

		if (this.alpha > 1.00000000)
		{
			this.alpha = 1.00000000;
		}

		if (this.initTable.pare.hitStopTime == 0)
		{
			this.sx += (1.50000000 - this.sx) * 0.25000000;
		}

		if (this.initTable.pare.motion >= 3060 && this.initTable.pare.motion <= 3064)
		{
			this.Warp(this.initTable.pare.point1_x, this.initTable.pare.point1_y);
		}
		else
		{
			this.ReleaseActor();
		}
	};
}

function SpellShot_A( t )
{
	this.SetMotion(4009, 0);
	this.rz = t.rot;
	this.SetSpeed_Vec(50.00000000, this.rz, this.direction);
	this.alpha = 0.00000000;
	this.cancelCount = 3;
	this.atk_id = 67108864;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.SetSpeed_XY(0.00000000, 0.00000000);
			this.SetMotion(4009, 1);
			this.count = 0;
			this.rz = this.atan2(this.owner.target.y - 30 - this.y, (this.owner.target.x - this.x) * this.direction);
			this.stateLabel = function ()
			{
				local r_ = this.atan2(this.owner.target.y - 30 - this.y, (this.owner.target.x - this.x) * this.direction) - this.rz;

				while (this.abs(r_) > 3.14159203)
				{
					if (r_ > 0)
					{
						r_ = r_ - 6.28318548;
					}
					else
					{
						r_ = r_ + 6.28318548;
					}
				}

				this.rz += r_ * 0.25000000;
				this.count++;

				if (this.count == 10)
				{
					this.func[2].call(this);
				}
			};
		},
		function ()
		{
			if (this.initTable.se > 0)
			{
				this.PlaySE(this.initTable.se);
			}

			this.SetCollisionRotation(0.00000000, 0.00000000, this.rz);
			this.count = 0;
			this.SetMotion(4009, 3);
			this.stateLabel = function ()
			{
			};
		},
		function ()
		{
			this.count = 0;
			this.stateLabel = function ()
			{
				this.count++;

				if (this.count <= 18)
				{
					this.rz += 0.17453292;
					this.SetSpeed_Vec(30, this.rz, this.direction);
				}

				if (this.IsScreen(200))
				{
					this.func[0].call(this);
					return;
				}
			};
		}
	];
	this.keyAction = [
		null,
		null,
		null,
		function ()
		{
			this.func[3].call(this);
		}
	];
	this.stateLabel = function ()
	{
		this.alpha += 0.10000000;
		this.TargetHoming(this.owner.target, 6.28318548, this.direction);
		this.count++;

		if (this.count >= 15)
		{
			this.Vec_Brake(5.00000000);
		}

		if (this.count == 20)
		{
			this.func[1].call(this);
		}
	};
}

function SpellShot_B( t )
{
	this.SetMotion(4019, 1);
	this.DrawActorPriority(180);
	this.SetParent(this.owner, 0, 0);
	this.atk_id = 67108864;
	this.func = [
		function ()
		{
			this.SetParent(null, 0, 0);
			this.SetMotion(4019, 1);
			this.flag1 = (3 - this.rand() % 7) * 0.01745329;
			this.flag2 = 0;
			this.stateLabel = function ()
			{
				this.alpha = this.red = this.green = this.blue -= 0.02500000;
				this.AddSpeed_XY(0.00000000, 0.20000000);

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}

				return;

				if (this.flag1 > 0)
				{
					this.flag2 += 0.20000000 * 0.01745329;
					this.rz += this.flag2;

					if (this.rz > this.flag1)
					{
						this.rz = this.flag1;
					}
				}
				else
				{
					this.flag2 += 0.20000000 * 0.01745329;
					this.rz += this.flag2;

					if (this.rz > this.flag1)
					{
						this.rz = this.flag1;
					}
				}
			};
		}
	];
	this.stateLabel = function ()
	{
		this.HitCycleUpdate(4);
		this.count++;

		if (this.count == 2)
		{
			local t_ = {};
			t_.height <- this.owner.centerY + 50;
			this.SetShot(this.x + 100 * this.direction, ::battle.scroll_bottom, this.direction, this.SpellShot_B_Sub, t_);
			this.SetShot(this.x - 100 * this.direction, ::battle.scroll_bottom, -this.direction, this.SpellShot_B_Sub, t_);
		}
	};
}

function SpellShot_B_Sub( t )
{
	this.SetMotion(4019, 0);
	this.atk_id = 67108864;
	this.DrawActorPriority(180);
	this.rz = (15 - this.rand() % 31) * 0.10000000 * 0.01745329;
	::camera.Shake(5.00000000);
	this.func = [
		function ()
		{
			this.SetMotion(4019, 1);
			this.stateLabel = function ()
			{
				this.alpha = this.red = this.green = this.blue -= 0.02500000;
				this.AddSpeed_XY(0.00000000, 0.20000000);

				if (this.alpha <= 0.00000000)
				{
					this.ReleaseActor();
				}
			};
		}
	];
	this.subState = function ()
	{
		this.AddSpeed_XY(0.00000000, -2.00000000, 0.00000000, -20.00000000);

		if (this.y < this.initTable.height)
		{
			this.subState = function ()
			{
				if (this.VY_Brake(4.00000000))
				{
					this.SetMotion(4019, 1);
					this.subState = function ()
					{
					};
				}
			};
		}
	};
	this.stateLabel = function ()
	{
		this.count++;
		this.HitCycleUpdate(4);

		if (this.count == 5 && !this.IsScreen(100))
		{
			local t_ = {};
			t_.height <- this.initTable.height - 50;
			this.SetShot(this.x + 128 * this.direction, ::battle.scroll_bottom, this.direction, this.SpellShot_B_Sub, t_);
		}

		if (this.count == 60)
		{
			this.func[0].call(this);
			return;
		}

		this.subState();
	};
}

function SpellShot_C_Aura( t )
{
	this.SetMotion(4029, 0);
	this.keyAction = this.ReleaseActor;
}

function SpellShot_C_AuraB( t )
{
	this.SetMotion(4029, 1);
	this.SetParent(this.owner, 0, 0);
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.isVisible = false;
			this.SetMotion(4029, 2);
			this.stateLabel = function ()
			{
				if (this.team.current == this.owner)
				{
					this.func[2].call(this);
				}
			};
		},
		function ()
		{
			this.SetMotion(4029, 1);
			this.Warp(this.owner.x, this.owner.y);
			this.isVisible = true;
			this.stateLabel = function ()
			{
			};
		}
	];
}

function Climax_Shot( t )
{
	this.DrawActorPriority(179);
	this.SetMotion(4909, 1);
	this.atkRate_Pat = t.rate;
	this.rx = t.rot;
	this.ry = 90 * 0.01745329;
	this.sx = this.sy = this.sz = 0.10000000;
	this.cancelCount = 99;
	this.SetCollisionRotation(0.00000000, 0.00000000, this.rx);
	this.SetCollisionScaling(this.sx, this.sy, 1.00000000);
	this.SetParent(this.owner, this.x - this.owner.x, this.y - this.owner.y);

	if (t.pare)
	{
		this.hitOwner = t.pare.weakref();
	}

	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.flag1 = 1.00000000;
			this.SetParent(null, 0, 0);
			this.SetKeyFrame(1);
			this.stateLabel = function ()
			{
			};
		}
	];
	this.keyAction = this.ReleaseActor;
	this.stateLabel = function ()
	{
		this.sx = this.sy = this.sz += (1.50000000 - this.sx) * 0.15000001;
		this.SetCollisionScaling(this.sx, this.sy, 1.00000000);
	};
}

function Climax_Back( t )
{
	this.SetMotion(4909, 2);
	this.DrawActorPriority(10);
	this.func = [
		function ()
		{
			if (this.flag1)
			{
				this.flag1.ReleaseActor();
			}

			this.ReleaseActor();
		}
	];
	this.alpha = 0.00000000;
	this.stateLabel = function ()
	{
		this.alpha += 0.03300000;

		if (this.alpha >= 1.00000000)
		{
			this.flag1 = this.SetFreeObject(640, 720, 1.00000000, this.Climax_HAARP, {}).weakref();
			this.alpha = 1.00000000;
			this.stateLabel = null;
		}
	};
}

function Climax_HAARP( t )
{
	this.SetMotion(4909, 3);
	this.DrawActorPriority(10);
}

function Climax_Screen( t )
{
	this.SetMotion(4907, 4);
	this.DrawScreenActorPriority(100);
	this.func = [
		function ()
		{
			this.ReleaseActor();
		}
	];
}

function Climax_Clowd( t )
{
	this.SetMotion(4907, 2);
	this.DrawScreenActorPriority(110);
	this.alpha = 0.00000000;
	this.anime.left = 0;
	this.anime.top = 1;
	this.anime.width = 768;
	this.anime.height = 255;
	this.anime.center_x = 0;
	this.anime.center_y = 200;
	this.anime.radius0 = 300;
	this.anime.radius1 = 800;
	this.anime.length = 400;
	this.anime.vertex_alpha1 = 1.00000000;
	this.anime.vertex_blue1 = 1.00000000;
	this.anime.vertex_red1 = 1.00000000;
	this.anime.vertex_green1 = 1.00000000;
	this.func = [
		function ()
		{
			if (this.flag1)
			{
				this.flag1.func[0].call(this.flag1);
			}

			this.ReleaseActor();
		},
		function ()
		{
			if (this.flag1)
			{
				this.flag1.func[1].call(this.flag1);
			}

			this.stateLabel = function ()
			{
				this.anime.radius0 *= 1.10000002;
				this.anime.radius1 *= 1.10000002;
				this.anime.length += 0.50000000;
				this.anime.left += 1.50000000;
				this.anime.radius0 -= 0.25000000;
			};
		}
	];
	this.flag1 = this.SetFreeObjectDynamic(this.x, this.y, this.direction, this.Climax_ClowdB, {}, this).weakref();
	this.stateLabel = function ()
	{
		this.rx += 0.01000000 * 0.01745329;
		this.alpha += 0.02500000;
		this.anime.length += 0.50000000;
		this.anime.left += 0.50000000;
		this.anime.radius0 -= 0.25000000;
	};
}

function Climax_ClowdB( t )
{
	this.SetMotion(4907, 3);
	this.DrawScreenActorPriority(110);
	this.alpha = 0.00000000;
	this.anime.left = 0;
	this.anime.top = 1;
	this.anime.width = 512;
	this.anime.height = 255;
	this.anime.center_x = 0;
	this.anime.center_y = 200;
	this.anime.radius0 = 500;
	this.anime.radius1 = 800;
	this.anime.length = 600;
	this.anime.vertex_alpha1 = 1.00000000;
	this.anime.vertex_blue1 = 1.00000000;
	this.anime.vertex_red1 = 1.00000000;
	this.anime.vertex_green1 = 1.00000000;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.anime.radius0 *= 1.10000002;
				this.anime.left += 1.50000000;
			};
		}
	];
	this.stateLabel = function ()
	{
		this.rx += 0.01000000 * 0.01745329;
		this.alpha += 0.02500000;
		this.anime.left += 1.50000000;
	};
}

function Climax_ClowdSpark( t )
{
	this.SetMotion(4907, 5 + this.rand() % 2);
	this.DrawScreenActorPriority(115);
	this.rz = this.rand() % 360 * 0.01745329;
	this.sx = this.sy = t.scale;
}

function Climax_ClowdSparkB( t )
{
	this.SetMotion(4907, 5 + this.rand() % 2);
	this.DrawScreenActorPriority(130);
	this.rz = this.rand() % 360 * 0.01745329;
	this.sx = this.sy = t.scale;
}

function Climax_Cut( t )
{
	this.SetMotion(4907, 0);
	this.DrawScreenActorPriority(120);
	this.red = this.green = this.blue = 0.00000000;
	this.sx = this.sy = 4.00000000;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		},
		function ()
		{
			this.stateLabel = function ()
			{
				this.sx = this.sy *= 1.20000005;
			};
		}
	];
	this.flag1 = 600;
	this.flag2 = 0.00000000;
	this.flag3 = 100;
	this.rz = -150 * 0.01745329;
	this.stateLabel = function ()
	{
		this.count++;

		if (this.count >= 20)
		{
			this.red = this.green = this.blue += 0.00250000;
		}

		if (this.red > 1.00000000)
		{
			this.red = this.green = this.blue = 1.00000000;
		}

		local s_ = (1.00000000 - this.sx) * 0.01500000;

		if (s_ > -0.00100000)
		{
			s_ = -0.00100000;
		}

		this.sx = this.sy += s_;
		this.flag2 = -2.00000000 * (this.sx - 0.97500002);
		this.flag1 += this.flag2;
		local r_ = this.rz * 0.01000000;

		if (r_ > -0.05000000 * 0.01745329)
		{
			r_ = -0.05000000 * 0.01745329;
		}

		this.rz -= r_;
		this.Warp(640 + this.flag1 * this.cos(this.rz + 90 * 0.01745329) * this.direction, this.flag3 + this.flag1 * this.sin(this.rz + 90 * 0.01745329));
		this.flag3 -= 0.10000000;
	};
}

function Climax_Lightning( t )
{
	this.SetMotion(4908, 0);
	this.keyAction = this.ReleaseActor;
	this.sx = 0.75000000 + this.rand() % 50 * 0.01000000;
	this.sy = 1.00000000 + this.rand() % 50 * 0.01000000;
	this.rz = (10 - this.rand() % 21) * 0.01745329;
}

function Climax_HitBox( t )
{
	this.SetMotion(4908, 1);
	this.atkRate_Pat = t.rate;
	this.cancelCount = 99;
	this.func = [
		function ()
		{
			this.ReleaseActor();
		}
	];
	this.stateLabel = function ()
	{
		this.HitCycleUpdate(10);
	};
}

