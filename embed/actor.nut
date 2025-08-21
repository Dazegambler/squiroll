this.actor_list <- {};
this.win <- [
	null,
	null
];
this.effect_mgr <- null;
this.common_mgr <- null;
this.story_effect_mgr <- null;
this.effect_class <- null;
::manbow.CompileFile("data/actor/initialize.nut", this);
function Initialize()
{
	this.effect_mgr = ::manbow.Actor2DManager();
	this.common_mgr = this.manbow.Actor2DManager();
	this.story_effect_mgr = null;
	this.effect_mgr.LoadAnimationData("data/actor/effect/effect.pat", null);
	this.common_mgr.LoadAnimationData("data/actor/common/common.pat", null);
}

function CreatePlayer( actor_name, src_name, color, mode, difficulty )
{
	local t = {};
	this.actor_list[actor_name] <- t;
	local mgr = ::manbow.Actor2DManager();
	local pat_name = "data/actor/" + src_name + "/" + src_name + ".pat";
	local palette_name = "data/actor/" + src_name + "/palette" + (color < 100 ? "0" : "") + (color < 10 ? "0" : "") + color + ".bmp";
	mgr.LoadAnimationData(pat_name, palette_name);
	::sound.LoadSE("data/se/" + src_name + ".csv");
	t.mgr <- mgr;
	t.name <- src_name;
	t.color <- color;
	t.mode <- mode;
	t.difficulty <- difficulty;
	this.DefinePlayerClass(t);
	//player patches
	local setmotion = t.player_class.SetMotion;
	t.player_class.SetMotion <- function (motion,take) {
		setmotion(motion,take);
		local frame_data = ::battle.frame_task;
		if (frame_data &&
			frame_data.team == this.team &&
			frame_data.current_data
		) {
			if (frame_data.current_data.motion != this.motion &&
				frame_data.current_data.take >= this.keyTake
			){
				if (this.motion >= 1000) {
					frame_data.IsNewMove();
				}else {
					frame_data.current_data.motion = this.motion;
				}
			}
		}
	};
	local setshot = t.player_class.SetShot;
	t.player_class.SetShot <- function (x_, y_, dir_, init_, t_, pare_ = null) {
		local a = setshot(x_,y_, dir_,init_,t_,pare_);
		if (::setting.frame_data.enabled) {
			local frame_data = ::battle.frame_task;
			if(frame_data &&
				"current" in frame_data.team &&
				frame_data.team.current &&
				this == frame_data.team.current
			) {
				::battle.frame_task.bullets.append(a);
			}
		}
		return a;
	};
	local setshotstencil = t.player_class.SetShotStencil;
	t.player_class.SetShotStencil <- function (x_, y_, dir_, init_, t_, pare_ = null) {
		local a = setshotstencil(x_,y_, dir_,init_,t_,pare_);
		if (::setting.frame_data.enabled) {
			local frame_data = ::battle.frame_task;
			if(frame_data &&
				"current" in frame_data.team &&
				frame_data.team.current &&
				this == frame_data.team.current
			) {
				::battle.frame_task.bullets.append(a);
			}
		}
		return a;
	};
	local setobject = t.player_class.SetObject;
	t.player_class.SetObject <- function (x_, y_, dir_, init_, t_, pare_ = null) {
		local a = setobject(x_,y_, dir_,init_,t_,pare_);
		if (::setting.frame_data.enabled) {
			local frame_data = ::battle.frame_task;
			if(frame_data &&
				"current" in frame_data.team &&
				frame_data.team.current &&
				this == frame_data.team.current
			) {
				::battle.frame_task.bullets.append(a);
			}
		}
		return a;
	};
	// local endtofreemove = t.player_class.EndtoFreeMove;
	// t.player_class.EndtoFreeMove <- function () {
	// 	endtofreemove();
	// 	local frame_data = ::battle.frame_task;
	// 	if(frame_data &&
	// 		"current" in frame_data.team &&
	// 		frame_data.team.current &&
	// 		this == frame_data.team.current
	// 	){
	// 		frame_data.current_data.motion = 1337;
	// 		// ::battle.frame_task.bullets.append(a);
	// 	}
	// };

	//rollback patches
	// ::manbow.CompileFile("actor_rollback.nut",t.player_class);
	//bullet patches;
	// ::manbow.CompileFile("actor_rollback.nut",t.shot_class);
	local releaseactor = t.shot_class.ReleaseActor;
	t.shot_class.ReleaseActor <- function () {
		local frame_data = ::battle.frame_task;
		if (::setting.frame_data.enabled &&
			frame_data) {
			local idx = frame_data.bullets.find(this);
			if (idx)frame_data.bullets.remove(idx);
		}
		if (::battle.rollback.IsStored(this))return;
		releaseactor();
	};
	local setshot = t.shot_class.SetShot;
	t.shot_class.SetShot <- function (x_, y_, dir_, init_, t_, pare_ = null) {
		local a = setshot(x_,y_, dir_,init_,t_,pare_);
		local frame_data = ::battle.frame_task;
		if(	::setting.frame_data.enabled &&
			frame_data &&
			"current" in frame_data.team &&
			frame_data.team.current &&
			this.owner == frame_data.team.current
		) {
			::battle.frame_task.bullets.append(a);
		}
		return a;
	};
	return t;
}

