class main extends ::battle.ModifierClass {
	watchlist = null;
	watcher = class  {
		buffer = null;
		last_frame = null;
		len = null;
		target = null;
		// Diff = class {
		// 	changes = null;
		// 	constructor(){
		// 		changes = {
		// 			slave = {}
		// 			combo = {}
		// 			master = {}
		// 			input = {}
		// 			current = {}
		// 		};
		// 	}
		// }

		mask = @(){
			slave = {}
			combo = {}
			master = {}
			input = {}
			current = {}
		};


		constructor(tgt,_len) {
			len = _len;
			buffer = [];
			target = tgt;
			local type = typeof target;
			// iterator = type == "instance" || type.find("@") ? target.getclass() : target;
		}

		// function snapshot(obj) {
		// 	local snap = mask();
		// 	foreach(k,v in snap) {

		// 	}
		// 	foreach(k,v in iterator) {
		// 		local type = typeof obj[k];
		// 		if (type != "function" &&
		// 			type != "class"
		// 		) {
		// 			if (k in obj) snap[k] <- obj[k];
		// 		}
		// 	}
		// 	return snap;
		// }



		// function track(obj) {
		// 	local type = typeof obj;
		// 	local iter = type == "instance" || type.find("@") ? obj.getclass() : obj;
		// 	foreach (k,_ in iter){
		// 		type = typeof obj[k];
		// 		// if (type == "instance" || type == "table" || type.find("@"))::print(::format("track@%s\n", k + ""));
		// 	}
		// }

		// function merge(lhs,rhs) {
		// 	foreach(k,v in lhs) {
		// 		if (k in rhs){
		// 			local type = typeof v;
		// 			if (type == "table") {
		// 				merge(lhs[k], rhs[k]);
		// 				continue;
		// 			}
		// 			// ::print(::format("%s:%s=>%s\n", k, rhs[k] + "", v + ""));
		// 			rhs[k] = v;
		// 		}
		// 	}
		// }

		function snapshot(obj,mask) {
			local snap = mask;
			local iterator = typeof obj == "table" ? obj : obj.getclass();
			foreach(k,v in iterator) {
				if (k in snap) {
					snap[k] = snapshot(obj[k], mask[k]);
					continue;
				}
				snap[k] <- obj[k];
			}
			return snap;
		}

		function get_diff(new_snap,prev_snap,mask) {
			local diff = mask;
			if (prev_snap) {
				foreach(k,v in prev_snap) {
					if (k in mask) {
							diff[k] = get_diff(new_snap[k], prev_snap[k], mask[k]);
							continue;
					}else {
						if (new_snap[k] != v) {
							diff[k] <- {
							    prev = v,
							    new = new_snap[k]
							}; //Diff(v, new_snap[k]);
						}
					}
				}
			}
			return diff;
		}

		// function diff() {
		// 	local snap = {};
		// 	foreach(k, _ in iterator) snap[k] <- target[k];
		// 	local empty = true;
		// 	if (last_frame) {
		// 		local diff = mask();
		// 		foreach(k,v in last_frame) {
		// 			if (snap[k] != v) {
		// 				diff[k] <- {prev = v, new = snap[k]};
		// 				empty = false;
		// 			}
		// 		}

		// 		last_frame = snap;
		// 		return !empty ? diff : null;
		// 	}
		// 	last_frame = snap;
		// 	return null;
		// }

		// function store() {
		// 	local d = diff();
		// 	if (d) buffer.insert(0, d);
		// 	if (buffer.len() != 0) {
		// 		local diff = len - buffer.len();
		// 		if (diff) {
		// 			if (diff > 0) {
		// 				local last = clone buffer.top();
		// 				while (diff-- > 0) buffer.append(last);
		// 			}else {
		// 				while (diff++ < 0) buffer.pop();
		// 			}
		// 		}
		// 	}
		// }

		function store() {
			local snap = snapshot(target, mask())
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

		// function restore(frames) {
		// 	::print("rolling back "+frames+" frames\n");
		// 	local i = ::math.clamp(frames, 0, len);
		// 	while (i-- > 0) {
		// 		foreach(k, diff in buffer.pop()) {
		// 			target[k] = diff.prev;
		// 		}
		// 	}
		// 	// local new_timeline = null;
		// 	// while (i-- > 0) new_timeline = buffer.pop();
		// 	// if (new_timeline) merge(new_timeline, target);
		// }

		function apply_diff(diff,tgt,mask) {
			foreach (k, d in diff) {
				if (k in mask) {
					::print("jumping to " + k + "\n");
					apply_diff(d, tgt[k],mask[k]);
					continue;
				}
				::print(::format("rolling back %s to %s\n", k, d.prev + ""));
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

	// function Snapshot(obj) {
	// 	local snap = {};
	// 	foreach(k,v in obj) {
	// 		snap[k] <- v;
	// 	}
	// 	return snap;
	// }

	// function diff(crnt) {
	// 	local snap = {};
	// 	foreach(k, v in crnt) snap[k] <- crnt[k];

	// 	local diff = {};
	// 	foreach(k,v in last_frame) {
	// 		if (snap[k] != v)diff[last_frame[k]] <- {prev = v, new = snap[k]};
	// 	}

	// 	last_frame = snap;
	// 	return diff;
	// }

	function Begin() {
		::print("are you doing anything??\n");
	}

	function PreFrame() {
		return true;
	}

	// function DumpMask(obj) {
	// 	local output = {};
	// 	local type = typeof obj;
	// 	local iter = type == "instance" || type.find("@") ? obj.getclass() : obj;
	// 	foreach(k,_ in iter) {
	// 		local tp = typeof obj[k];
	// 		if (tp == "integer") output[k] <- 0;
	// 		if (tp == "float") output[k] <- 6.9;
	// 		if (tp == "string") output[k] <- "";
	// 		if (tp == "bool") output[k] <- false;
	// 		if (tp == "null") output[k] <- null;
	// 		if (tp == "instance" || tp == "table" || tp.find("@")) {
	// 			output[k] <- {};
	// 			local _iter = type == "table" ? obj[k] : obj[k].getclass();
	// 			foreach(_k,__ in _iter) {
	// 				tp = typeof obj[k];
	// 				if (tp == "integer") output[k][_k] <- 0;
	// 				if (tp == "float") output[k][_k] <- 6.9;
	// 				if (tp == "string") output[k][_k] <- "";
	// 				if (tp == "bool") output[k][_k] <- false;
	// 				if (tp == "null") output[k][_k] <- null;
	// 				if (tp == "instance" || tp == "table" || tp.find("@")) output[k][_k] <- {};
	// 			}
	// 		}
	// 	}
	// }

	function Update() {
		if(::input_all.b7 == 1) {
			::print("rollback?\n");
			foreach (obj in watchlist) {
				// obj.track(::battle.team[0].current);
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
