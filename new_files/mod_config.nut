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
this.item <- [
	//misc
	"misc.hide_wip",
	"misc.skip_intro",
	//network
	"network.hide_opponent_name",
	"network.hide_ip",
	"network.share_watch_ip",
	"network.hide_profile_pictures",
	"network.auto_lobby_state_switch",
	//ping display
	"ping.enabled",
	"ping.X",
	"ping.Y",
	"ping.SY",
	"ping.SY",
	"ping.red",
	"ping.green",
	"ping.blue",
	"ping.alpha",
	"ping.input_delay",
	//frame data
	"frame_data.enabled",
	"frame_data.input_flags",
	"frame_data.frame_stepping",
	"frame_data.X",
	"frame_data.Y",
	"frame_data.SX",
	"frame_data.SY",
	"frame_data.red",
	"frame_data.green",
	"frame_data.blue",
	"frame_data.alpha",
	"frame_data.timer",
	//input display 1
	"input_display.p1.enabled",
	"input_display.p1.X",
	"input_display.p1.Y",
	"input_display.p1.SX",
	"input_display.p1.SY",
	"input_display.p1.offset",
	"input_display.p1.list_max",
	"input_display.p1.red",
	"input_display.p1.green",
	"input_display.p1.blue",
	"input_display.p1.alpha",
	"input_display.p1.timer",
	"input_display.p1.notation",
	//input_display 2
	"input_display.p2.enabled",
	"input_display.p2.X",
	"input_display.p2.Y",
	"input_display.p2.SX",
	"input_display.p2.SY",
	"input_display.p2.offset",
	"input_display.p2.list_max",
	"input_display.p2.red",
	"input_display.p2.green",
	"input_display.p2.blue",
	"input_display.p2.alpha",
	"input_display.p2.timer",
	"input_display.p2.notation"
];

this.data <- [];
this.page <- [];
this.cursors <- {};
this.cur_page <- -1;
this.cur_index <- -1;

this.anime <- {};
::manbow.compilebuffer("mod_config_animation.nut", this.anime);
::manbow.compilebuffer("mod_config_proc.nut",this);
function Initialize(){
	::loop.Begin(this);
	local page_num = 0;
	local page_index = 0;
	local history = [];

	foreach(i, v in this.item){
		local path = split(this.item[i],".");
		local key = path.pop();
		local value = ::setting;

		//unless someone adds a repeated config entry this should properly create
		//pages with their respective indexes
		if(!history.len() || history[0] != path[0]){
			page_num++;
			page_index = 0;
			history = path;
		}
		foreach(i,v in path){
			value = value[v];
		}
		value = value[key];
		local t = {};
		t.section <- v.slice(0,v.len()-key.len()-1);
		t.page <- page_num;
		t.index <- ++page_index;
		t.key <- key;
		t.value <- value;
		this.data.append(t);
	};
	local current_page = -1;
	foreach( i, v in this.data){
		if( current_page != v.page){
			current_page = v.page;
			this.page.append([]);
		}
		this.page.top().append(v);
	}
	this.cursor <- this.Cursor(0, this.page[0].len(), ::input_all);
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
		local prev = this.cursor.val;
		this.cursor <- this.Cursor(0, this.page[this.cursor_page.val].len(), ::input_all);
		this.cursor.se_ok = 0;
		this.cursor.val = this.cursor.item_num <= prev ? this.cursor.item_num - 1 : prev;
	}

	this.cursor.Update();

	if (this.cursor.ok)
	{
		local true_index = this.cursor.val;
		for(local i = 0; i < this.cursor_page.val; ++i){
			true_index += this.page[i].len();
		}
		local cur_item = this.item[true_index];
		if (cur_item in this.proc){
			this.proc[cur_item].call(this);
		}
		return;
	}
	else if (this.cursor.cancel)
	{
		::loop.End();
	}
}