function ClonePlayer( actor_name, src_data, mode, difficulty )
{
	local t = {};
	this.actor_list[actor_name] <- t;
	t.mgr <- src_data.mgr;
	t.name <- src_data.name;
	t.color <- src_data.color;
	t.mode <- mode;
	t.difficulty <- difficulty;
	this.DefinePlayerClass(t);
	return t;
}

function ReleasePlayer( name )
{
	if (name in this.actor_list)
	{
		delete this.actor_list[name];
	}
}

function ResetPlayer( name )
{
	if (!(name in this.actor_list))
	{
		return;
	}

	local t = this.actor_list[name];
	this.DefinePlayerClass(t);
}

function DefinePlayerClass( t )
{
	local name = t.name;
	local player_class = ::manbow.Actor2D.DerivedClass();
	this.PlayerClassDef(player_class);
	local shot_class = ::manbow.Actor2D.DerivedClass();
	this.ShotClassDef(shot_class);
	local collision_object_class = ::manbow.Actor2D.DerivedClass();
	this.CollisionObjectClassDef(collision_object_class);
	local player_effect_class = ::manbow.Actor2D.DerivedClass();
	this.PlayerEffectClassDef(player_effect_class);
	t.player_class <- player_class;
	t.shot_class <- shot_class;
	t.collision_object_class <- collision_object_class;
	t.player_effect_class <- player_effect_class;
	::manbow.CompileFile("data/actor/" + t.name + "_init.nut", t);

	switch(t.mode)
	{
	case 1:
		player_class.difficulty <- t.difficulty;
		::manbow.CompileFile("data/actor/" + t.name + "_com.nut", t);
		break;

	case 3:
		player_class.difficulty <- t.difficulty;
		::manbow.CompileFile("data/actor/" + t.name + "_practice_init.nut", t);
		break;

	case 2:
		player_class.difficulty <- t.difficulty;
		::manbow.CompileFile("data/actor/" + t.name + "_boss_init.nut", t);
		break;

	case 4:
		::manbow.CompileFile("data/actor/" + t.name + "_tutorial_init.nut", t);
		break;
	}
}

function Clear()
{
	foreach( v in this.actor_list )
	{
		v.mgr.SetGroup(null);
	}

	this.actor_list <- {};
	this.common_mgr.SetGroup(null);
	this.effect_mgr.SetGroup(null);

	if (this.story_effect_mgr)
	{
		this.story_effect_mgr.SetGroup(null);
	}

	this.win = [
		null,
		null
	];
	::sound.CacheSE(true);
	::sound.ResetSE();
}

function SetGroup( _actor, _effect )
{
	foreach( v in this.actor_list )
	{
		v.mgr.SetGroup(_actor);
	}

	this.common_mgr.SetGroup(_actor);
	this.effect_mgr.SetGroup(_effect);

	if (this.story_effect_mgr)
	{
		this.story_effect_mgr.SetGroup(_effect);
	}
}

function InitializeStoryEffect()
{
	this.story_effect_mgr = this.manbow.Actor2DManager();
}

function AddStoryEffect( filename )
{
	this.story_effect_mgr.LoadAnimationData(filename, null);
}

function LoadAnimationData( filename, enable_index = false )
{
	local src = {};
	::manbow.LoadJSONtoTable(filename, src);
	local take = {};
	local dir = filename;
	local offset = 0;

	while (true)
	{
		local t = filename.find("/", offset);

		if (t)
		{
			offset = t + 1;
		}
		else
		{
			break;
		}
	}

	dir = filename.slice(0, offset);

	foreach( v in src.take )
	{
		if (v.layer.len() == 0)
		{
			continue;
		}

		local t = {};
		t.name <- v.name;
		local element = v.layer[0].element[0];
		t.texture_name <- dir + element.name;
		t.offset_x <- element.cx;
		t.offset_y <- element.cy;
		t.scale_x <- element.sx / 100.00000000;
		t.scale_y <- element.sy / 100.00000000;
		t.left <- element.left;
		t.top <- element.top;
		t.height <- element.height;
		t.width <- element.width;
		t.point <- "point" in v.frame[0] ? v.frame[0].point : [];

		if (v.is_child)
		{
		}
		else if (enable_index)
		{
			take[v.id] <- t;
		}
		else
		{
			take[v.name] <- t;
		}
	}

	return take;
}

function CreateActor( anime_set, take, sub_take, mat_world, priority )
{
}

function SetEffect( x, y, dir, init, t, pare = null )
{
	t.init <- init;
	t.pare <- pare;
	return this.effect_mgr.CreateActor2D(this.effect_class, x, y, dir, this.effect_class.EF_CommonInit, t);
}

function SetEffectLight( x, y, motion, take = 0 )
{
	local a = ::actor.effect_mgr.CreateActor2D(this.effect_class, x, y, 1, null, null);
	a.SetMotion(motion, take);
	a.ConnectRenderSlot(::graphics.slot.info, 10);
	a.SetEndTakeCallbackFunction(function ()
	{
		this.Release();
	});
	a.Update();
}

function SetStoryEffect( x, y, dir, init, t, pare = null )
{
	t.init <- init;
	t.pare <- pare;
	return this.story_effect_mgr.CreateActor2D(this.effect_class, x, y, dir, this.effect_class.EF_CommonInit, t);
}

