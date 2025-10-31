class main extends ::battle.ModifierClass {
	watchlist = null;
	watcher = class  {
		buffer = null;
		last_frame = null;
		len = null;
		target = null;
		mask = @(){
			slave = {}
			master = {}
			current = {}
			combo = {}
			input = {}
		};
		

		constructor(tgt,_len) {
			len = _len;
			buffer = [];
			target = tgt;
			local actor_copy = function (actor) {
				local snap = {};
				local iter = actor.getclass();
				foreach (k,v in iter) {
					if (k == "__getTable")continue;
					if (k != "__setTable") {
						snap[k] <- actor[k];
					}else {
						foreach (_k,_ in iter[k]) {
							snap[_k] <- actor[_k];
						}
					}
				}
				return snap;
			};
		}

		function snapshot(obj,mask) {
			local snap = mask;
			local iter = typeof obj == "table" ? obj : obj.getclass();
			foreach(k,_ in iter) {
				if (k in snap) {
					snap[k] <- snapshot(obj[k],snap[k]);
					continue;
				}
				if (k == "__getTable")continue;
				if (k == "__setTable") {
					foreach(ke,_ in iter[k])snap[ke] <- obj[ke];
					continue;
				}
				snap[k] <- obj[k];
			}
			return snap;
		}

		function get_diff(snap,last,mask) {
			local diff = mask;
			if (last) {
				foreach(k,_ in last) {
					if (k in mask) {
						diff[k] = get_diff(snap[k], last[k], diff[k]);
						continue;
					}
					if (snap[k] != last[k]) {
						diff[k] <- {
							prev = last[k],
							new = snap[k]
						};
					}
				}
				return diff;
			}
			return snap;
		}

		function store() {
			local snap = snapshot(target,mask());
			buffer.insert(0, get_diff(snap,last_frame,mask()));
			local diff = len - buffer.len();
			if (diff) {
				if (diff > 0) {
					local last = clone buffer.top();
					while (diff-- > 0) buffer.append(last);
				}else {
					while (diff++ < 0) buffer.pop();
				}
			}
			last_frame = snap;
		}

		function apply_diff(diff,tgt,mask) {
			foreach (k, d in diff) {
				if (k in mask) {
					//::print("jumping to " + k + "\n");
					apply_diff(d, tgt[k],mask[k]);
					continue;
				}
				//::print(::format("rolling back %s to %s\n", k, d.prev + ""));
				tgt[k] = d.prev;
			}
		}

		function restore(frames) {
			::print("rolling back "+frames+" frames\n");
			local i = ::math.clamp(frames, 0, len);
			while (i-- > 0) apply_diff(buffer.pop(), target, mask());
		}

	}

	constructor() {
		watchlist = [];
		watchlist.append(watcher(::battle.team[0],16));
	}

	function Begin() {
		::print("are you doing anything??\n");
	}

	function PreFrame() {
		return true;
	}

	function Update() {
		if(::input_all.b7 == 1) {
			foreach (obj in watchlist) {
				obj.restore(8);
			}
		}
	}

	function PostFrame() {
		foreach (obj  in watchlist) obj.store();
	}

	function Release() {}
}
::battle.modifiers.rollback <- ::battle.Modifier(main,false,function (param) {
	return true;
});
