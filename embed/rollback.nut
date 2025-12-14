local snapshot_base = function() {
	local snap = {};
	local root = getclass();
	foreach (k,_ in root) {
		if (k == "__getTable")continue;
		if (k == "__setTable") {
			foreach (k,_ in root[k]) {
				snap[k] <- this[k];
			}
			continue;
		}
		snap[k] <- this[k];
	}
	return snap;
};
local diff_base = function (new,last) {
	local table = {};
	foreach (k,_ in last) {
		if (new[k] != last[k]) {
			table[k] <- {prev=last[k],new=new[k]};
			//::print(::format("%s:%s->%s\n",k,last[k]+"",new[k]+""));
		}
	}
	return table;
};
local store_diff = function () {
	local snap = snapshot_base();
	if (!last_snap)last_snap = snap;
	if (::battle.modifiers.rollback.task)
		::battle.modifiers.rollback.task.AddDiff(this,diff_base(snap,last_snap));
	last_snap = snap;
};
//rollback hooks
::manbow.InputMulti = class extends ::manbow.InputMulti {
	last_snap = null;

	function Update() {
		base.Update();
		store_diff.call(this);
	}
};

::plugin.Patch("data/script/battle/battle_team.nut",function() {
	PlayerTeamData = class extends PlayerTeamData {
		last_snap = null;

		function Update() {
			base.Update();
			store_diff.call(this);
		}
	};
});

::plugin.Patch("data/script/actor.nut",function() {
	local prev = CreatePlayer;
	function CreatePlayer(...) {
		vargv.insert(0,this);
		local t = prev.acall(vargv);
		foreach (k in ["player_class","shot_class","player_effect_class","collision_object_class"]) {
			t[k] = class extends t[k] {
				last_snap = null;
				
				function SetUpdateFunction(func) {
					base.SetUpdateFunction(function() {
						local r = func();
						store_diff.call(this);
						return r;
					});
				}

				function ReleaseActor(...) {
					// send diff to rollback handler
					last_snap = null;
					vargv.insert(0,this);
					return base.ReleaseActor.acall(vargv);
				};
			};
		}
		return t;
	}
});

class modifier extends ModifierClass {
	buffer = null;
	max_len = null;
	len = null;
	write = null;

	constructor() {
		max_len = 64;
		buffer = [];
		for (local i = 0;i < max_len; ++i)
			buffer.append({});
		write = 0;
		len = 0;
	}

	function Begin() {
		::print("are you doing anything??\n");
	}

	function PreFrame() {
		return true;
	}
	
	function AddDiff(from,diff) {
		buffer[write][from] <- diff;
	}

	function ApplyDiff(src,diffs) {
		foreach (k,diff in diffs) {
			src[k] = diff.prev;
		}
	}

	function Rollback(frames) {
		if (len) {
			frames = ::math.min(len,frames);
			::print(frames+"f rollback\n");
			len -= frames;
			local i = frames;
			while(i-- > 0) {
				write = (write - 1) & (max_len - 1);
				foreach (src,diff in buffer[write]) {
					ApplyDiff(src,diff);
				}
			}
		}
	}

	function Update() {
		if(::input_all.b7 == 1) {
			Rollback(8);
		}
	}

	function PostFrame() {
		write = (write + 1) & (max_len - 1);
		len += (len < max_len).tointeger();
	}

	function Enabled(param) {
		return true;
	}

	function Release() {
		buffer = null;
	}
}
