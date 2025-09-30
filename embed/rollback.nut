class main extends ::battle.ModifierClass {
	timeline = null;
	epoch = null;
	rollframes = null;
	tracking = null;
	rollback = null;

	constructor() {
		timeline = [];
		epoch = 0;
		rollframes = 8;
		tracking = [];
		rollback = false;
	}

	function TrackObjects(root) {
		local type = typeof root;
		if(
			(type == "table" ||
			type == "instance" ||
			type.find("@")) &&
			!tracking.find(root)
		) {
			tracking.append(root);
			local iterator = type == "instance" || type.find("@") ? root.getclass() : root;
			foreach(_ in iterator)TrackObjects(_);
		}else if(type == "array") {
			foreach(_ in root)TrackObjects(_);
		}
	}

	function StoreValues() {
		epoch = ::math.clamp(epoch+1,0,timeline.len());
		timeline.insert(epoch,{});
		foreach(track in tracking) {
			local copy = timeline[epoch][track] <- {};
			local iterator = typeof track == "instance" || (typeof track).find("@") ? track.getclass() : track;
			foreach(key,value in iterator) {
				if(!tracking.find(value)) {
					local type = typeof value;
					if (type == "table" ||
						type == "instance" ||
						type.find("@")
					) {
						tracking.append(value);
					}else if(
						type == "null" ||
						type == "integer" ||
						type == "float" ||
						type == "string" ||
						type == "bool"
					) {
						copy[key] <- value;
					}
				}
			}
		}
	}

	function Rollback(frames) {
		epoch = ::math.max(epoch - frames, 0);
		local new_timeline = timeline[epoch];
		foreach(tracked,values in new_timeline) {
			::print("rolling back:"+tracked+"\n");
			foreach(key,value in values)tracked[key] = value;
		}
	}

	function Begin() {
		TrackObjects(::battle.team[0]);
	}

	function PreFrame() {
		if (rollback) {
			Rollback(rollframes);
			rollback = false;
		}
		return true;
	}

	function Update() {
		TrackObjects(::battle.team[0]);
		if(::input_all.b7 == 1)rollback = true;
	}

	function PostFrame() {
		StoreValues();
	}

	function Release() {
		timeline = [];
		tracking = [];
	}
}
::battle.modifiers.rollback <- ::battle.Modifier(main,false,function (param) {
	return false;
});
