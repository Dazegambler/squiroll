::manbow.compilebuffer("mod_config_set.nut",this);
// function Initialize(){
//     this.action <- ::menu.mod_config.weakref();
//     this.pager <- this.UIPager();
//     this.page <- [];
// 	local item_width = 548;
// 	local left = ::menu.common.item_x - item_width / 2;
//     this.margin <- 42;
//     local space = 20;

//     foreach( p, _page in this.action.page )
// 	{
// 		local t = {};
// 		t.x <- 1280;
// 		t.y <- 0;
// 		t.visible <- true;
// 		this.page.append(t);
// 		local ui = this.UIBase();
// 		ui.target = t.weakref();
// 		ui.ox = 0;
// 		this.pager.Append(ui);
// 		t.item <- [];
// 		local w_max0 = 0;
// 		local w_max1 = 0;

// 		local section = ::font.CreateSystemString(_page[0].section);
// 		section.sx = section.sy = 1.5;
// 		section.x = ::graphics.width - ((section.sx * section.width) / 2);
// 		section.y = 50 - ((section.sy * section.height) / 2);
// 		section.red = 0.0;
// 		section.green = 1.0;
// 		section.blue = 0.0;
// 		section.alpha = 1.0;
// 		section.ConnectRenderSlot(::graphics.slot.front, 0);
// 		// t.item.push([section]);

// 		foreach( i, v in _page )
// 		{
// 			local obj = [];
// 			local w = 0;
// 			local text = ::font.CreateSystemString(v.key);
// 			text.ConnectRenderSlot(::graphics.slot.front, 0);
// 			text.y = ::menu.common.item_y + i * this.margin - 24 - 10;
// 			obj.push(text);
// 			w = text.width + space;

// 			local value = ::font.CreateSystemString(v.value);
// 			value.ConnectRenderSlot(::graphics.slot.front, 0);
// 			value.y = text.y;
// 			obj.push(value);
// 			w = w + value.width * value.sx;

// 			t.item.push(obj);

// 			if (w_max0 < text.width)
// 			{
// 				w_max0 = text.width;
// 			}

// 			if (w_max1 < w)
// 			{
// 				w_max1 = w;
// 			}
// 		}

// 		foreach(i, v in t.item )
// 		{
// 			v[0].x = (::graphics.width - w_max1) / 2;
// 			v[1].x = v[0].x + w_max0 + space;
// 		}
// 	}
//     this.pager.Activate(0);
//     this.cur_page <- this.action.cursor_page.val;
//     // this.page_index <- ::font.CreateSystemString("page 1/1");
//     // this.page_index.x = 1200;
//     // this.page_index.y = 660;
//     // this.page_index.ConnectRenderSlot(::graphics.slot.front, 0);
//     ::loop.AddTask(this);
// }


function Initialize(){
	this.action <- ::menu.mod_config.weakref();
	this.pager <- this.UIPager();
	this.page <- [];
	this.margin <- 42;
	local space = 20;
	foreach(v in this.action.data){
		local t = {};
		t.x <- 1280;
		t.y <- 0;
		t.visible <- true;
		this.page.append(t);
		local ui = this.UIBase();
		ui.target = t.weakref();
		ui.ox = 0;
		this.pager.Append(ui);
		t.item <- [];
		local w_max0 = 0;
		local w_max1 = 0;
		foreach(i,_v in v){
			if(!(_v.section in this.item_table) || !(_v.key in this.item_table[_v.section])) continue;
			local obj = [];
			local w = 0;
			local text = ::font.CreateSystemString(this.item_table[_v.section][_v.key].text);
			text.ConnectRenderSlot(::graphics.slot.front,0);
			text.y = ::menu.common.item_y + i * this.margin - 24 - 10;
			w = text.width + space;
			obj.push(text);
			if("value" in this.item_table[_v.section][_v.key]){
				local s = this.UIItemSelectorSingle(
					_v.values[0],
					select_x,text.y,this.mat_world,
					this.action.cursors[(_v.depth+"::"+_v.text)]);
				s.SetColor(1,1,0);
				obj.push(s);
				w += s.width;
			}else{
				local value = ::font.CreateSystemString(_v.value);
				value.ConnectRenderSlot(::graphics.slot.front, 0);
				value.y = text.y;
				obj.push(value);
				w += value.width;
			}

			t.item.push(obj);
			if(w_max0 < text.width)w_max0 = text.width;
			if(w_max1 < w)w_max1 = w;
			foreach(v in t.item){
			v[0].x = (::graphics.width - w_max1) / 2;
			v[1].x = v[0].x + w_max0 + space;
			}
		}
	}
    this.pager.Activate(0);
    this.cur_page <- this.action.cursor_page.val;
    ::loop.AddTask(this);
}

function Terminate()
{
	::loop.DeleteTask(this);
	this.pager = null;
	this.page = null;
}

function Update()
{
	this.pager.Set(this.action.cursor_page.val);
	local mat = ::manbow.Matrix();

	foreach( p, _page in this.page )
	{
		mat.SetTranslation(_page.x, 0, 0);

		foreach( i, _item in _page.item )
		{
			foreach( obj in _item )
			{
				obj.visible = _page.visible;

				if (obj.visible)
				{
					obj.SetWorldTransform(mat);
				}
			}
		}
	}
	local t = this.page[this.action.cursor_page.val].item[this.action.cursor.val][0];
	::menu.cursor.SetTarget(t.x - 20, t.y + 23, 0.69999999);
}