// ::UI.Menu.call(this,
// 	::UI.Page(
// 		::UI.Text("text object"),
// 		::UI.Text(""),
// 		::UI.Button("Button", function(page, index){
// 			::Dialog(0,"i got clicked :o\n",null,null);
// 		}),
// 		::UI.ValueField("value field", ::graphics),
// 		::UI.ValueField("input field", test, function (page, index) {
// 			local items = anime.page[page].item;
// 			local text = items[index][1];
// 			local item_x = anime.item_x;
// 			::Dialog(2, "input dialog", function (ret) {
// 				test = ret;
// 				text.Set(ret+"");
// 				text.x = ::graphics.width - item_x - (text.width * text.sx);
// 			}, test.tostring());
// 		}),
// 		::UI.Enum("bool object",true,function(page,index) {
// 			::menu.help.Set(help_item);
// 			Update = UpdateCommonItem;
// 			local items = anime.page[page].item;
// 			local cursor = items[index].top().cursor;
// 			common_cursor = cursor;
// 			common_callback_ok = function () {
// 				::Dialog(0, "success!",null,null);
// 			};
// 			common_callback_cancel = function () {

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
		::menu.help.Set(help_item);
		Update = UpdateCommonItem;
		anime.highlight.Set(item[1].left,item[1].top,item[1].right,item[1].bottom);
		common_cursor = item[1].cursor;
		common_callback_ok = function () {
			local ret = (common_cursor.val != 0);
			item[1].value.set(ret);
			::setting.save(_table.config_section,key,ret.tostring());
			item = null;
			anime.highlight.Reset();
		};
		common_callback_cancel = function () {
			item = null;
			anime.highlight.Reset();
		};
	});
}

local function ConfigField(label,sqkey = null,key = null) {
	if (!sqkey)sqkey = label;
	if (!key)key = sqkey;
	local _table = table;
	return ::UI.ValueField(label, [_table,sqkey], function (item) {
		local item_x = anime.item_x;
		::Dialog(2, label, function (ret) {
			if (ret) {
				try{ret["to"+typeof _table[sqkey]]();}
				catch (e){return;}
				local str = ret+"";
				item[1].Set(ret["to"+typeof _table[sqkey]]());
				::setting.save(_table.config_section,key,str);
				item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
			}
		}, "");
	});
}

local function ConfigNotationField(label,index) {
	local _table = table;
	local input_arr = ::split(_table.notation,",");
	local cinput = input_arr[index];
	local tab = {
		input = cinput
	};
	return ::UI.ValueField(label, [tab,"input"], function (item) {
		local item_x = anime.item_x;
		::Dialog(2, label, function (ret) {
			if (ret) {
				input_arr[index] = ret;
				local str = "";
				foreach(i,c in input_arr)str+=c+",";
				str = str.slice(0,-1);
				_table.notation = str;
				item[1].Set(ret);
				::setting.save(_table.config_section,"notation",str);
				item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
			}
		}, "");
	});
}

local function ConfigColorField(label,sqkey = null) {
	if (!sqkey)sqkey = label;
	local _table = table;
	return ::UI.ValueField(label, [_table,sqkey], function (item) {
		local item_x = anime.item_x;
		::Dialog(2,label, function (ret) {
			if (ret) {
				try{ret.tofloat();}
				catch (e){return;}
				local val = ::math.fclamp(ret.tofloat(),0,1);
				local str = ret+"";
				item[1].Set(val);
				::setting.save(_table.config_section,"color",::math.rgbaToHex(_table.red,_table.green,_table.blue,_table.alpha));
				item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
			}
		}, "");
	});
}

local function ConfigKeyField(label,sqkey = null,key = null) {
	if (!sqkey)sqkey = label;
	if (!key)key = sqkey;
	local _table = table;
	return ::UI.ValueField(label, [_table,sqkey], function (item) {
		Update = function () {
			if (::manbow.GetKeyboardState() >= 0)return;
			if (::manbow.GetPadButtonState() >= 0)return;
			Update = function () {
				local id = ::manbow.GetKeyboardState();
				if (id >= 0){
					::sound.PlaySE("sys_ok");
					item[1].Set(id);
					::setting.save(_table.config_section,key,id.tostring());
					item[1].x = ::graphics.width - anime.item_x - (item[1].width * item[1].sx);
					Update = UpdateMain;
					return;
				}
			};
		}
	});
}

local function ConfigEnumField(label,options,sq_key = null,key = null) {
	if (!sqkey) sqkey = label;
	if (!key) key = sqkey;
	local _table = table;
	return ::UI.Enum(label, [_table,sqkey],function (item) {
		::menu.help.Set(help_item);
		Update = UpdateCommonItem;
		anime.highlight.Set(item[1].left,item[1].top,item[1].right,item[1].bottom);
		common_cursor = item[1].cursor;
		common_callback_ok = function () {
			local ret = common_cursor.val;
			item[1].value.set(ret);
			::setting.save(_table.config_section,key,ret.tostring());
			item = null;
			anime.highlight.Reset();
		};
		common_callback_cancel = function () {
			item = null;
			anime.highlight.Reset();
		};
	},options);
}

