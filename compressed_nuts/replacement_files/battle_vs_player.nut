this.time<-99*90
this.time_unit<-90
this.win<-[0,0]
this.winner<-0
this.match_num<-2
this.round<-0
this.bgm<-null
this.GuardCrash_Check=this.GuardCrash_Check_VS
function Pause(){::sound.PlaySE(111)
::menu.pause.Initialize(0)}
function Begin(){this.Round_Begin()}
function Round_Begin(){this.battleUpdate=this.Game_BeginUpdate
this.state=2
this.demoCount=0
this.endWinDemo=[false,false]
this.endLoseDemo=[false,false]
this.skipDemo=[false,false]
this.enable_contact_test=false
::camera.Reset()
::camera.SetTarget(640,340,2.00000000,true)
if(this.team[0].current.func_beginDemo){this.team[0].current.func_beginDemo()}
if(this.team[1].current.func_beginDemo){this.team[1].current.func_beginDemo()}
::sound.PlayBGM(null)
this.bgm=this.BGMTitle()
this.bgm.Activate()
this.team[0].mp=1000
this.team[1].mp=1000
this.team[0].op=1000
this.team[1].op=1000}
function Game_BeginUpdate(){this.demoCount++
if(this.demoCount>=60){if(this.team[0].current.command){this.team[0].current.command.Update(this.team[0].current.direction,this.team[0].current.hitStopTime<=0&&this.team[0].current.damageStopTime<=0)}
if(this.team[1].current.command){this.team[1].current.command.Update(this.team[1].current.direction,this.team[1].current.hitStopTime<=0&&this.team[1].current.damageStopTime<=0)}
local c0=this.team[0].current.command
local c1=this.team[1].current.command
if(c0.rsv_k0+c0.rsv_k1+c0.rsv_k2+c0.rsv_k3!=0||c1.rsv_k0+c1.rsv_k1+c1.rsv_k2+c1.rsv_k3!=0){this.RoundBeginDemo_Skip()
return}
if(this.endWinDemo[0]&&this.endWinDemo[1]){this.Round_Ready()
return}}}
function RoundBeginDemo_Skip(){this.battleUpdate=this.Game_BeginSkipUpdate
this.state=2
this.demoCount=0
::graphics.FadeOut(10)}
function Game_BeginSkipUpdate(){this.demoCount++
if(this.demoCount==10){this.team[0].current.func_beginDemoSkip()
this.team[1].current.func_beginDemoSkip()
this.team[0].slave.func_beginDemoSkip()
this.team[1].slave.func_beginDemoSkip()}
if(this.demoCount>=10){::graphics.FadeIn(10)
this.Round_Ready()
return}}
function Round_Ready(){this.battleUpdate=this.Game_BattleReady
this.state=4
this.demoCount=0
this.round++
if(this.round>5){this.round=5}
this.gauge.Show()
if(this.bgm){this.bgm.Deactivate()
this.bgm=null}
::discord.rpc_set_state("Round "+this.round+" ("+this.win[0]+" - "+this.win[1]+")")
::discord.rpc_commit()}
function Game_BattleReady(){if(this.team[0].current.command){this.team[0].current.command.Update(this.team[0].current.direction,this.team[0].current.hitStopTime<=0&&this.team[0].current.damageStopTime<=0)}
if(this.team[1].current.command){this.team[1].current.command.Update(this.team[1].current.direction,this.team[1].current.hitStopTime<=0&&this.team[1].current.damageStopTime<=0)}
this.demoCount++
if(this.demoCount==20){this.PlaySE(850)
::actor.SetEffectLight(640,360,1000,this.round-1)}
if(this.demoCount==20+100){this.PlaySE(851)
::actor.SetEffectLight(640,360,1001)}
if(this.demoCount==20+148){this.PlaySE(853)}
if(this.demoCount==20+100+70){this.Round_Fight()}}
function Round_Fight(){this.state=8
this.battleUpdate=this.Game_BattleUpdate
this.enableTimeCount=true
this.enableTimeUp=true
this.enable_contact_test=true
::camera.SetTarget(640,340,2.00000000,true)
::camera.SetMode_Battle()}
function Game_BattleUpdate(){if(this.team[0].current.command){this.team[0].current.command.Update(this.team[0].current.direction,this.team[0].current.hitStopTime<=0&&this.team[0].current.damageStopTime<=0)}
if(this.team[1].current.command){this.team[1].current.command.Update(this.team[1].current.direction,this.team[1].current.hitStopTime<=0&&this.team[1].current.damageStopTime<=0)}
if(this.team[0].CheckKO()||this.team[1].CheckKO()){this.Round_KO()
return}
if(!this.is_time_stop&&this.enableTimeCount&&this.time>=0){this.time--
if(this.time>0&&this.time<this.time_unit*10&&this.time%this.time_unit==0){::sound.PlaySE(867)
this.gauge.FlashTime()}
if(this.time<0){this.time=0}
if(this.time==0&&this.enableTimeUp){this.Round_TimeUP()}}}
function Round_KO(){this.FightEndFunction()
local t_={}
t_.count<-60
t_.priority<-210
::actor.SetEffect(640,360,1.00000000,::actor.effect_class.EF_SpeedLine,t_)
::actor.SetEffectLight(640,360,1001,1)
this.PlaySE(855)
this.state=64
this.demoCount=0
this.enable_contact_test=false
this.enableTimeCount=false
this.endWinDemo=[false,false]
this.endLoseDemo=[false,false]
this.skipDemo=[false,false]
this.SetTimeStop(60)
this.SetWinner()
if(this.win[0]>=this.match_num||this.win[1]>=this.match_num){this.CreateWinData()}
if(this.winner==0){this.battleUpdate=this.Game_DowbleKoUpdate}
else if(this.win[0]>=this.match_num||this.win[1]>=this.match_num){this.battleUpdate=this.Game_FinishUpdate}
else{this.battleUpdate=this.Game_KoUpdate}}
function Game_KoUpdate(){this.demoCount++
if(this.demoCount==120){this.team[0].ResetCombo()
this.team[1].ResetCombo()}
if(this.demoCount>=180){if(this.team[0].current.IsFree()&&this.team[0].current.centerStop==0||this.team[1].current.IsFree()&&this.team[0].current.centerStop==0){this.Round_Win()}}}
function Game_FinishUpdate(){this.demoCount++
if(this.demoCount==60){this.SetSlow(240)}
if(this.demoCount==120){this.team[0].ResetCombo()
this.team[1].ResetCombo()}
if(this.demoCount>=300){this.Round_Win()
return}}
function Game_DowbleKoUpdate(){this.demoCount++
if(this.demoCount==210){this.team[0].ResetCombo()
this.team[1].ResetCombo()
local t_={}
t_.keyTake<-2
this.PlaySE(854)
::actor.SetEffectLight(640,360,1001,3)}
if(this.demoCount==330){this.BeginNextRound()}}
function Round_TimeUP(){this.FightEndFunction()
this.battleUpdate=this.Game_TimeUpUpdate
this.state=64
this.demoCount=0
this.enable_contact_test=false
this.endWinDemo=[false,false]
this.endLoseDemo=[false,false]
this.skipDemo=[false,false]
this.enableTimeCount=false
this.SetWinner()
if(this.win[0]>=this.match_num||this.win[1]>=this.match_num){this.CreateWinData()}
this.PlaySE(852)
::actor.SetEffectLight(640,360,1001,2)
if(this.team[0].current.resetTimeUpFunc){this.team[0].current.resetTimeUpFunc()}
if(this.team[1].current.resetTimeUpFunc){this.team[1].current.resetTimeUpFunc()}}
function Game_TimeUpUpdate(){if((this.team[0].current.IsFree()&&this.team[0].current.centerStop==0)&&this.team[1].current.IsFree()&&this.team[1].current.centerStop==0){this.battleUpdate=function(){this.demoCount++
if(this.demoCount>=150){this.Round_TimeUpCall()
return}}}}
function Round_TimeUpCall(){this.state=64
this.demoCount=0
this.endWinDemo=[false,false]
this.endLoseDemo=[false,false]
this.skipDemo=[false,false]
switch(this.winner){case 0:this.PlaySE(854)
::actor.SetEffectLight(640,360,1001,3)
local w_=this.team[0].current
local l_=this.team[1].current
if(w_.team.current==w_.team.slave){w_.team.current.Team_Lose()}
else if(w_.func_timeDemo){w_.func_timeDemo()}
if(l_.team.current==l_.team.slave){l_.team.current.Team_Lose()}
else if(l_.func_timeDemo){l_.func_timeDemo()}
this.battleUpdate=this.Game_DrawUpdate
break
case 1:local w_=this.team[0].current
local l_=this.team[1].current
if(l_.team.current==l_.team.slave){l_.team.current.Team_Lose()}
else if(l_.func_timeDemo){l_.func_timeDemo()}
this.battleUpdate=this.Game_TimeUpCallUpdate
w_.autoCamera=false
::camera.SetTarget(w_.x,w_.y-20,2.00000000,false)
local a=this.team[0].master
if(a.team.current==a.team.slave){a.team.current.Team_Win()}
else if(a.func_winDemo){a.func_winDemo()}
a.autoCamera=false
::camera.SetTarget(a.x,a.y-20,2.00000000,false)
local t={}
t.winner<-a.type
t.team<-a.team
this.infoActor=[null,null]
if(a.x<=640){if(a.team.index==0){this.infoActor[0]=a.SetEffect(880,460,1.00000000,::actor.effect_class.Round_Call_Win1P,t).weakref()}
else{this.infoActor[0]=a.SetEffect(880,460,1.00000000,::actor.effect_class.Round_Call_Win2P,t).weakref()}
this.infoActor[1]=a.SetFreeObject(0,600,1.00000000,a.WinPlayerName_L,{}).weakref()}
else{if(a.team.index==0){this.infoActor[0]=a.SetEffect(400,460,1.00000000,::actor.effect_class.Round_Call_Win1P,t).weakref()}
else{this.infoActor[0]=a.SetEffect(400,460,1.00000000,::actor.effect_class.Round_Call_Win2P,t).weakref()}
this.infoActor[1]=a.SetFreeObject(1280,600,1.00000000,a.WinPlayerName_R,{}).weakref()}
break
case 2:local w_=this.team[1].current
local l_=this.team[0].current
if(l_.team.current==l_.team.slave){l_.team.current.Team_Lose()}
else if(l_.func_timeDemo){l_.func_timeDemo()}
this.battleUpdate=this.Game_TimeUpCallUpdate
w_.autoCamera=false
::camera.SetTarget(w_.x,w_.y-20,2.00000000,false)
local a=this.team[1].master
if(a.team.current==a.team.slave){a.team.current.Team_Win()}
else if(a.func_winDemo){a.func_winDemo()}
a.autoCamera=false
::camera.SetTarget(a.x,a.y-20,2.00000000,false)
local t={}
t.winner<-a.type
t.team<-a.team
this.infoActor=[null,null]
if(a.x<=640){if(a.team.index==0){this.infoActor[0]=a.SetEffect(880,460,1.00000000,::actor.effect_class.Round_Call_Win1P,t).weakref()}
else{this.infoActor[0]=a.SetEffect(880,460,1.00000000,::actor.effect_class.Round_Call_Win2P,t).weakref()}
this.infoActor[1]=a.SetFreeObject(0,600,1.00000000,a.WinPlayerName_L,{}).weakref()}
else{if(a.team.index==0){this.infoActor[0]=a.SetEffect(400,460,1.00000000,::actor.effect_class.Round_Call_Win1P,t).weakref()}
else{this.infoActor[0]=a.SetEffect(400,460,1.00000000,::actor.effect_class.Round_Call_Win2P,t).weakref()}
this.infoActor[1]=a.SetFreeObject(1280,600,1.00000000,a.WinPlayerName_R,{}).weakref()}
break}}
function Game_TimeUpCallUpdate(){if(this.team[0].current.command){this.team[0].current.command.Update(this.team[0].current.direction,this.team[0].current.hitStopTime<=0&&this.team[0].current.damageStopTime<=0)}
if(this.team[1].current.command){this.team[1].current.command.Update(this.team[1].current.direction,this.team[1].current.hitStopTime<=0&&this.team[1].current.damageStopTime<=0)}
this.demoCount++
if(this.demoCount>30){local c=this.team[0].current.command
this.skipDemo[0]=c.rsv_k0+c.rsv_k1+c.rsv_k2+c.rsv_k3>0
c=this.team[1].current.command
this.skipDemo[1]=c.rsv_k0+c.rsv_k1+c.rsv_k2+c.rsv_k3>0}
if(this.endWinDemo[0]||this.endWinDemo[1]){this.Round_WinCall()}}
function Game_DrawUpdate(){if(this.endLoseDemo[0]&&this.endLoseDemo[1]){this.Round_DrawCall()
return}}
function Round_DrawCall(){this.battleUpdate=this.Game_DrawCallUpdate
this.state=32
this.demoCount=0
this.skipDemo=[false,false]}
function Game_DrawCallUpdate(){this.demoCount++
if(this.demoCount==60){this.BeginNextRound()}}
function Round_Win(){this.battleUpdate=this.Game_WinUpdate
this.state=32
this.demoCount=0
this.endWinDemo=[false,false]
this.skipDemo=[false,false]
local a=this.winner==1?this.team[0].master:this.team[1].master
if(a.team.current==a.team.slave){a.team.current.Team_Win()}
else if(a.func_winDemo){a.func_winDemo()}
a.autoCamera=false
::camera.SetTarget(a.x,a.y-20,2.00000000,false)
local t={}
t.winner<-a.type
t.team<-a.team
this.infoActor=[null,null]
if(a.x<=640){if(a.team.index==0){this.infoActor[0]=a.SetEffect(880,460,1.00000000,::actor.effect_class.Round_Call_Win1P,t).weakref()}
else{this.infoActor[0]=a.SetEffect(880,460,1.00000000,::actor.effect_class.Round_Call_Win2P,t).weakref()}
this.infoActor[1]=a.SetFreeObject(0,600,1.00000000,a.WinPlayerName_L,{}).weakref()}
else{if(a.team.index==0){this.infoActor[0]=a.SetEffect(400,460,1.00000000,::actor.effect_class.Round_Call_Win1P,t).weakref()}
else{this.infoActor[0]=a.SetEffect(400,460,1.00000000,::actor.effect_class.Round_Call_Win2P,t).weakref()}
this.infoActor[1]=a.SetFreeObject(1280,600,1.00000000,a.WinPlayerName_R,{}).weakref()}}
function Game_WinUpdate(){if(this.endWinDemo[0]||this.endWinDemo[1]){this.Round_WinCall()
return}}
function Round_WinCall(){this.battleUpdate=this.Game_WinCallUpdate
this.state=32
this.demoCount=0
this.skipDemo=[false,false]}
function Game_WinCallUpdate(){this.demoCount++
if(this.demoCount==60){if(this.win[0]>=this.match_num||this.win[1]>=this.match_num){if(this.win[0]>=this.match_num&&this.team[0].change_count==0&&this.team[0].current.cpuState==null){::trophy.SoloWin(0)}
if(this.win[1]>=this.match_num&&this.team[1].change_count==0&&this.team[1].current.cpuState==null){::trophy.SoloWin(1)}
this.BeginResult()}
else{this.BeginNextRound()}}}
function BeginNextRound(){this.battleUpdate=this.Game_BeginNextRoundUpdate
this.state=128
this.demoCount=0
if(this.infoActor){foreach(a in this.infoActor){a.func[0].call(a)}}
this.infoActor=null
::graphics.FadeOut(60)}
function Game_BeginNextRoundUpdate(){this.demoCount++
if(this.demoCount>=60){this.RoundReset()
this.Round_Ready()
::graphics.FadeIn(15)}}
function BeginResult(){this.battleUpdate=this.Game_ResultUpdate
this.demoCount=0
if(this.infoActor){foreach(a in this.infoActor){a.func[0].call(a)}}
this.infoActor=null
::talk.Begin("start")}
function Game_ResultUpdate(){}
function BeginResultEnd(){this.battleUpdate=this.Game_ResultEndUpdate}
function Game_ResultEndUpdate(){local b=false
local c=this.team[0].input
if(c.b0||c.b1||c.b2||c.b3||c.b4){b=true}
c=this.team[1].input
if(c.b0||c.b1||c.b2||c.b3||c.b4){b=true}
if(b){this.battleUpdate=function(){this.End()}
::replay.Confirm(null)}}
function FightEndFunction(){this.gauge.Hide()
this.team[0].current.EndSpellCard()
this.team[1].current.EndSpellCard()
this.team[0].master.BuffReset()
this.team[1].master.BuffReset()
this.team[0].slave.BuffReset()
this.team[1].slave.BuffReset()}
function RoundReset(){this.group_player.Clear(~15)
this.group_effect.Clear(-1)
this.team[0].ResetRound()
this.team[1].ResetRound()
::camera.Reset()
::camera.SetTarget(640,340,2.00000000,true)
this.time=99*90
this.enableTimeCount=false
this.enableTimeUp=false}
function SetWinner(){if(this.team[0].life<=0&&this.team[1].life<=0){this.winner=0}
else if(this.team[0].life<=0){this.winner=2}
else if(this.team[1].life<=0){this.winner=1}
else if(this.team[0].life>this.team[1].life){this.winner=1}
else if(this.team[0].life<this.team[1].life){this.winner=2}
else{this.winner=0}
switch(this.winner){case 1:this.gauge.SetWin(0,this.win[0])
this.win[0]++
break
case 2:this.gauge.SetWin(1,this.win[1])
this.win[1]++
break
default:if(this.win[0]>=this.match_num-1&&this.win[1]>=this.match_num-1){}
else{}
break}}
function CreateWinData(){if(this.winner==1){::talk.GenerateResultMessage(this.team[0].master_name,this.team[0].slave_name,this.team[1].master_name,this.team[1].slave_name,false)}
else{::talk.GenerateResultMessage(this.team[1].master_name,this.team[1].slave_name,this.team[0].master_name,this.team[0].slave_name,true)}}
