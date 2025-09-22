// local test = ::font.CreateSystemString(" \f");
// ::print(format("width:%d\n",test.width - 12));
//'b' 19
//'B' 20
//'d' 19
//'D' 23
//'s' 16
//'S' 19
//'c' 17
//'C' 21
//'#' 23
//' ' 7
//'~' 14
//'/' 14
//'|-' 21
//'-' 13
//'_' 14
//'|' 8
//'[]' 28
//" []" 40
//" [" 26
//" " 12
// "   " 26
class main extends ::battle.ModifierClass {
	lastinput = null;
	active = null;
	frame_lock = null;
	lock_override = null;
	timeline = null;
	epoch = null;
	constructor() {
		active = false;
		lock_override = false;
		frame_lock = false;
		timeline = [];
		epoch = 0;
	}

	function HandleInputs() {
		if (::input_all.b6 == 1) {
			local now = ::date().sec;
			if (lastinput && !(now - lastinput)) {
				if (!(active = !active)) ::battle.gauge.Hide();
				else ::battle.gauge.Show(0);
				if (::battle.modifiers.frame_data.task) ::battle.modifiers.frame_data.task.full = !active;
				lastinput = 0;
				// ::sound.PlaySE("sys_ok");
			}else lastinput = now;
		}
		local b7 = ::input_all.b7;
		if (b7 && (!(b7 % 10) || b7 == 1)) {
			::sound.PlaySE("sys_ok");
			frame_lock = false;
			// epoch -= 8;
			// merge(timeline[epoch],::battle.team[0]);
			// ::debug.test(player);
			// ::rollback.rewind(8);
			// ::battle.rollback.NeverHappened(4);
			// local test = ::deepcopy(t0);
			// ::debug.fprint_value(::manbow,"manbow.dump");
		}
		local b8 = ::input_all.b8;
		if (b8 == 1) {
			if (lock_override)lock_override = false;
			else {
				local now = ::date().sec;
				if (lastinput && !(now - lastinput)) {
					lock_override = true;
					lastinput = 0;
				}else  {
					lastinput = now;
					local enabled = !::setting.frame_data.frame_stepping;
					::setting.frame_data.frame_stepping = enabled;
					::setting.save("frame_data_display","frame_stepping",enabled.tostring());
				}
			}
		}
	}

	function copy(lhs,rhs,known = []) {
		local og_type = typeof lhs;
		if ((og_type == "table" ||
			og_type == "instance" ||
			og_type.find("@")) &&
			!known.find(lhs)
		) {
			local root = lhs;
			if (og_type == "instance" || og_type.find("@"))root = lhs.getclass();
			known.append(lhs);
			foreach(k,v in root) {
				rhs[k] <- {};
				copy(v,rhs[k],known);
			}
			return true;
		}
		if (og_type == "array") {
			rhs[k] <- [];
			foreach(i,v in lhs) {
				rhs[k].append(null);
				copy(v,rhs[k][i]);
			}
			return true;
		}
		if (og_type == "null" ||
			og_type == "integer" ||
			og_type == "float" ||
			og_type == "bool" ||
			og_type == "string"
		) {
			rhs = lhs;
			return true;
		}
		return false;
	}

	function iterate(object) {
		foreach(k,v in object) {
			if (typeof v == "table")iterate
		}
	}

	function merge(lhs,rhs) {
		local og_type = typeof lhs;
		if (og_type == "table") {
			foreach(k,v in lhs) {
				merge(v,rhs[k]);
			}
		}
		if (og_type == "array") {
			foreach(i,v in lhs) {
				merge(v,rhs[k][i]);
				return null;
			}
		}
		rhs = lhs;
	}

	function PreFrame() {
		HandleInputs();
		if (::setting.frame_data.frame_stepping) {
			return !frame_lock;
		}
		return true;
	}

	function Update() {
		// epoch = ::math.clamp(epoch+1,0,timeline.len());
		// timeline.insert(epoch,{});
		// copy(::battle.team[0],timeline[epoch]);
		local current = ::battle.team[0].current;
		frame_lock = false;
		if (!::network.IsActive() && ::setting.frame_data.frame_stepping) {
			frame_lock = lock_override;
			if (!frame_lock && ::replay.GetState() != ::replay.PLAY) {
				frame_lock = (
					current.motion >= 1000 &&
					::setting.frame_data.hasData(current) &&
					!current.hitStopTime && !current.team.time_stop_count
				);
			}
		}
	}
};
::battle.modifiers.misc_inputs <- ::battle.Modifier(main,false,function (param) {
	local enabled = (::network.IsPlaying != true);
	if (enabled) {
		if (param.game_mode == 40) {
			local practicerestart = PracticeRestart;
			function PracticeRestart() {
				modifiers.misc_inputs.task.active = true;
				practicerestart();
			}
		}
	}
	return enabled;
});