// local function ConfigFieldA(label,_table,sqkey,section,key) {
// 	return ::UI.ValueField(label, [_table,sqkey], function (item) {
// 		local item_x = anime.item_x;
// 		::Dialog(2, label, function (ret) {
// 			if (ret) {
// 				try{ret["to"+typeof _table[sqkey]]();}
// 				catch (e){return;}
// 				local str = ret+"";
// 				item[1].Set(ret["to"+typeof _table[sqkey]]());
// 				::setting.save(_table.config_section,key,str);
// 				item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
// 			}
// 		}, "");
// 	});
// }

local function ConfigBoolSelectA(label,table,sqkey,section,key) {
	return ::UI.Enum(label,[table,sqkey],function (item) {
		::menu.help.Set(help_item);
		Update = UpdateCommonItem;
		anime.highlight.Set(item[1].left,item[1].top,item[1].right,item[1].bottom);
		common_cursor = item[1].cursor;
		common_callback_ok = function () {
			local ret = (common_cursor.val != 0);
			item[1].value.set(ret);
			::setting.save(section,key,ret.tostring());
			item = null;
			anime.highlight.Reset();
		};
		common_callback_cancel = function () {
			item = null;
			anime.highlight.Reset();
		};
	});
}

local function ConfigPage(section,_table,...) {
	return function () {
		anime.data.push([]);
		proc.push([]);
		foreach (elem in vargv) {
			anime.data.top().push(elem[0]);
			proc.top().push(elem[1]);
		}
		local title = ::UI.Title(section);
		anime.data.top().push(title[0]);
		proc.top().push(title[1]);
	};
}

function Add(...) {
	foreach (elem in vargv)elem.call(this);
}

::UI.Menu.call(this,
	ConfigPage("Ping",table = ::setting.ping,
		ConfigBoolSelect("enabled"),
		ConfigBoolSelect("show input delay","input_delay","frames"),
		ConfigBoolSelect("simple"),
		ConfigField("great threshold([///])","great_threshold"),
		ConfigField("good threshold([//_])","good_threshold"),
		ConfigField("bad threshold([/__])","bad_threshold"),
		ConfigField("x"),
		ConfigField("y"),
		ConfigField("scale x","sx","scale_x"),
		ConfigField("scale y","sy","scale_y")
	),
	ConfigPage("Input Display(p1) 1/4",table = ::setting.input_display.p1,
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
	ConfigPage("Input Display(p1) 2/4",null,
		ConfigBoolSelect("input duration","frame_count"),
		ConfigField("offset"),
		ConfigField("input count","list_max","count"),
		ConfigField("timer")
	),
	ConfigPage("Input Display(p1) 3/4",null,
		ConfigNotationField("Notation(1)",0),
		ConfigNotationField("Notation(2)",1),
		ConfigNotationField("Notation(3)",2),
		ConfigNotationField("Notation(4)",3),
		ConfigNotationField("Notation(5)",4),
		ConfigNotationField("Notation(6)",5),
		ConfigNotationField("Notation(7)",6),
		ConfigNotationField("Notation(8)",7),
		ConfigNotationField("Notation(9)",8)
	),
	ConfigPage("Input Display(p1) 4/4",null,
		ConfigNotationField("Notation(A)",9),
		ConfigNotationField("Notation(B)",10),
		ConfigNotationField("Notation(C)",11),
		ConfigNotationField("Notation(D)",12),
		ConfigNotationField("Notation(E)",13),
		ConfigNotationField("Notation([B])",14)
	),
	ConfigPage("Input Display(p2) 1/4",table = ::setting.input_display.p2,
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
	ConfigPage("Input Display(p2) 2/4",null,
		ConfigBoolSelect("input duration","frame_count"),
		ConfigField("offset"),
		ConfigField("input count","list_max","count"),
		ConfigField("timer")
	),
	ConfigPage("Input Display(p2) 3/4",null,
		ConfigNotationField("Notation(1)",0),
		ConfigNotationField("Notation(2)",1),
		ConfigNotationField("Notation(3)",2),
		ConfigNotationField("Notation(4)",3),
		ConfigNotationField("Notation(5)",4),
		ConfigNotationField("Notation(6)",5),
		ConfigNotationField("Notation(7)",6),
		ConfigNotationField("Notation(8)",7),
		ConfigNotationField("Notation(9)",8)
	),
	ConfigPage("Input Display(p2) 4/4",null,
		ConfigNotationField("Notation(A)",9),
		ConfigNotationField("Notation(B)",10),
		ConfigNotationField("Notation(C)",11),
		ConfigNotationField("Notation(D)",12),
		ConfigNotationField("Notation(E)",13),
		ConfigNotationField("Notation([B])",14)
	),
	ConfigPage("Frame Data Display",table = ::setting.frame_data,
		ConfigBoolSelect("enabled"),
		ConfigField("x"),
		ConfigField("y"),
		ConfigField("scale x","sx","scale_x"),
		ConfigField("scale y","sy","scale_y"),
		ConfigBoolSelect("frame step", "frame_stepping"),
		ConfigField("width"),
		ConfigField("timer")
	),
	ConfigPage("Keybinds",table = ::setting.binds,
		ConfigKeyField("hide ui","hide_ui"),
		ConfigKeyField("step frame","step_frame"),
		ConfigKeyField("toggle frame stepping","step_toggle")
	),
	ConfigPage("misc",null,
		ConfigBoolSelectA("show hitboxes",::overlay,"enabled","hitbox_vis","enabled"),
		ConfigBoolSelectA("discord integration**",::discord,"enabled","misc","discord_integration")
	)
);
table = null;
