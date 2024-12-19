local network_task={}
network_task.Update<-function(){if(this.team[0].input.b10==120||this.team[1].input.b10==120){::sound.StopBGM(500)
::loop.EndWithFade()}}.bindenv(this)
this.AddTask(network_task)
function Pause(){}
function BeginResult(){if(::config.replay.save_mode_online==0){::replay.Save()}
this.End()}