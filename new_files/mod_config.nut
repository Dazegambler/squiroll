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

this.help_item <- [
	"B1",
	"ok",
	null,
	"B2",
	"cancel",
	null,
	"LR",
	"change"
];

this.data <- [];
this.cursors <- {};
this.cur_page <- -1;
this.cur_index <- -1;
this.Update <- null;

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

function iterate(section,depth) {
	local last_section = "";
	foreach(k,v in section){
		if(typeof(v) == "function")continue;
		if(typeof(v) == "table"){
			this.iterate(v,depth+"::"+k);
			continue;
		}
		if (depth != last_section){
			last_section = depth;
			this.data.append([]);
		}
		this.data.top().append({
			section = depth;
			key = k;
			value = v;
		});
		if(typeof(v) == "bool"){
			this.cursors[depth+"::"+k] <- this.Cursor(1,2 ::input_all);
		}
	}
};

function Initialize(){
	::loop.Begin(this);
	foreach(k, v in ::setting){
		if (typeof(v) != "table" || k == "misc")continue;
		iterate(v,k);
	};
	this.cursor <- this.Cursor(0, this.data[0].len(), ::input_all);
	this.cursor.se_ok = 0;
	this.cursor_page <- this.Cursor(1, this.data.len(), ::input_all);
	this.cursor_page.enable_ok = false;
	this.cursor_page.enable_cancel = false;
	this.cur_index = -1;
	this.cur_page = -1;
	::menu.cursor.Activate();
	::menu.back.Activate();
	::menu.help.Set(this.help);
	this.Update = this.UpdateMain;
	this.BeginAnime();
}

function Terminate(){
	this.data.resize(0);
	this.EndAnime();
	::menu.back.Deactivate(true);
	::menu.cursor.Deactivate();
	::menu.help.Reset();
}

function UpdateMain()
{
	this.cursor_page.Update();

	if (this.cursor_page.diff)
	{
		local prev = this.cursor.val;
		this.cursor <- this.Cursor(0, this.data[this.cursor_page.val].len(), ::input_all);
		this.cursor.se_ok = 0;
		this.cursor.val = this.cursor.item_num <= prev ? this.cursor.item_num - 1 : prev;
	}

	this.cursor.Update();

	if (this.cursor.ok)
	{
		this.cur_index = this.cursor.val;
		this.cur_page = this.cursor_page.val;
		local item = this.data[this.cursor_page.val][this.cursor.val];
		if (item.section in this.proc && item.key in this.proc[item.section]){
			this.proc[item.section][item.key].call(this);
		}
		return;
	}
	else if (this.cursor.cancel)
	{
		::loop.End();
	}
}

