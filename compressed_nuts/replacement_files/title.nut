if(!::setting.misc.hide_wip){this.item<-["story","tutorial","vs_com","vs_player","network","practice","replay","music","config","exit"]
}else{ this.item<-["story","vs_com","vs_player","network","practice","replay","music","config","exit"]
}
this.proc<-{}
this.cursor<-this.Cursor(0,this.item.len(),::input_all)
this.cursor_difficulty<-this.Cursor(0,4,::input_all)
this.op<-{}
::manbow.CompileFile("data/system/title/op.nut",this.op)
this.anime<-{}
::manbow.CompileFile("data/system/title/title_animation.nut",this.anime)
this.new_version<-false
this.visible<-false
function Initialize(){::INFORMATION.UpdateNewestVersion("th155")
this.Show()
if(::setting.misc.skip_intro){this.Update<-this.UpdateMain
::sound.PlayBGM(::savedata.GetTitleBGMID())
}else {this.Update<-this.UpdateOP
this.op.Initialize()
}
::loop.Begin(this)
}
function Suspend(){this.Hide()
::effect.Clear()
}
function Resume(){this.Show()
this.anime.Resume()
::sound.PlayBGM(::savedata.GetTitleBGMID())
this.Update<-this.UpdateMain
}
function Show(){if(this.visible){return
}
::menu.cursor.Activate()
this.visible=true
this.anime.Initialize()
}
function Hide(){if(!this.visible){return
}
::menu.cursor.Deactivate()
this.visible=false
this.anime.Terminate()
}
function UpdateOP(){if(::input_all.b0==1||::input_all.b1==1){::loop.Fade(function (){::menu.title.Update=::menu.title.UpdateMain
::menu.title.op.Terminate()
::menu.title.op=null
},30)
this.Update=function (){}
}
}
function UpdateMain(){this.new_version=::INFORMATION.GetNewestVersion()>this.GetUpdaterVersion()
this.cursor.Update()
if(this.cursor.ok){::input_all.Lock()
if(this.item[this.cursor.val] in this.proc){this.proc[this.item[this.cursor.val]].call(this)
}
}
else if(this.cursor.cancel){this.cursor.val=this.item.len()-1
}
this.anime.Update()
}
function UpdateDifficulty(){this.cursor_difficulty.Update()
if(this.cursor_difficulty.ok){if(this.cursor.val==0){if(this.cursor_difficulty.val!=::config.difficulty.story){::config.difficulty.story=this.cursor_difficulty.val
::config.Save()
}
::input_all.Lock()
::loop.Fade(function (){::menu.title.Suspend()
::menu.story_select.Initialize(::menu.title.cursor_difficulty.val)
})
}
else {if(this.cursor_difficulty.val!=::config.difficulty.vs){::config.difficulty.vs=this.cursor_difficulty.val
::config.Save()
}
::input_all.Lock()
::loop.Fade(function (){::menu.title.Suspend()
::menu.character_select.Initialize(0,this.cursor_difficulty.val)
}.bindenv(this))
}
}
else if(this.cursor_difficulty.cancel){this.Update=this.UpdateMain
}
this.anime.Update()
}
this.proc.story<-function (){local num=::savedata.GetDifficultyNum()
this.cursor_difficulty.SetItemNum(num)
this.cursor_difficulty.val=::config.difficulty.story
if(this.cursor_difficulty.val>=num){this.cursor_difficulty.val=num-1
}
this.Update=this.UpdateDifficulty
}
this.proc.vs_com<-function (){this.cursor_difficulty.SetItemNum(4)
this.cursor_difficulty.val=::config.difficulty.vs
this.Update=this.UpdateDifficulty
}
this.proc.vs_player<-function (){::loop.Fade(function (){::menu.title.Suspend()
::menu.character_select.Initialize(1)
})
}
this.proc.network<-function (){::menu.network.Initialize()
}
this.proc.tutorial<-function (){::loop.Fade(function (){::menu.title.Suspend()
::tutorial.Initialize()
})
}
this.proc.practice<-function (){::loop.Fade(function (){::menu.title.Suspend()
::menu.character_select.Initialize(40)
})
}
this.proc.replay<-function (){::loop.Fade(function (){::menu.title.Suspend()
::menu.replay_select.Initialize()
})
}
this.proc.music<-function (){::loop.Fade(function (){::menu.title.Suspend()
::menu.music_room.Initialize()
})
}
this.proc.config<-function (){::menu.config.Initialize(true)
}
this.proc.exit<-function (){::sound.StopBGM(500)
::graphics.FadeOut(45,function (){::ExitGame()
})
::loop.End()
}
