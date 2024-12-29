this.title_x <- 640;
this.title_y <- 96;
this.item_x <- 640;
this.item_y <- 200;
this.item_space <- 30;
local message_item = ::manbow.LoadCSV("data/system/component/item.csv");
this.message_table <- {};

foreach( v in message_item )
{
	this.message_table[v[0]] <- [
		v[1],
		v[2]
	];
}

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

	// ::debug.print_value(item);
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

	//::debug.print_value(item);
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

function LoadItemTextArrayA( filename )
{
	local item = ::manbow.LoadCSVA(filename);
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

function GetMessageText( name )
{
	return name in this.message_table ? this.message_table[name][::config.lang] : "";
}

function InitializeLayout( gl, item_table )
{
	if (gl)
	{
		gl.title.x = ::menu.common.title_x - this.resource.title.src_width / 2;
		gl.title.y = ::menu.common.title_y;
	}
	else
	{
		this.title.x = ::menu.common.title_x - this.anime_set.title.width / 2;
		this.title.y = ::menu.common.title_y;
	}

	local left = ::menu.common.item_x;
	local top = ::menu.common.item_y;
	this.space <- ::menu.common.item_space;
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

this.proc <- {};
this.proc.exit <- function ()
{
	::loop.End();
};
this.proc.ret_select <- function ()
{
	::sound.StopBGM(500);
	::loop.Fade(function ()
	{
		::loop.End(::menu.character_select);
	});
};
this.proc.ret_story_select <- function ()
{
	::sound.StopBGM(500);
	::loop.Fade(function ()
	{
		::loop.End(::menu.story_select);
	});
};
this.proc.ret_replay_select <- function ()
{
	::sound.StopBGM(500);
	::loop.Fade(function ()
	{
		::loop.End(::menu.replay_select);
	});
};
this.proc.ret_title <- function ()
{
	::sound.StopBGM(500);
	::loop.Fade(function ()
	{
		::loop.End(::menu.title);
	});
};
this.proc.config <- function ()
{
	this.Suspend();
	::menu.config.Initialize();
};
this.proc.hide <- function ()
{
	this.Hide();
	this.Update = function ()
	{
		if (::input_all.b0 == 1 || ::input_all.b1 == 1)
		{
			this.Show();
			this.Update = this.UpdateMain;
		}
	};
};
