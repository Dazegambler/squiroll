function Initialize(){
    this.action <- ::menu.mod_config.weakref();
    this.pager <- this.UIPager();
    this.page <- [];
    this.margin <- 42;
    local space = 20;
    local scale = 0.69;

    foreach( p, _page in this.action.page )
	{
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
		local w_max1 = 0;

		local section = ::font.CreateSystemString(_page[0].section);
		section.sx = section.sy = 1.5;
		section.x = ::graphics.width - ((section.sx * section.width) / 2);
		section.y = 50 - ((section.sy * section.height) / 2);
		section.red = 0.0;
		section.green = 1.0;
		section.blue = 0.0;
		section.alpha = 1.0;
		section.ConnectRenderSlot(::graphics.slot.front, 0);
		t.item.push([section]);

		foreach( i, v in _page )
		{
			local obj = [];
			local w = 0;
			local text = ::font.CreateSystemString(v.key);
			text.ConnectRenderSlot(::graphics.slot.front, 0);
			text.y = ::menu.common.item_y + i * this.margin - 24 - 10;
			obj.push(text);
			w = text.width + space;
			t.item.push(obj);

			if (w_max1 < w)
			{
				w_max1 = w;
			}
		}

		foreach( v in t.item )
		{
			v[0].x = (::graphics.width - w_max1) / 2;
		}
	}
    this.pager.Activate(0);
    this.cur_page <- this.action.cursor_page.val;
    this.page_index <- ::font.CreateSystemString("page 1/1");
    this.page_index.x = 1200;
    this.page_index.y = 660;
    this.page_index.ConnectRenderSlot(::graphics.slot.front, 0);
    ::loop.AddTask(this);
}

function Terminate()
{
	::loop.DeleteTask(this);
	this.pager = null;
	this.page = null;
	this.page_index = null;
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
	this.page_index.Set("page " + (this.action.cursor_page.val + 1) + "/" + this.action.cursor_page.item_num);
	this.page_index.x = 1200 - this.page_index.width;
}