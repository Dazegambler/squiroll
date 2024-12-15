this.current_item<-""
this.item<-["up","down","left","right","b0","b1","b2","b3","b4","b10"]
this.key<-{}
this.pad<-{}
this.cursor<-this.Cursor2(2,this.item.len()+1,::input_all)
this.side<-0
this.update<-null
this.help<-["B1","ok",null,"B2","return",null,"UDLR","select"]
this.help_key<-["KEY","input_key",null,"PAD","cancel"]
this.help_pad<-["PAD","input_button",null,"KEY","cancel"]
this.anime<-{}
::manbow.compilebuffer("mod_config_animation.nut",this.anime)
function Initialize(_side){::manbow.compilebuffer("mod_config_animation.nut",this.anime)
::menu.cursor.Activate()
::menu.back.Activate()
this.side=_side
this.cursor.x=0
this.cursor.y=0
foreach(val in this.item){this.key[val]<-::config.input.key[this.side][val]
this.pad[val]<-::config.input.pad[this.side][val]
}
this.state<-0
this.update=this.SelectItem
this.BeginAnime()
::loop.Begin(this)
}
function Terminate(){this.state=-1
this.EndAnimeDelayed()
::menu.help.Reset()
::menu.back.Deactivate()
::menu.cursor.Deactivate()
}
function Update(){this.update()
}
function SelectItem(){::menu.help.Set(this.help)
if(::input_all.b10==1){::sound.PlaySE("sys_cancel")
::input_all.Lock()
::loop.End()
return
}
this.cursor.Update()
if(this.cursor.ok){::input_all.Lock()
if(this.cursor.y==10){::loop.End()
}
else{this.current_item=this.item[this.cursor.y]
if(this.cursor.x==0){this.update=this.GetPadStateWait
}
else if(this.cursor.x==1){this.update=this.GetKeyStateWait
}
}
}
else if(this.cursor.cancel){::input_all.Lock()
::loop.End()
}
}
function GetKeyStateWait(){if(::manbow.GetKeyboardState()>=0){return
}
if(::manbow.GetPadButtonState()>=0){return
}
this.update=this.GetKeyState
}
function GetKeyState(){::menu.help.Set(this.help_key)
local id=::manbow.GetKeyboardState()
if(id>=0){::sound.PlaySE("sys_ok")
this.key[this.current_item]=id
::config.input.key[this.side][this.current_item]=this.key[this.current_item]
::config.Save()
this.update=this.SelectItem
return
}
id=::manbow.GetPadButtonState()
if(id>=0){this.key[this.current_item]=::config.input.key[this.side][this.current_item]
::sound.PlaySE("sys_cancel")
this.update=this.SelectItem
return
}
this.key[this.current_item]=-1
}
function GetPadStateWait(){if(::manbow.GetKeyboardState()>=0){return
}
if(::manbow.GetPadButtonState()>=0){return
}
this.update=this.GetPadState
}
function GetPadState(){::menu.help.Set(this.help_pad)
local id=::manbow.GetPadButtonState()
if(id>=0){::sound.PlaySE("sys_ok")
this.pad[this.current_item]=id
::config.input.pad[this.side][this.current_item]=this.pad[this.current_item]
::config.Save()
this.update=this.SelectItem
return
}
id=::manbow.GetKeyboardState()
if(id>=0){::sound.PlaySE("sys_cancel")
this.pad[this.current_item]=::config.input.pad[this.side][this.current_item]
this.update=this.SelectItem
return
}
this.pad[this.current_item]=-1
}
