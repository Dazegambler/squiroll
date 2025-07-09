function SetNeutralActor()
{
	local t_ = {};
	t_.init <- null;
	return ::actor.common_mgr.CreateActor2D(this.effect_class, 0, 0, 1.00000000, ::neutral.Init, t_);
}

function SetEventObject( x_, y_, dir_, init_, t_, mgr )
{
	local actor_ = mgr.CreateActor2D(this.effect_class, x_, y_, dir_, init_, this.table_);
	actor_.DrawActorPriority(200);
	return actor_;
}

function SetFreeObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	local a = this.CreateActor2D(this.player_effect_class, x_, y_, dir_, this.player_effect_class.FreeObjectCommonInit, t_);
	return a;
}

function SetFreeObjectStencil( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2DStencil(this.player_effect_class, x_, y_, dir_, this.player_effect_class.FreeObjectCommonInit, t_);
}

function SetFreeObjectDynamic( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2DDynamic(this.player_effect_class, x_, y_, dir_, this.player_effect_class.FreeObjectCommonInit, t_);
}

function SetShot( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	local a =  this.CreateActor2D(this.shot_class, x_, y_, dir_, this.shot_class.ShotCommonInit, t_);
	if(::battle.frame_task && this == ::battle.frame_task.team.current){
		::battle.frame_task.spawn = true;
	}
	// ::battle.rollback.actors.append(a);
	return a;
}

function SetLightShot( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2D(this.shot_class, x_, y_, dir_, this.shot_class.ShotCommonLightInit, t_);
}

function SetShotStencil( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2DStencil(this.shot_class, x_, y_, dir_, this.shot_class.ShotCommonInit, t_);
}

function SetShotDynamic( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2DDynamic(this.shot_class, x_, y_, dir_, this.shot_class.ShotCommonInit, t_);
}

function SetShotObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2D(this.collision_object_class, x_, y_, dir_, this.collision_object_class.ShotObjectCommonInit, t_);
}

function SetShotObjectStencil( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2DStencil(this.collision_object_class, x_, y_, dir_, this.collision_object_class.ShotObjectCommonInit, t_);
}

function SetAllShotObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2D(this.collision_object_class, x_, y_, dir_, this.collision_object_class.AllShotObjectCommonInit, t_);
}

function SetObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2D(this.collision_object_class, x_, y_, dir_, this.collision_object_class.ObjectActorCommonInit, t_);
}

function SetObjectStencil( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2DStencil(this.collision_object_class, x_, y_, dir_, this.collision_object_class.ObjectActorCommonInit, t_);
}

function SetCommonObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.common_mgr.CreateActor2D(this.collision_object_class, x_, y_, dir_, this.collision_object_class.ObjectActorCommonInit, t_);
}

function SetCommonObjectDynamic( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.common_mgr.CreateActor2DDynamic(this.collision_object_class, x_, y_, dir_, this.collision_object_class.ObjectActorCommonInit, t_);
}

function SetCommonFreeObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.common_mgr.CreateActor2D(this.player_effect_class, x_, y_, dir_, this.player_effect_class.FreeObjectCommonInit, t_);
}

function SetCommonFreeObjectDynamic( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.common_mgr.CreateActor2DDynamic(this.player_effect_class, x_, y_, dir_, this.player_effect_class.FreeObjectCommonInit, t_);
}

function SetCommonFreeObjectStencil( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.common_mgr.CreateActor2DStencil(this.player_effect_class, x_, y_, dir_, this.player_effect_class.FreeObjectCommonInit, t_);
}

function SetAllObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2D(this.collision_object_class, x_, y_, dir_, this.collision_object_class.AllObjectCommonInit, t_);
}

function SetBariaObject( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return this.CreateActor2D(this.collision_object_class, x_, y_, dir_, this.collision_object_class.BariaCommonInit, t_);
}

function SetCommonShot( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.common_mgr.CreateActor2D(this.shot_class, x_, y_, dir_, this.shot_class.ShotCommonInit, t_);
}

function SetCommonShotStencil( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.common_mgr.CreateActor2DStencil(this.shot_class, x_, y_, dir_, this.shot_class.ShotCommonInit, t_);
}

