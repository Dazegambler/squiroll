//TF4's UI code is a mess, i'm making my own modular system for it
this.title_x <- 640;
this.title_y <- 96;
this.item_x <- 640;
this.item_y <- 200;
this.item_space <- 30;

function Initialize()
{
	this.state = 0;
	::menu.cursor.Activate();
	::menu.back.Activate();
	::loop.Begin(this);
}

function Terminate()
{
	this.state = -1;
	::menu.cursor.Deactivate();
	::menu.back.Deactivate(true);
	::menu.help.Reset();
}

function Suspend()
{
	this.state = 1;
	::menu.help.Reset();
}

function Resume()
{
	this.state = 0;

	if (("anime" in this) && "Resume" in this.anime)
	{
		this.anime.Resume();
	}

	::menu.help.Set(this.help);
}

function Show()
{
	::menu.cursor.Show();
	::menu.back.Show();
	::menu.help.Show();

	if ("anime" in this)
	{
		this.anime.Show();
	}
}

function Hide()
{
	::menu.cursor.Hide();
	::menu.back.Hide();
	::menu.help.Hide();

	if ("anime" in this)
	{
		this.anime.Hide();
	}
}

function Update()
{
	::menu.help.Set(this.help);

	if (::input_all.b10 == 1)
	{
		::sound.PlaySE("sys_cancel");
		::input_all.Lock();
		::loop.End();
		return;
	}

	this.cursor_item.Update();

	if (this.cursor_item.ok)
	{
		if (this.item[this.cursor_item.val] in this.proc)
		{
			this.proc[this.item[this.cursor_item.val]].call(this);
			return;
		}
	}
	else if (this.cursor_item.cancel)
	{
		::loop.End();
		return;
	}
}

function CreateCursor( item )
{
	local cursor = this.Cursor(0, item.len(), ::input_all);
	local skip = [];

	foreach( v in item )
	{
		skip.append(v ? 0 : 1);
	}

	cursor.SetSkip(skip);
	return cursor;
}

function LoadItemText( filename )
{
	local item = ::manbow.LoadCSV(filename);
	local item_table = {};

	foreach( v in item )
	{
		item_table[v[0]] <- v[::config.lang + 1];
	}

	return item_table;
}

function LoadItemTextArray( filename )
{
	local item = ::manbow.LoadCSV(filename);
	local item_table = {};

	foreach( v in item )
	{
		local a = [];

		for( local i = 1 + ::config.lang; i < v.len(); i = i + 2 )
		{
			if (v[i].len() == 0)
			{
				break;
			}

			a.append(v[i]);
		}

		item_table[v[0]] <- a;
	}

	return item_table;
}

function InitializePage( title, item_table )
{
    if (title){
        local t = ::font.CreateSystemString(title);
        t.x = this.title_x - t.width / 2;
        t.y = this.title_y;
    }

	local left = this.item_x;
	local top = this.item_y;
	this.space <- this.item_space;

    foreach(page in this.action.data){

    }

	this.ui <- this.UIBase();
	this.ui.action = this.action.weakref();
	this.ui.target = gl ? gl.weakref() : this.weakref();
	this.text <- [];
	local width = 0;

	foreach( i, v in this.action.item )
	{
		if (v == null)
		{
			this.text.append(null);
			continue;
		}

		local item = item_table[v];
		local t = ::font.CreateSystemString(typeof item == "array" ? item[0] : item);
		t.ConnectRenderSlot(::graphics.slot.overlay, 0);

		if (t.width > width)
		{
			width = t.width;
		}

		t.y = top - 8 + i * this.space;
		this.text.append(t);
	}

	left = left - width / 2;

	foreach( v in this.text )
	{
		if (v)
		{
			v.x = left;
		}
	}

	this.cursor_x <- left - 20;
	this.cursor_y <- top + 16;
	this.mat_world <- ::manbow.Matrix();
	this.ui.Activate(-1);
}

function TerminateLayout()
{
	this.text = null;
}

function UpdateLayout( gl )
{
	if (this.action == ::loop.GetCurrentScene())
	{
		::menu.cursor.SetTarget(this.cursor_x, this.cursor_y + this.action.cursor_item.val * this.space, 0.69999999);
	}

	this.ui.Update();
	this.mat_world.SetTranslation(gl.x, gl.y, 0);

	foreach( i, v in this.text )
	{
		if (v == null)
		{
			continue;
		}

		v.SetWorldTransform(this.mat_world);
		v.red = v.green = v.blue = this.action.cursor_item.val == i ? 1.00000000 : 0.50000000;
	}
}

function UpdateItemString( item_table )
{
	foreach( i, v in this.action.item )
	{
		if (v == null)
		{
			continue;
		}

		local item = item_table[v];
		this.text[i].Set(typeof item == "array" ? item[0] : item);
	}
}