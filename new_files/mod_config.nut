local test = 420;
::UI.Menu.call(this,
	::UI.Page(
		::UI.Text("text object"),
		::UI.Text(""),
		::UI.Button("Button", function(page, index){
			::Dialog(0,"i got clicked :o\n",null,null);
		}),
		::UI.ValueField("value field", ::graphics),
		::UI.ValueField("input field", test, function (page, index) {
			local items = this.anime.page[page].item;
			local text = items[index][1];
			local item_x = this.anime.item_x;
			::Dialog(2, "input dialog", function (ret) {
				test = ret;
				text.Set(ret+"");
				text.x = ::graphics.width - item_x - (text.width * text.sx);
			}, test.tostring());
		}),
		::UI.Enum("bool object",true,function(page,index) {
			::menu.help.Set(this.help_item);
			this.Update = this.UpdateCommonItem;
			local items = this.anime.page[page].item;
			local cursor = items[index].top().cursor;
			this.common_cursor = cursor;
			this.common_callback_ok = function () {
				::Dialog(0, "success!",null,null);
			};
			this.common_callback_cancel = function () {

			};
		})
		::UI.Title("title")
	),
	::UI.Page(
		::UI.Text("this is just another page with different objects"),
		::UI.Text(""),
		::UI.Text("so nothing to pay attention to"),
		::UI.Title("")//each page needs something at the end due to titles being needed
	)
);