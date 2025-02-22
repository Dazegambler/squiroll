// this.help <- [
// 	"B1",
// 	"ok",
// 	null,
// 	"B2",
// 	"return",
// 	null,
// 	"UD",
// 	"select",
// 	null,
// 	"LR",
// 	"page"
// ];
// this.data{
// 	ping_display<-{
// 		page<-0;
// 		enabled<-this.Cursor(1,2,::input_all);
// 		x<-640;
// 		y<-705;
// 		sx<-1.0;
// 		sy<-1.0;
// 		color<-"FFFFFFFF";
// 		frame_delay<-this.Cursor(1,2,::input_all);
// 	},
// 	input_display_p1<-{
// 		page<-1;
// 		enabled<-this.Cursor(1,2,::input_all);
// 		x<-10;
// 		y<-515;
// 		sx<-1.0;
// 		sy<-1.0;
// 		offset<-30;
// 		count<-12;
// 		color<-"FF00FF00";
// 		spacing<-this.Cursor(1,2,::input_all);
// 		timer<-200;
// 		raw_input<-this.Cursor(1,2,::input_all);
// 		notation<-"1,2,3,4,5,6,7,8,9, ,A,B,[B],C,E,D";
// 	},
// };
// this.proc <- {};
// this.page <- [];
// this.cur_index <- 0;
// this.cur_page <- 0;
// this.anime <- {};
// ::manbow.compilebuffer("mod_config_animation.nut", this.anime);
// function Initialize(){
// 	::loop.Begin(this);
// 	//more
// 	this.cursor <- this.Cursor(0, this.page[0].len(), ::input_all);
// 	this.cursor.se_ok = 0;
// 	this.cursor_page <- this.Cursor(1, this.page.len(), ::input_all);
// 	this.cursor_page.enable_ok = false;
// 	this.cursor_page.enable_cancel = false;
// 	::menu.cursor.Activate();
// 	::menu.back.Activate();
// 	::menu.help.Set(this.help);
// 	this.BeginAnime();
// }

// function Terminate(){
// 	this.page.resize(0);
// 	this.data.resize(0);
// 	this.EndAnimeDelayed();
// 	::menu.help.Reset();
// 	::menu.back.Deactivate();
// 	::menu.cursor.Deactivate();
// }

// function Update(){

// }

// // function Update()
// // {
// // 	this.update();
// // }



// // function SelectItem()
// // {
// // 	::menu.help.Set(this.help);

// // 	if (::input_all.b10 == 1)
// // 	{
// // 		::sound.PlaySE("sys_cancel");
// // 		::input_all.Lock();
// // 		::loop.End();
// // 		return;
// // 	}

// // 	this.cursor.Update();

// // 	if (this.cursor.ok)
// // 	{
// // 		::input_all.Lock();

// // 		if (this.cursor.y == 10)
// // 		{
// // 			::loop.End();
// // 		}
// // 		else
// // 		{
// // 			this.current_item = this.item[this.cursor.y];

// // 			if (this.cursor.x == 0)
// // 			{
// // 				this.update = this.GetPadStateWait;
// // 			}
// // 			else if (this.cursor.x == 1)
// // 			{
// // 				this.update = this.GetKeyStateWait;
// // 			}

// // 			  // [085]  OP_JMP            0      0    0    0
// // 		}
// // 	}
// // 	else if (this.cursor.cancel)
// // 	{
// // 		::input_all.Lock();
// // 		::loop.End();
// // 	}
// // }

// // function GetKeyStateWait()
// // {
// // 	if (::manbow.GetKeyboardState() >= 0)
// // 	{
// // 		return;
// // 	}

// // 	if (::manbow.GetPadButtonState() >= 0)
// // 	{
// // 		return;
// // 	}

// // 	this.update = this.GetKeyState;
// // }

// // function GetKeyState()
// // {
// // 	::menu.help.Set(this.help_key);
// // 	local id = ::manbow.GetKeyboardState();

// // 	if (id >= 0)
// // 	{
// // 		::sound.PlaySE("sys_ok");
// // 		this.key[this.current_item] = id;
// // 		::config.input.key[this.side][this.current_item] = this.key[this.current_item];
// // 		::config.Save();
// // 		this.update = this.SelectItem;
// // 		return;
// // 	}

// // 	id = ::manbow.GetPadButtonState();

// // 	if (id >= 0)
// // 	{
// // 		this.key[this.current_item] = ::config.input.key[this.side][this.current_item];
// // 		::sound.PlaySE("sys_cancel");
// // 		this.update = this.SelectItem;
// // 		return;
// // 	}

// // 	this.key[this.current_item] = -1;
// // }

// // function GetPadStateWait()
// // {
// // 	if (::manbow.GetKeyboardState() >= 0)
// // 	{
// // 		return;
// // 	}

// // 	if (::manbow.GetPadButtonState() >= 0)
// // 	{
// // 		return;
// // 	}

// // 	this.update = this.GetPadState;
// // }

// // function GetPadState()
// // {
// // 	::menu.help.Set(this.help_pad);
// // 	local id = ::manbow.GetPadButtonState();

// // 	if (id >= 0)
// // 	{
// // 		::sound.PlaySE("sys_ok");
// // 		this.pad[this.current_item] = id;
// // 		::config.input.pad[this.side][this.current_item] = this.pad[this.current_item];
// // 		::config.Save();
// // 		this.update = this.SelectItem;
// // 		return;
// // 	}

// // 	id = ::manbow.GetKeyboardState();

// // 	if (id >= 0)
// // 	{
// // 		::sound.PlaySE("sys_cancel");
// // 		this.pad[this.current_item] = ::config.input.pad[this.side][this.current_item];
// // 		this.update = this.SelectItem;
// // 		return;
// // 	}

// // 	this.pad[this.current_item] = -1;
// // }

