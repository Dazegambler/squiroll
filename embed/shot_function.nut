function ShotCommonInit( t )
{
	this.actorType = 2;
	this.target = this.owner.team.target.weakref();
	this.initTable = t;
	this.vf = this.Vector3();
	this.va = this.Vector3();
	this.vfBaria = this.Vector3();
	this.hitTarget = {};
	this.hitOwner = this.weakref();
	this.DrawActorPriority(200);
	this.SetUpdateFunction(this.Shot_CommonUpdate);
	this.SetEndTakeCallbackFunction(this.KeyActionCheck);
	this.SetEndMotionCallbackFunction(this.ReleaseActor);
	this.SetContactTestCallbackFunction(this.StoreShotActorData);
	this.SetTeamShot();

	if (t.init)
	{
		t.init.call(this, t);
	}
}

function ShotCommonLightInit( t )
{
	this.actorType = 2;
	this.target = this.owner.team.target.weakref();
	this.initTable = t;
	this.vf = this.Vector3();
	this.va = this.Vector3();
	this.vfBaria = this.Vector3();
	this.hitTarget = {};
	this.hitOwner = this.weakref();
	this.DrawActorPriority(200);
	this.SetUpdateFunction(this.Shot_LightUpdate);
	this.SetEndTakeCallbackFunction(this.KeyActionCheck);
	this.SetEndMotionCallbackFunction(this.ReleaseActor);
	this.SetContactTestCallbackFunction(this.StoreShotActorData);
	this.SetTeamShot();

	if (t.init)
	{
		t.init.call(this, t);
	}
}

function KeyActionRelease()
{
	this.ReleaseActor();
}

function Damage_ConvertOP( x_, y_, num_, dLv_ = 1 )
{
	if (this.team.current.IsDamage() >= dLv_)
	{
		local t_ = {};
		t_.num <- num_;
		this.SetFreeObject(x_, y_, 1.00000000, this.Occult_PowerCreatePoint, t_);
		return true;
	}
}

