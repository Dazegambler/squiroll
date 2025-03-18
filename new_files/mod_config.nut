this.help <- [
	"B1",
	"ok",
	null,
	"B2",
	"return",
	null,
	"UD",
	"select",
	null,
	"LR",
	"page"
];

//put general configs first
// this.item <- [
// 	//misc
// 	"misc.hide_wip",
// 	"misc.skip_intro",
// 	//network
// 	"network.hide_opponent_name",
// 	"network.hide_ip",
// 	"network.share_watch_ip",
// 	"network.hide_profile_pictures",
// 	"network.auto_lobby_state_switch",
// 	//ping display
// 	"ping.enabled",
// 	"ping.X",
// 	"ping.Y",
// 	"ping.SY",
// 	"ping.SY",
// 	"ping.red",
// 	"ping.green",
// 	"ping.blue",
// 	"ping.alpha",
// 	"ping.input_delay",
// 	//frame data
// 	"frame_data.enabled",
// 	"frame_data.input_flags",
// 	"frame_data.frame_stepping",
// 	"frame_data.X",
// 	"frame_data.Y",
// 	"frame_data.SX",
// 	"frame_data.SY",
// 	"frame_data.red",
// 	"frame_data.green",
// 	"frame_data.blue",
// 	"frame_data.alpha",
// 	"frame_data.timer",
// 	//input display 1
// 	"input_display.p1.enabled",
// 	"input_display.p1.X",
// 	"input_display.p1.Y",
// 	"input_display.p1.SX",
// 	"input_display.p1.SY",
// 	"input_display.p1.offset",
// 	"input_display.p1.list_max",
// 	"input_display.p1.red",
// 	"input_display.p1.green",
// 	"input_display.p1.blue",
// 	"input_display.p1.alpha",
// 	"input_display.p1.timer",
// 	"input_display.p1.notation",
// 	//input_display 2
// 	"input_display.p2.enabled",
// 	"input_display.p2.X",
// 	"input_display.p2.Y",
// 	"input_display.p2.SX",
// 	"input_display.p2.SY",
// 	"input_display.p2.offset",
// 	"input_display.p2.list_max",
// 	"input_display.p2.red",
// 	"input_display.p2.green",
// 	"input_display.p2.blue",
// 	"input_display.p2.alpha",
// 	"input_display.p2.timer",
// 	"input_display.p2.notation"
// ];

this.data <- [];
this.page <- [];
this.cursors <- {};
this.cur_page <- -1;
this.cur_index <- -1;

this.anime <- {};
::manbow.compilebuffer("mod_config_animation.nut", this.anime);
::manbow.compilebuffer("mod_config_proc.nut",this);
// all you need to start a menu page on this god forsaken UI:
// in this case we're using pagers since you can always just
// have one page lol
// 1.a data array containing the page/section and key of each element
// 2.cursors for pages and indexes
// 3.a anime table to handle the ui elements
// 4.a proc table containing each function for each UI element in the page
// ?.patience/masochism
function Initialize(){
	::loop.Begin(this);
	CreatePages();
	this.cursor_index <- this.Cursor(0, this.page[0].len(), ::input_all);
	this.cursor_page <- this.Cursor(1, this.page.len(), ::input_all);
	this.cursor_page.enable_ok = false;
	this.cursor_page.enable_cancel = false;
	::menu.cursor.Activate();
	::menu.back.Activate();
	::menu.help.Set(this.help);
	this.BeginAnime();
}

function Terminate(){
	this.page.resize(0);
	this.data.resize(0);
	this.EndAnime();
	::menu.back.Deactivate(true);
	::menu.cursor.Deactivate();
	::menu.help.Reset();
}

function Update()
{
	this.cursor_page.Update();

	if (this.cursor_page.diff)
	{
		local prev = this.cursor_index.val;
		this.cursor_index <- this.Cursor(0, this.page[this.cursor_page.val].len(), ::input_all);
		this.cursor_index.se_ok = 0;
		this.cursor_index.val = this.cursor_index.item_num <= prev ? this.cursor.item_num - 1 : prev;
	}

	this.cursor_index.Update();

	if (this.cursor_index.ok)
	{
		local proc_sec = this.proc[this.cursor_page.val];
		proc_sec[this.cursor_index.val > proc_sec.len()-1 ? proc_sec.len()-1 : this.cursor_index.val].call(this);
		return;
	}
	else if (this.cursor_index.cancel)
	{
		::loop.End();
	}
}

function CreatePages(){
	local last_section = "";

	local function iterate(section,depth) {
		foreach(k,v in section){
			if(typeof(v) == "table"){
				depth += "/"+k;
				iterate(v,depth);
				continue;
			}
			if (depth != last_section){
				last_section = depth
				this.data.append([]);
			}
			if(typeof(v) == "bool")this.cursors[(depth+"/"+k)] <- this.Cursor(1,2 ::input_all);
			this.data.top().append({
				section = depth;
				key = k;
				value = v;
			});
		}
	};

	foreach(k, v in ::setting){
		if (typeof(v) != "table" || k == "misc")continue;
		iterate(_v,"/"+k);
	};
	// foreach(v in this.data)this.page.append(v);
}