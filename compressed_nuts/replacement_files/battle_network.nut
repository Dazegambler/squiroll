local network_task={}
if(::network.use_lobby){network_task.Update<-function (){if(this.team[::network.is_client?0:1].input.b10==120){::sound.StopBGM(500)
::loop.EndWithFade()
}
}.bindenv(this)
}
else {network_task.Update<-function (){if(this.team[0].input.b10==120||this.team[1].input.b10==120){::sound.StopBGM(500)
::loop.EndWithFade()
}
}.bindenv(this)
}
this.AddTask(network_task)
function Pause(){}
function BeginResult(){if(::config.replay.save_mode_online==0){::replay.Save()
}
else {}
this.End()
}
