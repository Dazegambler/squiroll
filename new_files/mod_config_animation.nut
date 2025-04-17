::manbow.compilebuffer("mod_config_set.nut",this);
function Initialize(){
	this.action <- ::menu.mod_config.weakref();
	this.pager <- this.UIPager();
	this.page <- [];
	// this.select_obj <- {};
	this.margin <- 42;
	local space = 20;
	foreach(v in this.action.data){
		local t = {};
		t.x <- 0;
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
			local item = this.item_table[_v.section][_v.key];
			local w = 0;
			local text = ::font.CreateSystemString(item.text);
			text.ConnectRenderSlot(::graphics.slot.front,0);
			text.y = ::menu.common.item_y + i * this.margin - 24 - 10;
			w = text.width + space;
			obj.push(text);
			local value = ::font.CreateSystemString(_v.value);
			value.ConnectRenderSlot(::graphics.slot.front, 0);
			value.y = text.y;
			obj.push(value);
			w += value.width;

			t.item.push(obj);
			if(w_max0 < text.width)w_max0 = text.width;
			if(w_max1 < w)w_max1 = w;
			foreach(v in t.item){
				v[0].x = (::graphics.width - w_max1) / 2;
				if(v.len() >  1)v[1].x = v[0].x + w_max0 + space;
			}
		}
	}
    this.pager.Activate(0);
    this.cur_page <- this.action.cursor_page.val;
    ::loop.AddTask(this);
}

// function Initialize(){
// 	this.action <- ::menu.mod_config.weakref();
// 	this.pager <- this.UIPager();
// 	this.page <- [];
// 	this.select_obj <- {};
// 	this.margin <- 42;
// 	local space = 20;
// 	foreach(v in this.action.data){
// 		this.pager.append(/*func call*/);
// 	}
//     this.pager.Activate(0);
//     this.cur_page <- this.action.cursor_page.val;
//     ::loop.AddTask(this);
// }


function Terminate()
{
	::loop.DeleteTask(this);
	this.pager = null;
	this.page = null;
	// this.select_obj = null;
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
	// foreach( v in this.select_obj) {
	// 	v.Update();
	// }
	local t = this.page[this.action.cursor_page.val].item[this.action.cursor.val][0];
	::menu.cursor.SetTarget(t.x - 20, t.y + 23, 0.69999999);
}