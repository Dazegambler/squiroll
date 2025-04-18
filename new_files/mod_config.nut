::manbow.compilebuffer("UI.nut",this);
local text_table = {
	enabled = "enabled";
	X = "pos X";
	Y = "pos Y";
	SX = "scale X";
	SY = "scale Y";
	red = "color(Red)";
	green = "color(Green)";
	blue = "color(Blue)";
	alpha = "color(Alpha)";

	input_delay = "show input delay";

	timer = "duration(frames)";

	offset = "spacing";
	list_max = "input history size";
	frame_count = "show input frames";
	notation = "input notation";

	input_flags = "show move flags";
	frame_stepping = "manual frame stepping";
	framebar = "show framebar";

	hide_opponent_name = "hide names";
	hide_ip = "hide ip address";
	share_watch_ip = "share ip address";
	hide_profile_pictures = "hide profile pictures";
	auto_lobby_state_switch = "auto switch lobby state";
 }
local function filter(k,v) {
	if (typeof(v) != "bool" &&
		typeof(v) != "integer" &&
		typeof(v) != "string" &&
		typeof(v) != "float"){
			return true;
	}
	return false;
}
local order_input = ["enabled","X","Y","SX","SY","red","green","blue","alpha","offset","list_max","timer","frame_count","notation"];
local order_frame = ["enabled","X","Y","SX","SY","red","green","blue","alpha","timer","input_flags","framebar","frame_stepping"];
local order_ping = ["enabled","X","Y","SX","SY","red","green","blue","alpha","input_delay"];
local pages = [];
pages.extend(ToMenuPage("ping display",FilterTable(::setting.ping,filter),text_table,order_ping));
pages.extend(ToMenuPage("network",FilterTable(::setting.network,filter),text_table));
pages.extend(ToMenuPage("live frame data",FilterTable(::setting.frame_data,filter),text_table,order_frame));
pages.extend(ToMenuPage("input display(p1)",FilterTable(::setting.input_display.p1,filter),text_table,order_input));
pages.extend(ToMenuPage("input display(p2)",FilterTable(::setting.input_display.p2,filter),text_table,order_input));

InitializeMenu(pages);
// this.help <- [
// 	"B1",
// 	"ok",
// 	null,
// 	"B2",
// 	"return",
// 	null,
// 	"UD",
// 	"select",
// 	null,
// 	"LR",
// 	"page"
// ];

// this.help_item <- [
// 	"B1",
// 	"ok",
// 	null,
// 	"B2",
// 	"cancel",
// 	null,
// 	"LR",
// 	"change"
// ];

// this.data <- [];
// this.cursors <- {};
// this.cur_item <- null;
// this.common_cursor <- null;
// this.common_callback_ok <- null;
// this.common_callback_cancel <- null;
// this.cur_page <- -1;
// this.cur_index <- -1;
// this.Update <- null;

// this.anime <- {};
// ::manbow.compilebuffer("mod_config_animation.nut", this.anime);
// ::manbow.compilebuffer("mod_config_proc.nut",this);
// // all you need to start a menu page on this god forsaken UI:
// // in this case we're using pagers since you can always just
// // have one page lol
// // 1.a data array containing the page/section and key of each element
// // 2.cursors for pages and indexes
// // 3.a anime table to handle the ui elements
// // 4.a proc table containing each function for each UI element in the page
// // ?.patience/masochism

// function iterate(section,depth) {
// 	local last_section = "";
// 	foreach(k,v in section){
// 		if(typeof(v) == "function")continue;
// 		if(typeof(v) == "table"){
// 			this.iterate(v,depth+"::"+k);
// 			continue;
// 		}
// 		if (depth != last_section){
// 			last_section = depth;
// 			this.data.append([]);
// 		}
// 		this.data.top().append({
// 			section = depth;
// 			key = k;
// 			value = v;
// 		});
// 		if(typeof(v) == "bool"){
// 			this.cursors[depth+"::"+k] <- this.Cursor(1,2 ::input_all);
// 		}
// 	}
// };

// function Initialize(){
// 	::loop.Begin(this);
// 	foreach(k, v in ::setting){
// 		if (typeof(v) != "table" || k == "misc")continue;
// 		iterate(v,k);
// 	};
// 	this.cursor <- this.Cursor(0, this.data[0].len(), ::input_all);
// 	this.cursor.se_ok = 0;
// 	this.cursor_page <- this.Cursor(1, this.data.len(), ::input_all);
// 	this.cursor_page.enable_ok = false;
// 	this.cursor_page.enable_cancel = false;
// 	this.cur_index = -1;
// 	this.cur_page = -1;
// 	::menu.cursor.Activate();
// 	::menu.back.Activate();
// 	::menu.help.Set(this.help);
// 	this.Update = this.UpdateMain;
// 	this.BeginAnime();
// }

// function Terminate(){
// 	this.data.resize(0);
// 	this.EndAnime();
// 	::menu.back.Deactivate(true);
// 	::menu.cursor.Deactivate();
// 	::menu.help.Reset();
// }

// function UpdateMain()
// {
// 	this.cursor_page.Update();

// 	if (this.cursor_page.diff)
// 	{
// 		local prev = this.cursor.val;
// 		this.cursor <- this.Cursor(0, this.data[this.cursor_page.val].len(), ::input_all);
// 		this.cursor.se_ok = 0;
// 		this.cursor.val = this.cursor.item_num <= prev ? this.cursor.item_num - 1 : prev;
// 	}

// 	this.cursor.Update();

// 	if (this.cursor.ok)
// 	{
// 		this.cur_item = this.data[this.cursor_page.val][this.cursor.val];
// 		if (this.cur_item.section in this.proc && this.cur_item.key in this.proc[this.cur_item.section]){
// 			this.proc[this.cur_item.section][this.cur_item.key].call(this);
// 		}
// 		return;
// 	}
// 	else if (this.cursor.cancel)
// 	{
// 		::loop.End();
// 	}
// }

// function UpdateCommonItem()
// {
// 	this.common_cursor.Update();

// 	if (this.common_cursor.ok)
// 	{
// 		this.common_callback_ok();
// 		this.Update = this.UpdateMain;
// 	}
// 	else if (this.common_cursor.cancel)
// 	{
// 		this.common_callback_cancel();
// 		this.Update = this.UpdateMain;
// 	}
// }

