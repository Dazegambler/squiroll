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

// this.item <- [
// 	[
// 		"ping_display_enabled",
// 		"ping_display_x",
// 		"ping_display_y",
// 		"ping_display_sx",
// 		"ping_display_sy",
// 		"ping_display_color",
// 		"ping_display_framedelay",
// 		null,
// 		"exit"
// 	],
// 	[
// 		"input_display_p1_enabled",
// 		"input_display_p1_x",
// 		"input_display_p1_y",
// 		"input_display_p1_sx",
// 		"input_display_p1_sy",
// 		"input_display_p1_offset",
// 		"input_display_p1_count",
// 		"input_display_p1_color",
// 		"input_display_p1_spacing",
// 		"input_display_p1_timer",
// 		"input_display_p1_notation",
// 		null,
// 		"exit"
// 	],
// 	[
// 		null,
// 		"exit"
// 	],
// ]

this.data <- [];
this.page <- [];
this.cursors <- {};
this.cur_page <- -1;
this.cur_index <- -1;

this.anime <- {};
::manbow.compilebuffer("mod_config_animation.nut", this.anime);
function Initialize(){
	//sort the configs so tables are at the end
	//use the combined size of all tables to reduce the check to one loop that can adapt to any table
	//but i end up doing a recursive search regardless
	//time to come out with a different solution
	//do while loop that once it detects a table it increases size and switches target??
	::loop.Begin(this);
	local page_num = 0;
	local configs = [];
	local parent_index = ::setting.len()-1;
	local children_index = 0;
	local cur_index = parent_index;

	foreach( k, v in ::setting){
		if(typeof(v) == "table"){
			local t = {};
			t.page <- ++page_num;
			t.table <- k;
			local i = 0;
			foreach( _k, _v in ::setting[k]){
				t.index <- i++;
				t.key <- _k;
				t.value <- _v;
			}
			this.data.append(t);
		}
	}
	this.data.sort(function (a, b){
		if ( a.page > b.page)return 1;
		else if( a.page < b.page)return -1;
		if( a.index > b.index)return 1;
		else if( a.index < b.index)return -1;
		return 0;
	});
	::debug.print_value(this.data);
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
	this.EndAnimeDelayed();
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
		this.cur_index = this.cursor.val;
		this.cur_page = this.cursor_page.val;
		local dialog_type = null;
		local cur_item = this.page[this.cur_page][this.cur_index];
		switch (typeof(cur_item.value)){
			default:
				::Dialog(2,cur_item.key,function ( ret ){
					if (ret){
						::setting[cur_item.table][cur_item.key] = ret;
					}
				});
				break;
		}
		return;
	}
	else if (this.cursor.cancel)
	{
		::loop.EndWithFade();
	}
}