function Set_Shield( x_, y_, scale_, life_, time_ )
{
	local t_ = {};
	t_.init <- this.Shield_Object;
	t_.pare <- this.weakref();
	t_.life <- life_;
	t_.scale <- scale_;
	t_.count <- time_;
	return ::actor.common_mgr.CreateActor2D(this.shot_class, x_, y_, this.direction, this.shot_class.ShotCommonInit, t_);
}

function Set_BodyShield( x_, y_, scale_, life_, time_ )
{
	if (this.shield_body)
	{
		this.shield_body.func();
	}

	this.PlaySE(805);
	local t_ = {};
	t_.init <- this.BodyShield_Object;
	t_.pare <- this.weakref();
	t_.life <- life_;
	t_.scale <- scale_;
	t_.count <- time_;
	this.shield_body = ::actor.common_mgr.CreateActor2D(this.shot_class, x_, y_, this.direction, this.shot_class.ShotCommonInit, t_).weakref();
}

function SetEffect( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.effect_mgr.CreateActor2D(this.effect_class, x_, y_, dir_, this.effect_class.EF_CommonInit, t_);
}

function SetEffectStencil( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.effect_mgr.CreateActor2DStencil(this.effect_class, x_, y_, dir_, this.effect_class.EF_CommonInit, t_);
}

function SetEffectDynamic( x_, y_, dir_, init_, t_, pare_ = null )
{
	t_.init <- init_;
	t_.pare <- pare_;
	return ::actor.effect_mgr.CreateActor2DDynamic(this.effect_class, x_, y_, dir_, this.effect_class.EF_CommonInit, t_);
}

function SetStoryEffect( x_, y_, dir_, init_, t_ )
{
	t_.init <- init_;
	return ::actor.story_effect_mgr.CreateActor2D(this.effect_class, x_, y_, dir_, this.effect_class.EF_CommonInit, t_);
}

function SetTrail( motion_, keyTake_, length_ = null, width_ = null, state_ = null )
{
	local t_ = {};
	local func_ = function ( a_ )
	{
		this.SetMotion(motion_, keyTake_);

		if (a_.length != null)
		{
			this.anime.length = a_.length;
		}

		if (a_.width != null)
		{
			this.anime.radius0 = a_.width;
		}
	};
	t_.init <- func_;
	t_.owner <- this.owner.weakref();
	t_.trail <- this.weakref();
	t_.length <- length_;
	t_.width <- width_;
	local e;

	if (length_ != null)
	{
		e = this.CreateActor2DDynamic(this.player_effect_class, this.x, this.y, this.direction, this.player_effect_class.FreeObjectCommonInit, t_);
	}
	else
	{
		e = this.CreateActor2D(this.player_effect_class, this.x, this.y, this.direction, this.player_effect_class.FreeObjectCommonInit, t_);
	}

	if (state_)
	{
		e.stateLabel = state_;
	}

	this.SetParent.call(e, this, 0, 0);

	if (!this.linkObject)
	{
		this.linkObject = [
			e.weakref()
		];
	}
	else
	{
		this.linkObject.append(e.weakref());
	}

	this.DrawActorPriority(this.drawPriority);
	return e;
}

function SetCommonTrail( motion_, keyTake_, length_, width_, state_ = null )
{
	local t_ = {};
	local func_ = function ( a_ )
	{
		this.SetMotion(motion_, keyTake_);
		this.anime.length = a_.length;
		this.anime.width = a_.width;
	};
	t_.init <- func_;
	t_.owner <- this.owner.weakref();
	t_.trail <- this.weakref();
	t_.length <- length_;
	t_.width <- width_;
	local e = ::actorList_PlayerCommon.CreateActor2DTrail(this.effect_class, this.x, this.y, this.direction, this.effect_class.FreeObjectCommonInit, t_);
	this.SetParent.call(e, this, 0, 0);

	if (!this.linkObject)
	{
		this.linkObject = [
			e.weakref()
		];
	}
	else
	{
		this.linkObject.append(e.weakref());
	}

	this.DrawActorPriority(this.drawPriority);
	return e;
}

