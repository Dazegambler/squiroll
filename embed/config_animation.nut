this.anime_set <- ::actor.LoadAnimationData("data/system/config/config.pat");
function Initialize()
{
	this.action <- ::menu.config.weakref();
	this.x <- 0;
	this.y <- 0;
	this.visible <- true;
	this.item <- [];
	this.active <- false;
	local texture = ::manbow.Texture();
	texture.Load("data/system/config/config.png");
	local res;
	res = this.anime_set.title;
	this.title <- ::manbow.Sprite();
	this.title.Initialize(texture, res.left, res.top, res.width, res.height);
	this.item.push(this.title);
	local item_table = ::menu.common.LoadItemTextArray("data/system/config/item.csv");
	item_table.misc <- ["squiroll"];
	::menu.common.InitializeLayout.call(this, null, item_table);
	local item_width = 548;
	local left = ::menu.common.item_x - item_width / 2;
	local text_table = {};

	foreach( i, v in this.action.item )
	{
		if (v == null)
		{
			continue;
		}

		local t = this.text[i];
		t.x = left;
		text_table[v] <- t;

		if (t.width > 270)
		{
			t.sx = 270.00000000 / t.width.tofloat();
		}
	}

	this.cursor_x <- left - 20;
	local item_left = 200;
	this.select_obj <- {};
	local select_x = left + item_left + 120;
	local _width = item_width - item_left;
	local t = [
		"screen",
		"vsync",
		"background",
		"fps",
		"replay_save",
		"replay_save_online",
		"lang"
	];
	this.item_list <- {};

	foreach( v in this.action.item )
	{
		if (v)
		{
			this.item_list[v] <- v;
		}
	}

	foreach( v in t )
	{
		if (!(v in this.item_list))
		{
			continue;
		}

		local s = this.UIItemSelectorSingle(item_table[v].slice(1), select_x, text_table[v].y, this.mat_world, this.action["cursor_" + v]);
		s.SetColor(1, 1, 0);
		this.select_obj[v] <- s;
	}

	res = this.anime_set.bar_back;
	local se_back = ::manbow.Sprite();
	se_back.Initialize(texture, res.left, res.top, res.width, res.height);
	this.item.push(se_back);
	res = this.anime_set.bar;
	this.se_bar <- ::manbow.Sprite();
	this.se_bar.Initialize(texture, res.left, res.top, res.width, res.height);
	this.item.push(this.se_bar);
	res = this.anime_set.bar_back;
	local bgm_back = ::manbow.Sprite();
	bgm_back.Initialize(texture, res.left, res.top, res.width, res.height);
	this.item.push(bgm_back);
	res = this.anime_set.bar;
	this.bgm_bar <- ::manbow.Sprite();
	this.bgm_bar.Initialize(texture, res.left, res.top, res.width, res.height);
	this.item.push(this.bgm_bar);
	this.bar_src <- res;
	this.se_bar.x = se_back.x = text_table.se.x + item_left + 60;
	this.se_bar.y = se_back.y = text_table.se.y + 4;
	this.bgm_bar.x = bgm_back.x = text_table.bgm.x + item_left + 60;
	this.bgm_bar.y = bgm_back.y = text_table.bgm.y + 4;
	this.se_bar.SetUV(this.bar_src.left, this.bar_src.top, this.bar_src.width * this.action.cursor_se.val / 10.00000000, this.bar_src.height);
	this.bgm_bar.SetUV(this.bar_src.left, this.bar_src.top, this.bar_src.width * this.action.cursor_bgm.val / 10.00000000, this.bar_src.height);

	foreach( v in this.item )
	{
		v.ConnectRenderSlot(::graphics.slot.overlay, 0);
	}

	this.highlight <- this.UIItemHighlight();
	this.state <- 0;
	::loop.AddTask(this);
}

function Terminate()
{
	::menu.common.TerminateLayout.call(this);
	this.title = null;
	this.se_bar = null;
	this.bgm_bar = null;
	this.highlight = null;
	this.item = null;
	this.select_obj = null;
	::loop.DeleteTask(this);
}

function Update()
{
	::menu.common.UpdateLayout.call(this, this);

	switch(this.state)
	{
	case 0:
		if (this.action.cursor_se.active)
		{
			this.highlight.Set(this.se_bar.x - 8, this.se_bar.y + 6, this.se_bar.x + this.bar_src.width + 8, this.se_bar.y + this.bar_src.height - 3);
			this.state = 1;
		}

		if (this.action.cursor_bgm.active)
		{
			this.highlight.Set(this.bgm_bar.x - 8, this.bgm_bar.y + 6, this.bgm_bar.x + this.bar_src.width + 8, this.bgm_bar.y + this.bar_src.height - 3);
			this.state = 2;
		}

		foreach( v in this.select_obj )
		{
			v.Update();
		}

		break;

	case 1:
		if (!this.action.cursor_se.active)
		{
			this.highlight.Reset();
			this.state = 0;
		}

		this.se_bar.SetUV(this.bar_src.left, this.bar_src.top, this.bar_src.width * this.action.cursor_se.val / 10.00000000, this.bar_src.height);
		break;

	case 2:
		if (!this.action.cursor_bgm.active)
		{
			this.highlight.Reset();
			this.state = 0;
		}

		this.bgm_bar.SetUV(this.bar_src.left, this.bar_src.top, this.bar_src.width * this.action.cursor_bgm.val / 10.00000000, this.bar_src.height);
		break;
	}

	foreach( v in this.item )
	{
		v.SetWorldTransform(this.mat_world);
	}
}

function UpdateLang()
{
	local item_table = ::menu.common.LoadItemTextArray("data/system/config/item.csv");
	item_table.misc <- ["squiroll"];
	::menu.common.UpdateItemString.call(this, item_table);

	foreach( i, v in this.action.item )
	{
		if (v == null)
		{
			continue;
		}

		local t = this.text[i];

		if (t.width > 270)
		{
			t.sx = 270.00000000 / t.width.tofloat();
		}
		else
		{
			t.sx = 1;
		}
	}

	foreach( key, item in this.select_obj )
	{
		item.SetString(item_table[key].slice(1));
	}
}

