//due to the sheer amount of config options we have i made all the proc functions
//be on their separate file
this.proc <- {};
this.proc["network"] <- {
	hide_opponent_name = function() {
    };
	hide_ip = function() {};
	share_watch_ip = function() {};
	hide_profile_pictures = function() {};
	auto_lobby_state_switch = function() {};
};
this.proc["ping"] <- {
	enabled = function() {};
	X = function() {};
	Y = function() {};
	SX = function() {};
	SY = function() {};
	red = function() {};
	green = function() {};
	blue = function() {};
	alpha = function() {};
	input_delay = function() {};
};
this.proc["frame_data"] <- {
	enabled = function() {
        ::menu.help.Set(this.help_item);
        this.Update = this.UpdateCommonItem;
        local cursor = this.cursors[this.cur_item.section+"::"+this.cur_item.key];
        this.common_cursor = cursor;
        this.common_callback_ok = function (){
            ::setting.frame_data.enabled = cursor.val ? true : false;
        };
        this.common_callback_cancel = function () {
            cursor.val = ::setting.frame_data.enabled ? 1 : 0;
        };
    };
	input_flags = function() {};
	frame_stepping = function() {};
	X = function() {};
	Y = function() {};
	SX = function() {};
	SY = function() {};
	red = function() {};
	green = function() {};
	blue = function() {};
	alpha = function() {};
	timer = function() {};
};
this.proc["input_display::p1"] <- {
	enabled = function() {};
	input_flags = function() {};
	frame_count = function() {};
	offset = function() {};
	list_max = function() {};
	notation = function() {};
	X = function() {};
	Y = function() {};
	SX = function() {};
	SY = function() {};
	red = function() {};
	green = function() {};
	blue = function() {};
	alpha = function() {};
	timer = function() {};
};
this.proc["input_display::p2"] <- {
	enabled = function() {};
	input_flags = function() {};
	frame_count = function() {};
	offset = function() {};
	list_max = function() {};
	notation = function() {};
	X = function() {};
	Y = function() {};
	SX = function() {};
	SY = function() {};
	red = function() {};
	green = function() {};
	blue = function() {};
	alpha = function() {};
	timer = function() {};
};