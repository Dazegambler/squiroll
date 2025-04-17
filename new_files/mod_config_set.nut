//.pat files are cursed so we're just hardcoding what
//they're translated to directly in squirrel
//blame tasofro
// this.anime_set <- {
//     title = {
//         name = "title";
//         texture_name = "";
//         width = 192;
//         height = 64;
//         left = 0;
//         top = 448;
//         offset_y = 0;
//         offset_x = 0;
//         scale_x = 1.0;
//         scale_y = 1.0;
//         point = [];
//     }
// };

this.item_table <- {};
this.item_table["network"] <- {
	hide_opponent_name = {
		text = "hide oppponent name";
		values = ["disable","enable"];
	};
	hide_ip = {
		text = "hide ip";
		values = ["disable","enable"];
	};
	share_watch_ip = {
		text = "share watch ip";
		values = ["disable","enable"];
	};
	hide_profile_pictures = {
		text = "hide profile pictures";
		values = ["disable","enable"];
	};
	auto_lobby_state_switch = {
		text = "auto host/auto search";
		values = ["disable","enable"];
	};
};
this.item_table["ping"] <- {
	enabled = {
		text = "enabled";
		values = ["disable","enable"];
	};
	X = {
		text = "X";
	};
	Y = {
		text = "Y";
	};
	SX = {
		text = "scale X";
	};
	SY = {
		text = "scale Y";
	};
	red = {
		text = "red";
	};
	green = {
		text = "green";
	};
	blue = {
		text = "blue";
	};
	alpha = {
		text = "alpha";
	};
	input_delay = {
		text = "show input delay";
		values = ["disable","enable"];
	};
};
this.item_table["frame_data"] <- {
	enabled = {
		text = "enabled";
		values = ["disable","enable"];
	};
	input_flags = {
		text = "show flags";
		values = ["disable","enable"];
	};
	frame_stepping = {
		text = "manual frame stepping";
		values = ["disable","enable"];
	};
	framebar = {
		text = "framebar";
		value = ["disabled","enabled"];
	};
	X = {
		text = "X";
	};
	Y = {
		text = "Y";
	};
	SX = {
		text = "scale X";
	};
	SY = {
		text = "scale Y";
	};
	red = {
		text = "red";
	};
	green = {
		text = "green";
	};
	blue = {
		text = "blue";
	};
	alpha = {
		text = "alpha";
	};
	timer = {
		text = "timer";
	};
};
this.item_table["input_display::p1"] <- {
	enabled = {
		text = "enabled";
		values = ["disable","enable"];
	};
	input_flags = {
		text = "show flags";
		values = ["disable","enable"];
	};
	frame_count = {
		text = "display input duration";
		values = ["disable","enable"];
	};
	offset = {
		text = "offset";
	};
	list_max = {
		text = "display max";
	};
	notation = {
		text = "notation";
	};
	X = {
		text = "X";
	};
	Y = {
		text = "Y";
	};
	SX = {
		text = "scale X";
	};
	SY = {
		text = "scale Y";
	};
	red = {
		text = "red";
	};
	green = {
		text = "green";
	};
	blue = {
		text = "blue";
	};
	alpha = {
		text = "alpha";
	};
	timer = {
		text = "timer";
	};
};
this.item_table["input_display::p2"] <- {
	enabled = {
		text = "enabled";
		values = ["disable","enable"];
	};
	input_flags = {
		text = "show flags";
		values = ["disable","enable"];
	};
	frame_count = {
		text = "display input duration";
		values = ["disable","enable"];
	};
	offset = {
		text = "offset";
	};
	list_max = {
		text = "display max";
	};
	notation = {
		text = "notation";
	};
	X = {
		text = "X";
	};
	Y = {
		text = "Y";
	};
	SX = {
		text = "scale X";
	};
	SY = {
		text = "scale Y";
	};
	red = {
		text = "red";
	};
	green = {
		text = "green";
	};
	blue = {
		text = "blue";
	};
	alpha = {
		text = "alpha";
	};
	timer = {
		text = "timer";
	};
};