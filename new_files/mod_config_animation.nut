this.anime_set <- ::actor.LoadAnimationData("data/system/key_config/key_config.pat");
function Initialize()
{
	this.action <- ::menu.mod_config.weakref();
	this.x <- -1280;
	this.y <- 0;
	this.visible <- true;
	local obj;
	local texture = ::manbow.Texture();
	texture.Load("data/system/key_config/parts.png");
	this.texture_key <- ::manbow.Texture();
	this.texture_key.Load("data/system/key_config/config_moji1.png");
	this.texture_button <- ::manbow.Texture();
	this.texture_button.Load("data/system/key_config/config_pad1.png");
	this.texture_lever <- ::manbow.Texture();
	this.texture_lever.Load("data/system/key_config/config_pad2.png");
	local func_create_sprite = function ( name )
	{
		local res = this.anime_set[name];
		local obj = ::manbow.Sprite();
		obj.Initialize(texture, res.left, res.top, res.width, res.height);
		obj.ConnectRenderSlot(::graphics.slot.overlay, 0);
		return obj;
	};
	local title_name = "title_" + (this.action.side == 0 ? "1p" : "2p");
	this.title <- func_create_sprite(title_name);
	this.title.x = ::menu.common.title_x - this.anime_set[title_name].width / 2;
	this.title.y = ::menu.common.title_y;
	this.pad <- func_create_sprite("gamepad");
	this.pad.x = 400 + 128;
	this.pad.y = ::menu.common.item_y - 36;
	this.key <- func_create_sprite("keyboard");
	this.key.x = 400 + 320;
	this.key.y = ::menu.common.item_y - 36;
	this.item <- [];
	this.item_key <- [];
	this.item_pad <- [];

	for( local i = 0; i < 10; i = ++i )
	{
		local _y = ::menu.common.item_y + i * 36;
		obj = func_create_sprite("b" + i);
		obj.x = 400;
		obj.y = _y;
		this.item.push(obj);
		obj = ::manbow.Sprite();
		obj.x = this.key.x;
		obj.y = _y;
		obj.ConnectRenderSlot(::graphics.slot.overlay, 0);
		this.item_key.append(obj);
		obj = ::manbow.Sprite();
		obj.x = this.pad.x;
		obj.y = _y;
		obj.ConnectRenderSlot(::graphics.slot.overlay, 0);
		this.item_pad.append(obj);
	}

	obj = func_create_sprite("exit");
	obj.x = 400;
	obj.y = ::menu.common.item_y + 11 * 36;
	this.item.push(obj);
	this.ui <- this.UIBase();
	this.ui.action = this.action.weakref();
	this.ui.target = this.weakref();
	this.Update();
	::loop.AddTask(this);
}

function Terminate()
{
	this.title = null;
	this.pad = null;
	this.key = null;
	this.item = null;
	this.item_key = null;
	this.item_pad = null;
	::loop.DeleteTask(this);
}

function Update()
{
	local y = this.action.cursor.y;

	foreach( i, v in this.item )
	{
		v.red = v.green = v.blue = y == i ? 1.00000000 : 0.50000000;
	}

	foreach( v in this.item_pad )
	{
	}

	foreach( v in this.item_key )
	{
	}

	foreach( i, v in this.action.item )
	{
		this.SetPad(this.item_pad[i], this.action.pad[v]);
		this.SetKey(this.item_key[i], this.action.key[v]);
		this.item_pad[i].red = this.item_pad[i].green = this.item_pad[i].blue = y == i && this.action.cursor.x == 0 ? 1.00000000 : 0.50000000;
		this.item_key[i].red = this.item_key[i].green = this.item_key[i].blue = y == i && this.action.cursor.x == 1 ? 1.00000000 : 0.50000000;
	}

	if (this.action.state == 0)
	{
		if (this.action.cursor.y >= 10)
		{
			::menu.cursor.SetTarget(this.item[y].x - 20, this.item[y].y + 16, 0.69999999);
		}
		else
		{
			::menu.cursor.SetTarget(this.action.cursor.x == 0 ? this.item_pad[y].x : this.item_key[y].x, this.item[y].y + 16, 0.69999999);
		}
	}

	this.ui.Update();
	local mat = ::manbow.Matrix();
	mat.SetTranslation(this.x, 0, 0);

	foreach( v in this.item )
	{
		v.SetWorldTransform(mat);
	}

	foreach( v in this.item_pad )
	{
		v.SetWorldTransform(mat);
	}

	foreach( v in this.item_key )
	{
		v.SetWorldTransform(mat);
	}

	this.title.SetWorldTransform(mat);
	this.key.SetWorldTransform(mat);
	this.pad.SetWorldTransform(mat);
	return;
	this.ui.Update();
}

function SetKey( obj, val )
{
	if (val < 0)
	{
		obj.Initialize(this.texture_lever, 256, 160, 128, 32);
	}
	else
	{
		local x = val % 8 * 128;
		local y = val / 8 * 32;
		obj.Initialize(this.texture_key, x, y, 128, 32);
	}
}

function SetPad( obj, val )
{
	if (val < 0)
	{
		obj.Initialize(this.texture_lever, 256, 160, 128, 32);
	}
	else
	{
		local x;
		local y;

		if (val & 512)
		{
			val = val & 511;
			x = val % 4 * 128;
			y = val / 4 * 32;
			obj.Initialize(this.texture_lever, x, y, 128, 32);
		}
		else
		{
			x = val % 4 * 128;
			y = val / 4 * 32;
			obj.Initialize(this.texture_button, x, y, 128, 32);
		}
	}
}

