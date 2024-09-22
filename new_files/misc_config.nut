this.current_item <- "";
this.item <- [
	"up",
	"down",
	"left",
	"right",
	"b0",
	"b1",
	"b2",
	"b3",
	"b4",
	"t0",
	"t1",
	"t2",
	"b10"
];
this.cursor <- this.Cursor2(2, this.item.len() + 1, ::input_all);
this.side <- 0;
this.update <- null;
this.help <- [
	"B1",
	"ok",
	null,
	"B2",
	"return",
	null,
	"B3",
	"delete_assign YOU ARE MODIFIED",
	null,
	"UDLR",
	"select"
];
this.help_key <- [
	"KEY",
	"input_key",
	null,
	"PAD",
	"cancel"
];
this.help_pad <- [
	"PAD",
	"input_button",
	null,
	"KEY",
	"cancel"
];
this.anime <- {};
::manbow.CompileFile("data/system/key_config/key_config_animation.nut", this.anime);
function Initialize( _side )
{
	::manbow.CompileFile("data/system/key_config/key_config_animation.nut", this.anime);
	::menu.cursor.Activate();
	::menu.back.Activate();
	this.side = _side;
	this.cursor.x = 0;
	this.cursor.y = 0;

	foreach( val in this.item )
	{
		this.key[val] <- ::config.input.key[this.side][val];
		this.pad[val] <- ::config.input.pad[this.side][val];
	}

	this.state <- 0;
	this.update = this.SelectItem;
	this.BeginAnime();
	::loop.Begin(this);
}

function Terminate()
{
	this.state = -1;
	this.EndAnimeDelayed();
	::menu.help.Reset();
	::menu.back.Deactivate();
	::menu.cursor.Deactivate();
}

function Update()
{
	this.update();
}

function SelectItem()
{
	::menu.help.Set(this.help);

	if (::input_all.b10 == 1)
	{
		::sound.PlaySE("sys_cancel");
		::input_all.Lock();
		::loop.End();
		return;
	}

	this.cursor.Update();

	if (this.cursor.ok)
	{
		::input_all.Lock();

		if (this.cursor.y == 13)
		{
			::loop.End();
		}
		else
		{
			this.current_item = this.item[this.cursor.y];

			if (this.cursor.x == 0)
			{
				this.update = this.GetPadStateWait;
			}
			else if (this.cursor.x == 1)
			{
				this.update = this.GetKeyStateWait;
			}

			  // [085]  OP_JMP            0      0    0    0
		}
	}
	else if (this.cursor.cancel)
	{
		::input_all.Lock();
		::loop.End();
	}

	if (::input_all.b2 == 1)
	{
		local c = this.item[this.cursor.y];

		if (this.cursor.x == 0)
		{
			::config.input.pad[this.side][c] = this.pad[c] = -2;
			::config.Save();
		}
		else
		{
			::config.input.key[this.side][c] = this.key[c] = -2;
			::config.Save();
		}

		return;
	}
}