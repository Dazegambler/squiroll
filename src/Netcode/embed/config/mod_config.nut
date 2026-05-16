::print("FIX:mod_config.nut will crash the game upon attempting to create menu page\n");
return;
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

::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Title("Misc"),
        ::UI.Menu.Enum(0,"hitboxes",function() {
            local page = ::menu.mod_config;
            page.anime.highlight.Set(val.left,val.top,val.right,val.bottom);
            page.common_cursor = val.cursor;
            page.common_callback_ok = function () {
               local ret = (cursor.val != 0);
               val.Set(ret);
               ::setting.save("hitbox_vis","enabled");
               page.item = null;
               page.anime.highlight.Reset();
            };
            page.common_callback_cancel = function () {
                page.item = null;
                page.anime.highlight.Reset();
            };
        })
    )
	//ConfigPage("Keybinds",table = ::setting.binds,
	//	ConfigKeyField("hide ui","hide_ui"),
	//	ConfigKeyField("step frame","step_frame"),
	//	ConfigKeyField("toggle frame stepping","step_toggle")
	//),
	//ConfigPage("misc",null,
	//	ConfigBoolSelectA("show hitboxes",::overlay,"enabled","hitbox_vis","enabled"),
	//	ConfigBoolSelectA("discord integration**",::discord,"enabled","misc","discord_integration")
	//)
);
table = null;
