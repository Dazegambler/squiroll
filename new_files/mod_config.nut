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
local dialog_set = function (section,key,diag_txt,value) {
	return function (page, index) {
		local items = this.anime.page[page].item;
		local text = items[index][1];
		local item_x = this.anime.item_x;
		::Dialog(2, diag_txt, function (ret) {
			if (ret) {
				local str = ret+"";
				value = ret;
				::setting.save(section,key,str);
				// text.Set(@()str);
				text.x = ::graphics.width - item_x - (text.width * text.sx);
			}
		}, value+"");
	};
};

local color_set = function (section,config,diag_txt,value) {
	return function (page, index) {
		local items = this.anime.page[page].item;
		local text = items[index][1];
		local item_x = this.anime.item_x;
		::Dialog(2, diag_txt, function (ret) {
			if (ret) {
				local str = ret+"";
				value = ret;
				::setting.save(section,"color",::math.rgbaToHex(config.red,config.green,config.blue,config.alpha));
				text.Set(@()str);
				text.x = ::graphics.width - item_x - (text.width * text.sx);
			}
		}, value+"");
	};
};

local bool_set = function (section,key) {
	return function (page, index) {
		::menu.help.Set(this.help_item);
		this.Update = this.UpdateCommonItem;
		local items = this.anime.page[page].item;
		local cursor = items[index].top().cursor;
		this.common_cursor = cursor;
		this.common_callback_ok = function () {
			::setting.save(section,key,!this.common_cursor.val ? "false" : "true");
		};
		this.common_callback_cancel = function () {};
	};
};

::UI.Menu.call(this,
	::UI.Page(
		::UI.Enum("enabled", ::setting.ping.enabled,bool_set("ping","enabled")),
		::UI.Enum("input delay display",::setting.ping.input_delay,bool_set("ping","frames")),
		::UI.ValueField("pos x", @()::setting.ping.X, dialog_set("ping","x","position x",::setting.ping.X)),
		::UI.ValueField("pos y", @()::setting.ping.Y, dialog_set("ping","y","position y",::setting.ping.Y)),
		::UI.ValueField("scale x", @()::setting.ping.SX, dialog_set("ping","scale_x","scale x",::setting.ping.SX)),
		::UI.ValueField("scale y", @()::setting.ping.SY, dialog_set("ping","scale_y","scale y",::setting.ping.SY)),
		// ::UI.ValueField("color(red)", ::setting.ping.red, color_set("ping",::setting.ping,"color(red)",::setting.ping.red)),
		::UI.Title("ping display")// title must always be at the end so it can be filtered out from selection
	)
);