function SetTrailEffect( motion_, keyTake_, length_, width_, state_ = null )
{
	local t_ = {};
	local func_ = function ( a_ )
	{
		this.SetMotion(motion_, keyTake_);
		this.anime.length = a_.length;
		this.anime.width = a_.width;
	};
	t_.init <- func_;
	t_.trail <- this.weakref();
	t_.length <- length_;
	t_.width <- width_;
	local e = ::actorList_Effect.CreateActor2DTrail(this.effect_class, this.x, this.y, this.direction, this.effect_class.EF_CommonInit, t_);
	this.SetParent.call(e, this, 0, 0);

	if (!this.linkObject)
	{
		this.linkObject = [
			e.weakref()
		];
	}
	else
	{
		this.linkObject.append(e.weakref());
	}

	this.ConnectRenderSlot(::graphics.slot.actor, this.priority);
	return e;
}

function SetAfterImage( init_, num_, interval_ )
{
	local t_ = ::manbow.Afterimage();
	t_.Init(this, num_, interval_);
	t_.ConnectRenderSlot(::graphics.slot.actor, this.drawPriority);

	if (init_)
	{
		init_.call(t_);
	}

	this.DrawActorPriority(this.drawPriority);
	this.afterImage = t_;
}

function DelOccultAura()
{
	if (this.occultAura && this.occultAura[2])
	{
		this.occultAura[2].func[0].call(this.occultAura[2]);
	}

	this.occultAura = null;
}

function SetOccultAura( init_ )
{
	local t_ = ::manbow.Aura();
	t_.Init(this, 40, 10, 1);
	t_.ConnectRenderSlot(::graphics.slot.actor, this.drawPriority);
	this.DrawActorPriority(this.drawPriority);
	this.SetEffect(this.point0_x, this.point0_y, this.direction, this.EF_ChargeO, {}, this.weakref());

	if (init_)
	{
		init_(t_);
	}
	else
	{
		t_.blue = 0.89999998;
		t_.green = 0.00000000;
		t_.scale = 1.04999995;
	}

	local t2_ = {};
	t2_.owner <- this.weakref();
	this.occultAura = [
		t_,
		function ()
		{
			this.occultAura[0].scale = 1.20000005;
		},
		this.SetEffect(this.x, this.y, 1.00000000, this.Occult_AuraB_Core, t2_, this.weakref()).weakref()
	];
}

function ReleaseActor()
{
	if (this.linkObject)
	{
		foreach( a in this.linkObject )
		{
			if (a)
			{
				this.ReleaseActor.call(a);
			}
		}
	}

	this.Release();
}

function ReleaseTargetActor( name_ )
{
	local type_ = typeof name_;

	if (type_ == "table")
	{
		this.ReleaseActor.call(name_);
	}
	else if (type_ == "array")
	{
		foreach( a in name_ )
		{
			if (a)
			{
				this.ReleaseActor.call(a);
			}
		}
	}
	else
	{
	}
}

function ResetActorTable()
{
	::actor = ::manbow.Actor2DProcGroup();
	::actorObject = ::manbow.Actor2DProcGroup();
	::enemyID = 0;
	::objectID = 0;
	::effectID = 0;
}

function ResetNonPlayerActor()
{
	::enemyID = 0;
	::objectID = 0;
	::effectID = 0;
}

function ReleaseAllActor()
{
	this.ResetActorTable();

	if (this.actorgroup_default)
	{
		this.actorgroup_default.Clear(1 | 2 | 0 | 16 | 32 | 64 | 256 | 512 | 4096 | 8192);
	}

	if (this.actorgroup_effect)
	{
		this.actorgroup_effect.Clear(1 | 2 | 0 | 16 | 32 | 64 | 256 | 512 | 4096 | 8192);
	}
}

function ReleaseNonPlayer()
{
	this.ResetNonPlayerActor();
	this.actorgroup_default.Clear(0 | 16 | 32 | 64 | 256 | 512 | 4096 | 8192);
	this.actorgroup_effect.Clear(1 | 2 | 0 | 16 | 32 | 64 | 256 | 512 | 4096 | 8192);
}

