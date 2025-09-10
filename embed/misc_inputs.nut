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
	constructor() {
		active = false;
		lock_override = false;
		frame_lock = false;
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
			// ::sound.PlaySE("sys_ok");
			frame_lock = false;
			// ::debug.test(player);
			// ::rollback.rewind(8);
			// ::battle.rollback.NeverHappened(4);
			// local test = ::deepcopy(t0);
			// ::debug.fprint_value(::manbow,"manbow.dump");
		}
		local b8 = ::input_all.b8;
		if (b8 == 1) {
			local enabled = lock_override ? lock_override = false : !::setting.frame_data.frame_stepping;
			local now = ::date().sec;
			if (lastinput && !(now - lastinput)) {
				enabled = lock_override = !lock_override;
				lastinput = 0;
			}else lastinput = now;
			::setting.frame_data.frame_stepping = enabled;
			::setting.save("frame_data_display","frame_stepping",enabled.tostring());
		}
	}

	function PreFrame() {
		HandleInputs();
		if (::setting.frame_data.frame_stepping) {
			return !frame_lock;
		}
		return true;
	}

	function Update() {
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
