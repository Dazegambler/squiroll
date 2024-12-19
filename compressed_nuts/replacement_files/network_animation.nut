this.anime_set<-::actor.LoadAnimationData("data/system/network/network.pat")
function Initialize(){this.action<-::menu.network.weakref()
this.x<-0
this.y<-0
this.visible<-true
this.item<-[]
this.active<-false
this.texture<-::manbow.Texture()
this.texture.Load("data/system/network/network_font.png")
local res
res=this.anime_set.title
this.title<-::manbow.Sprite()
this.title.Initialize(this.texture,res.left,res.top,res.width,res.height)
this.item.push(this.title)
local item_table=this.action.item_table
::menu.common.InitializeLayout.call(this,null,item_table)
local item_width=548
local left=::menu.common.item_x-item_width/2-36
local text_table={}
foreach(i,v in this.action.item){if(v==null){continue}
local t=this.text[i]
t.x=left
text_table[v]<-t}
this.cursor_x<-left-20
local item_left=340
this.select_obj<-[]
this.player_name<-::font.CreateSystemString(::config.network.player_name)
this.player_name.x=text_table.player_name.x+item_left
this.player_name.y=text_table.player_name.y
this.player_name.blue=0
this.item.push(this.player_name)
this.port<-::font.CreateSystemString(::config.network.hosting_port.tostring())
this.port.x=text_table.port.x+item_left
this.port.y=text_table.port.y
this.port.blue=0
this.item.push(this.port)
local select_x=left+item_left+40
local _width=item_width-item_left
local t=["upnp","allow_watch"]
foreach(v in t){if(!("cursor_"+v in this.action)){continue}
this.select_obj.append(this.UIItemSelectorSingle(item_table[v].slice(1),text_table[v].x+item_left,text_table[v].y,this.mat_world,this.action["cursor_"+v]))
this.select_obj.top().SetColor(1,1,0)}
this.select_obj.append(this.UIItemSelectorSingle(this.action.room_title,text_table.lobby_select.x+item_left,text_table.lobby_select.y,this.mat_world,this.action.cursor_lobby))
this.select_obj.top().SetColor(1,1,0)
local a=item_table.lobby_state
local t=::font.CreateSystemString(a[0])
t.x=text_table.lobby_incomming.x+item_left
t.y=text_table.lobby_incomming.y
this.item.push(t)
this.lobby_state<-[]
for(local i=1;i<4;i=++i){local t=::font.CreateSystemString(a[i])
t.x=text_table.lobby_incomming.x+item_left+200
t.y=text_table.lobby_incomming.y
this.item.push(t)
this.lobby_state.push(t)}
this.lobby_state[0].green=0
this.lobby_state[0].blue=0
this.lobby_state[1].blue=0
this.lobby_state[2].red=0
this.lobby_user_str<-::font.CreateSystemString("Users: ")
this.lobby_user_str.x=670
this.lobby_user_str.y=222
this.lobby_user_str.visible=false
this.item.push(this.lobby_user_str)
foreach(v in this.item){v.ConnectRenderSlot(::graphics.slot.overlay,0)}
this.state<-0
::loop.AddTask(this)}
function Terminate(){::menu.common.TerminateLayout.call(this)
this.title=null
this.item=null
this.lobby_state=null
this.port=null
this.player_name=null
this.select_obj=null
this.texture=null
this.lobby_user_str=null
::loop.DeleteTask(this)}
function Update(){::menu.common.UpdateLayout.call(this,this)
local state=::LOBBY.GetNetworkState()
if(state!=::LOBBY.CLOSED){this.lobby_user_str.Set("Users: "+::lobby.user_count())
this.lobby_user_str.visible=true}else{this.lobby_user_str.visible=false}
foreach(v in this.lobby_state){v.visible=false}
switch(state){case 0:case 1:case 2:this.lobby_state[state].visible=true
break
default:this.lobby_state[0].visible=true
break}
this.player_name.Set(::config.network.player_name)
this.port.Set(::config.network.hosting_port.tostring())
foreach(v in this.select_obj){v.Update()}
foreach(v in this.item){v.SetWorldTransform(this.mat_world)}}