this.item<-["lobby_incomming","lobby_match","lobby_select",null,"server","client","watch",null,"player_name","port","upnp","allow_watch",null,"exit"]
this.room_name<-["Free","Novice","Veteran","EU","NA","SA","Asia"]
this.room_title<-["Free","Novice","Veteran","EU","NA","SA","Asia"]
this.cursor_item<-this.Cursor(0,this.item.len(),::input_all)
local skip=[]
foreach(v in this.item){skip.push(v?0:1)}
this.cursor_item.SetSkip(skip)
this.update<-null
this.state<-0
this.plugin<-{}
this.plugin.se_lobby<-::libact.LoadPlugin("data/plugin/se_lobby.dll")
::LOBBY.SetMaxNickLength(32)
this.plugin.se_upnp<-::libact.LoadPlugin("data/plugin/se_upnp.dll")
this.cursor_lobby<-this.Cursor(1,this.room_name.len(),::input_all)
this.target_addr_v<-[]
for(local i=0;i<12+5;i=++i){local c=this.Cursor(0,10,::input_all)
c.dir=-1
c.enable_ok=false
c.enable_cancel=false
this.target_addr_v.push(c)}
this.target_addr_h<-this.Cursor(1,12+5,::input_all)
this.server_port_v<-[]
for(local i=0;i<5;i=++i){local c=this.Cursor(0,10,::input_all)
c.dir=-1
c.enable_ok=false
c.enable_cancel=false
this.server_port_v.push(c)}
this.display_ip_on_wait<-false
this.server_port_h<-this.Cursor(1,5,::input_all)
this.cursor_upnp<-this.Cursor(1,2,::input_all)
this.cursor_allow_watch<-this.Cursor(1,2,::input_all)
this.timeout<-0
this.upnp_timeout<-0
this.retry_count<-0
this.lobby_user_state<-0
this.lobby_interval<-10*1000
this.lobby_time_stamp<-::manbow.timeGetTime()-this.lobby_interval+1000
this.help<-["B1","ok",null,"B2","return",null,"UD","select"]
this.help_cancel<-["B2","cancel"]
this.help_port<-["B1","ok",null,"B2","cancel",null,"UD","val",null,"LR","digit"]
this.help_addr<-["B1","ok","B2","cancel","B3","clipboard","UD","val","LR","digit"]
this.help_item<-["B1","ok",null,"B2","cancel",null,"LR","change"]
this.is_suspend<-false
this.dialog_wait<-{}
::manbow.CompileFile("data/system/network/dialog_wait.nut",this.dialog_wait)
this.dialog_address<-{}
::manbow.CompileFile("data/system/network/dialog_address.nut",this.dialog_address)
this.dialog_port<-{}
::manbow.CompileFile("data/system/network/dialog_port.nut",this.dialog_port)
this.dialog_connect<-{}
::manbow.CompileFile("data/system/network/dialog_connect.nut",this.dialog_connect)
this.anime<-{}
::manbow.CompileFile("data/system/network/network_animation.nut",this.anime)
function Initialize(){this.item_table<-::menu.common.LoadItemTextArray("data/system/network/item.csv")
::menu.cursor.Activate()
::menu.back.Activate()
this.update=this.UpdateMain
this.state=0
this.is_suspend=false
this.timeout=0
this.upnp_timeout=0
this.lobby_time_stamp=::manbow.timeGetTime()-9000
if(this.cursor_item.val!=0){this.cursor_item.val=0
this.cursor_item.diff=-1}
::LOBBY.SetPrefix(::network.lobby_prefix)
::LOBBY.SetExternalPort(::config.network.hosting_port)
::LOBBY.SetVersionSig(::network.lobby_version_sig)
::LOBBY.SetStrikeFactor(1,1000)
local n=::config.network.lobby_name
::config.network.lobby_name=this.room_name[0]
this.cursor_lobby.val=0
foreach(i,v in this.room_name){if(n==v){::config.network.lobby_name=v
this.cursor_lobby.val=i
break}}
this.SetHostingPortToCursor(::config.network.hosting_port)
this.SetTargetHostToCursor(::config.network.target_host)
this.SetTargetPortToCursor(::config.network.target_port)
this.cursor_upnp.val=::config.network.upnp?0:1
this.cursor_allow_watch.val=::config.network.allow_watch?0:1
this.BeginAnime()
::loop.Begin(this)}
function Terminate(){this.state=-1
::menu.help.Reset()
::menu.back.Deactivate()
::menu.cursor.Deactivate()
this.EndAnimeDelayed()
this.update=null
this.LobbyTerminate()
::network.Terminate()}
function Suspend(){::loop.End(::menu.network)
this.is_suspend=true
::menu.title.Hide()
::menu.help.Reset()
::menu.cursor.Deactivate()
::menu.back.Deactivate(true)
::effect.Clear()
this.EndAnime()}
function Resume(){if(!this.is_suspend){return}
this.is_suspend=false
::sound.PlayBGM(::savedata.GetTitleBGMID())
::menu.title.Show()
if(::network.return_code==0){::Dialog(0,::menu.common.GetMessageText("disconnect"))}
else{}
::network.Terminate()
this.update=this.UpdateMain
this.timeout=0
this.upnp_timeout=0
::menu.cursor.Activate()
::menu.back.Activate()
this.BeginAnime()}
function Update(){if(::input_all.b10==1){::sound.PlaySE("sys_cancel")
::loop.End()
return}
this.LobbyUpdate()
if(this.update){this.update()}}
function UpdateMain(){::discord.rpc_commit_details_and_state("Idle","")
::menu.help.Set(this.help)
this.cursor_item.Update()
::punch.ignore_ping()
if(::input_all.b0==1){::input_all.Lock()
::network.local_device_id=::input_all.GetLastDevice()
switch(this.cursor_item.val){case 0:if(::LOBBY.GetNetworkState()==2){::discord.rpc_commit_details_and_state("Waiting in "+::config.network.lobby_name,"")
::LOBBY.SetExternalPort(::config.network.hosting_port)
::LOBBY.SetUserData(""+::config.network.hosting_port)
this.upnp_timeout=0
if(!::config.network.upnp){::LOBBY.SetLobbyUserState(::LOBBY.WAIT_INCOMMING)}
this.lobby_user_state=::LOBBY.WAIT_INCOMMING
::network.use_lobby=true
::network.StartupServer(::config.network.hosting_port,0)
::lobby.inc_user_count()
this.update=this.UpdateMatch
this.display_ip_on_wait=false
::Dialog(-1,this.item_table.wait_incomming[0],null,this.dialog_wait.InitializeWithUPnP)}
break
case 1:if(::LOBBY.GetNetworkState()==2){::discord.rpc_commit_details_and_state("Searching in "+::config.network.lobby_name,"")
::LOBBY.SetExternalPort(::config.network.hosting_port)
::LOBBY.SetUserData(""+::config.network.hosting_port)
::LOBBY.SetLobbyUserState(::LOBBY.MATCHING)
this.lobby_user_state=::LOBBY.MATCHING
this.update=this.UpdateMatch
this.display_ip_on_wait=false
::Dialog(-1,this.item_table.find[0],null,this.dialog_wait.Initialize)}
break
case 2:this.update=this.UpdateSelectLobby
break
case 4: ::discord.rpc_commit_details_and_state("Waiting for connection","")
::network.use_lobby=false
::network.StartupServer(::config.network.hosting_port,1)
this.update=this.UpdateWaitServer
::punch.reset_ip()
this.display_ip_on_wait=true
::Dialog(-1,this.item_table.wait_incomming[0],null,this.dialog_wait.InitializeWithUPnP)
break
case 5:this.target_addr_h.val=0
::Dialog(-1,this.item_table.input_address[0],null,this.dialog_address.Initialize)
break
case 6:this.target_addr_h.val=0
::Dialog(-1,this.item_table.input_address[0],null,this.dialog_address.Initialize)
break
case 8: ::Dialog(2,::menu.common.GetMessageText("input_name"),function(ret){if(ret){::config.network.player_name=ret
::config.Save()}},::config.network.player_name)
break
case 9:this.SetHostingPortToCursor(::config.network.hosting_port)
this.server_port_h.val=0
::Dialog(-1,this.item_table.input_port[0],null,this.dialog_port.Initialize)
break
case 10:this.update=this.UpdateUPnP
break
case 11:this.update=this.UpdateAllowWatch
break
case 13: ::loop.End()
break}}
else if(::input_all.b1==1){::loop.End()}}
function UpdateSelectLobby(){::menu.help.Set(this.help_item)
this.cursor_lobby.Update()
if(this.cursor_lobby.ok){::config.network.lobby_name=this.room_name[this.cursor_lobby.val]
::config.Save()
this.lobby_time_stamp=::manbow.timeGetTime()-9000
::LOBBY.Close()
this.update=this.UpdateMain}
if(this.cursor_lobby.cancel){this.update=this.UpdateMain}}
function UpdateUPnP(){::menu.help.Set(this.help_item)
this.cursor_upnp.Update()
if(this.cursor_upnp.ok){::config.network.upnp=this.cursor_upnp.val==0?true:false
::config.Save()
this.update=this.UpdateMain}
if(this.cursor_upnp.cancel){this.update=this.UpdateMain}}
function UpdateAllowWatch(){::menu.help.Set(this.help_item)
this.cursor_allow_watch.Update()
if(this.cursor_allow_watch.ok){::config.network.allow_watch=this.cursor_allow_watch.val==0?true:false
::config.Save()
this.update=this.UpdateMain}
if(this.cursor_allow_watch.cancel){this.update=this.UpdateMain}}
function UpdateInputPort(){::menu.help.Set(this.help_port)
this.server_port_h.Update()
this.server_port_v[this.server_port_h.val].Update()
if(::input_all.b0==1){local port=0
for(local i=0;i<5;i=++i){port=port*10
port=port+this.server_port_v[i].val}
::config.network.hosting_port=port
::config.Save()
::loop.End()}
else if(::input_all.b1==1){::loop.End()}}
function UpdateWaitServer(){::menu.help.Set(this.help_cancel)
if(::input_all.b1==1){::network.Terminate()
this.update=this.UpdateMain
::loop.End()}
if(::input_all.b2==1){::punch.copy_ip_to_clipboard()}}
function UpdateInputAddr(){::menu.help.Set(this.help_addr)
this.target_addr_h.Update()
this.target_addr_v[this.target_addr_h.val].Update()
if(::input_all.b0==1){local addr=""
local t=0
for(local i=0;i<12;i=++i){if(i==3||i==6||i==9){addr=addr+t
addr=addr+"."
t=0}
t=t*10
t=t+this.target_addr_v[i].val}
addr=addr+t
local port=0
for(local i=12;i<12+5;i=++i){port=port*10
port=port+this.target_addr_v[i].val}
::network.StartupClient(addr,port,this.item[this.cursor_item.val]=="watch"?3:2)
this.update=this.UpdateWaitClient
::config.network.target_host=addr
::config.network.target_port=port
::config.Save()
::loop.End()
::Dialog(-1,this.item_table[this.item[this.cursor_item.val]=="watch"?"connect_watch":"connect"][0],null,this.dialog_connect.Initialize)}
else if(::input_all.b1==1){::network.Terminate()
::loop.End()}
if(::input_all.b2==1){local ret=this.GetIPAddress(::manbow.GetClipboardString())
if(ret!=""){this.SetTargetHostToCursor(this.GetHostName(ret))
this.SetTargetPortToCursor(this.GetHostPort(ret).tointeger())}}}
function UpdateWaitClient(){::menu.help.Set(this.help_cancel)
if(::input_all.b1==1){::network.Terminate()
this.update=this.UpdateMain
::loop.End()
::Dialog(-1,this.item_table.input_address[0],null,this.dialog_address.Initialize)}
switch(::network.return_code){case 1:this.update=this.UpdateMain
::loop.End()
::Dialog(0,::menu.common.GetMessageText("error_busy"))
::network.Terminate()
break
case 2:this.update=this.UpdateMain
::loop.End()
::Dialog(0,::menu.common.GetMessageText("error_version"))
::network.Terminate()
break
case 3:this.update=this.UpdateMain
::loop.End()
::Dialog(0,::menu.common.GetMessageText("error_watch"))
::network.Terminate()
break
case 4:this.update=this.UpdateMain
::loop.End()
::Dialog(0,::menu.common.GetMessageText("error_ready"))
::network.Terminate()
break}}
function UpdateMatch(){::menu.help.Set(this.help_cancel)
if(::input_all.b1==1){if(this.cursor_item.val==0){::lobby.dec_user_count()}
::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION)
::network.Terminate()
::loop.End()
this.update=this.UpdateMain
return}
if(::config.network.upnp){if(::LOBBY.GetLobbyUserState()==::LOBBY.NO_OPERATION){if(::UPnP.GetAsyncState()==2||this.upnp_timeout++>360){::LOBBY.SetLobbyUserState(::LOBBY.WAIT_INCOMMING)}}}
if(::LOBBY.GetLobbyUserState()==102){if(this.timeout++>360){if(this.retry_count++>5){this.lobby_user_state=::LOBBY.MATCHING}
::LOBBY.SetLobbyUserState(this.lobby_user_state)
this.timeout=0
return}}
else{this.timeout=0}
local st_host=::LOBBY.GetMatchHost()
local st_userdata=::LOBBY.GetMatchUserData()
if(st_host!=""){::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION)
::network.Terminate()
::network.StartupClient(this.GetHostName(st_host),st_userdata.tointeger(),0)
this.update=this.UpdateMatchWait
return}}
function UpdateMatchWait(){::menu.help.Set(this.help_cancel)
if(::input_all.b1==1){if(this.cursor_item.val==0){::lobby.dec_user_count()}
::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION)
::network.Terminate()
::loop.End()
this.update=this.UpdateMain
return}
if(this.timeout++>360){::LOBBY.SetLobbyUserState(this.lobby_user_state)
::network.Terminate()
this.timeout=0
if(this.lobby_user_state==::LOBBY.WAIT_INCOMMING){::network.StartupServer(::config.network.hosting_port,0)}
this.update=this.UpdateMatch
return}}
function LobbyUpdate(){local now=::manbow.timeGetTime()
if(now-this.lobby_time_stamp<this.lobby_interval){return}
this.lobby_time_stamp=now
if(::config.network.lobby_name!=""){if(::LOBBY.GetNetworkState()==::LOBBY.CLOSED){local lobby_server="service1.tasofro.net"
local lobby_port="49955"
local lobby_pass="kzxmckfqbpqieh8rw<rczuturKfnsjxhauhybttboiuuzmWdmnt5mnlczpythaxf"
::LOBBY.Connect(lobby_server,""+lobby_port,lobby_pass,::config.network.lobby_name,::config.network.lobby_name)}}
else if(::LOBBY.GetNetworkState()!=::LOBBY.CLOSED){::LOBBY.Close()
this.lobby_time_stamp-=9000}}
function LobbyTerminate(){if(::LOBBY.GetNetworkState()!=::LOBBY.CLOSED){::LOBBY.Close()}}
function SetTargetHostToCursor(t){for(local i=0;i<4;i=++i){local val=0
local d=t.find(".")
if(d){val=t.slice(0,d).tointeger()
t=t.slice(d+1)}
else{val=t.tointeger()}
this.target_addr_v[i*3+2].val=val%10
val=val/10
this.target_addr_v[i*3+1].val=val%10
val=val/10
this.target_addr_v[i*3].val=val}}
function SetHostingPortToCursor(t){local t=::config.network.hosting_port
for(local i=4;i>=0;i=--i){this.server_port_v[i].val=t%10
t=t/10}}
function SetTargetPortToCursor(t){for(local i=4;i>=0;i=--i){this.target_addr_v[12+i].val=t%10
t=t/10}}
function GetHostName(_str){local delimit_pos=_str.find(":")
if(delimit_pos!=null){return _str.slice(0,delimit_pos)}
return _str}
function GetHostPort(_str){local delimit_pos=_str.find(":")
if(delimit_pos!=null){return _str.slice(delimit_pos+1)}
return null}
function GetIPAddress(text){local ex=this.regexp("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{1,5}")
local ret=ex.search(text)
if(ret==null){return""}
return text.slice(ret.begin,ret.end)}