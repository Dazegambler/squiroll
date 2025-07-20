local text_table = {
	enabled = "enabled"
	X = "pos X"
	Y = "pos Y"
	SX = "scale X"
	SY = "scale Y"
	red = "color(Red)"
	green = "color(Green)"
	blue = "color(Blue)"
	alpha = "color(Alpha)"

	input_delay = "show input delay"

	timer = "duration(frames)"

	offset = "spacing"
	list_max = "input history size"
	frame_count = "show input frames"
	notation = "input notation"

	input_flags = "show move flags"
	frame_stepping = "manual frame stepping"
	framebar = "show framebar"

	hide_opponent_name = "hide names"
	hide_ip = "hide ip address"
	share_watch_ip = "share ip address"
	hide_profile_pictures = "hide profile pictures"
	auto_lobby_state_switch = "auto switch lobby state"
};
local proc_table = {
	enabled = function(){}
	X = function(){}
	Y = function(){}
	SX = function(){}
	SY = function(){}
	red = function(){}
	green = function(){}
	blue = function(){}
	alpha = function(){}

	input_delay = function(){}

	timer = function(){}

	offset = function(){}
	list_max = function(){}
	frame_count = function(){}
	notation = function(){}

	input_flags = function(){}
	frame_stepping = function(){}
	framebar = function(){}

	hide_opponent_name = function(){}
	hide_ip = function(){}
	share_watch_ip = function(){}
	hide_profile_pictures = function(){}
	auto_lobby_state_switch = function(){}
};
local config_table = {
	enabled = "enabled"
	X = "x"
	Y = "y"
	SX = "scale_x"
	SY = "scale_y"
	red = "color"
	green = "color"
	blue = "color"
	alpha = "color"

	input_delay = "frames"

	timer = "timer"

	offset = "offset"
	list_max = "count"
	frame_count = "frame_count"
	notation = "notation"

	input_flags = "input_flags"
	frame_stepping = "frame_stepping"
	framebar = "framebar"

	hide_opponent_name = "hide_name"
	hide_ip = "hide_ip"
	share_watch_ip = "share_watch_ip"
	hide_profile_pictures = "hide_profile_pictures"
	auto_lobby_state_switch = "auto_seach_host"
};
local order_input = ["enabled","X","Y","SX","SY","red","green","blue","alpha","offset","list_max","timer","frame_count","notation"];
local order_frame = ["enabled","X","Y","SX","SY","red","green","blue","alpha","timer","input_flags","framebar","frame_stepping"];
local order_ping = ["enabled","X","Y","SX","SY","red","green","blue","alpha","input_delay"];
local pages = [];
pages.extend(::UI.ToConfigMenuPage(["ping display","ping"],::setting.ping,config_table,text_table,order_ping));
pages.extend(::UI.ToConfigMenuPage(["network","network"],::setting.network,config_table,text_table));
pages.extend(::UI.ToConfigMenuPage(["live frame data","frame_data_display"],::setting.frame_data,config_table,text_table,order_frame));
pages.extend(::UI.ToConfigMenuPage(["input display(p1)","input_display_p1"],::setting.input_display.p1,config_table,text_table,order_input));
pages.extend(::UI.ToConfigMenuPage(["input display(p2)","input_display_p2"],::setting.input_display.p2,config_table,text_table,order_input));

// ::UI.InitializeConfigMenu(pages);
::UI.Menu.call(this,
	::UI.Page(
		::UI.Text("whatever"),
		::UI.Text("whatever"),
		::UI.Text("whatever"),
		::UI.Text("whatever"),
		::UI.Text("whatever"),
		// ::UI.Bool("anything"),
		// ::UI.Button("cool button",function(){
		// 	::print("*dabs");
		// }),
		::UI.Title("title")
	)
);