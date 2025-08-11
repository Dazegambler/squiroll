// ::UI.Menu.call(this,
// 	::UI.Page(
// 		::UI.Text("text object"),
// 		::UI.Text(""),
// 		::UI.Button("Button", function(page, index){
// 			::Dialog(0,"i got clicked :o\n",null,null);
// 		}),
// 		::UI.ValueField("value field", ::graphics),
// 		::UI.ValueField("input field", test, function (page, index) {
// 			local items = this.anime.page[page].item;
// 			local text = items[index][1];
// 			local item_x = this.anime.item_x;
// 			::Dialog(2, "input dialog", function (ret) {
// 				test = ret;
// 				text.Set(ret+"");
// 				text.x = ::graphics.width - item_x - (text.width * text.sx);
// 			}, test.tostring());
// 		}),
// 		::UI.Enum("bool object",true,function(page,index) {
// 			::menu.help.Set(this.help_item);
// 			this.Update = this.UpdateCommonItem;
// 			local items = this.anime.page[page].item;
// 			local cursor = items[index].top().cursor;
// 			this.common_cursor = cursor;
// 			this.common_callback_ok = function () {
// 				::Dialog(0, "success!",null,null);
// 			};
// 			this.common_callback_cancel = function () {

// 			};
// 		})
// 		::UI.Title("title")
// 	),
// 	::UI.Page(
// 		::UI.Text("this is just another page with different objects"),
// 		::UI.Text(""),
// 		::UI.Text("so nothing to pay attention to"),
// 		::UI.Title("")//each page needs something at the end due to titles being needed
// 	)
// );
local table = null;
local function ConfigBoolSelect(label,sqkey = null,key = null) {
	if (!sqkey)sqkey = label;
	if (!key)key = sqkey;
	local _table = table;
	return ::UI.Enum(label, [_table,sqkey],function (item) {
		::menu.help.Set(this.help_item);
		this.Update = this.UpdateCommonItem;
		this.anime.highlight.Set(item[1].left,item[1].top,item[1].right,item[1].bottom);
		this.common_cursor = item[1].cursor;
		this.common_callback_ok = function () {
			local ret = (this.common_cursor.val != 0);
			item[1].value.set(ret);
			::setting.save(_table.config_section,key,ret.tostring());
			item = null;
			this.anime.highlight.Reset();
		};
		this.common_callback_cancel = function () {
			item = null;
			this.anime.highlight.Reset();
		};
	});
}

local function ConfigField(label,sqkey = null,key = null) {
	if (!sqkey)sqkey = label;
	if (!key)key = sqkey;
	local _table = table;
	return ::UI.ValueField(label, [_table,sqkey], function (item) {
		local item_x = this.anime.item_x;
		::Dialog(2, label, function (ret) {
			if (ret) {
				local str = ret+"";
				item[1].Set(ret["to"+typeof _table[sqkey]]());
				::setting.save(_table.config_section,key,str);
				item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
			}
		}, "");
	});
}

local function ConfigColorField(label,sqkey = null) {
	if (!sqkey)sqkey = label;
	local _table = table;
	return ::UI.ValueField(label, [_table,sqkey], function (item) {
		local item_x = this.anime.item_x;
		::Dialog(2, diag_txt, function (ret) {
			if (ret) {
				local val = ::math.clamp(ret.tofloat(),0,1);
				local str = ret+"";
				item[1].Set(val);
				::setting.save(_table.config_section,"color",::math.rgbaToHex(_table.red,_table.green,_table.blue,_table.alpha));
				item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
			}
		}, "");
	});
}
local function ConfigPage(section,_table,...) {
	return function () {
		this.anime.data.push([]);
		this.proc.push([]);
		foreach (elem in vargv) {
			this.anime.data.top().push(elem[0]);
			this.proc.top().push(elem[1]);
		}
		local title = ::UI.Title(section);
		this.anime.data.top().push(title[0]);
		this.proc.top().push(title[1]);
	};
}
::UI.Menu.call(this,
	ConfigPage("network",table = ::setting.network,
		ConfigBoolSelect("hide ip","hide_ip"),
		ConfigBoolSelect("share spectate ip","share_watch_ip"),
		ConfigBoolSelect("hide names","hide_opponent_name","hide_name"),
		ConfigBoolSelect("hide profile images","hide_opponent_name","hide_name"),
		ConfigBoolSelect("lobby auto switch","auto_lobby_state_switch","auto_seach_host")
	),
	ConfigPage("ping",table = ::setting.ping,
		ConfigBoolSelect("enabled"),
		ConfigBoolSelect("show input delay","input_delay","frames"),
		ConfigField("x"),
		ConfigField("y"),
		ConfigField("scale x","sx","scale_x"),
		ConfigField("scale y","sy","scale_y"),
		ConfigColorField("red"),
		ConfigColorField("green"),
		ConfigColorField("blue"),
		ConfigColorField("alpha")
	),
	ConfigPage("input display(p1)1/2",table = ::setting.input_display.p1,
		ConfigBoolSelect("enabled"),
		ConfigField("x"),
		ConfigField("y"),
		ConfigField("scale x","sx","scale_x"),
		ConfigField("scale y","sy","scale_y"),
		ConfigColorField("red"),
		ConfigColorField("green"),
		ConfigColorField("blue"),
		ConfigColorField("alpha")
	),
	ConfigPage("input display(p1)2/2",null,
		ConfigField("notation"),
		ConfigBoolSelect("input duration","frame_count"),
		ConfigField("offset"),
		ConfigField("input count","list_max","count"),
		ConfigField("timer")
	)
	ConfigPage("input display(p2)1/2",table = ::setting.input_display.p2,
		ConfigBoolSelect("enabled"),
		ConfigField("x"),
		ConfigField("y"),
		ConfigField("scale x","sx","scale_x"),
		ConfigField("scale y","sy","scale_y"),
		ConfigColorField("red"),
		ConfigColorField("green"),
		ConfigColorField("blue"),
		ConfigColorField("alpha")
	),
	ConfigPage("input display(p2)2/2",null,
		ConfigField("notation"),
		ConfigBoolSelect("input duration","frame_count"),
		ConfigField("offset"),
		ConfigField("input count","list_max","count"),
		ConfigField("timer")
	)
);
table = null;