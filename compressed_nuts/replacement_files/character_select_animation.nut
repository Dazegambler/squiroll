::menu.character_select.help_copy<-clone::menu.character_select.help
::menu.character_select.help_copy.insert(6,"B3")
::menu.character_select.help_copy.insert(7,"copy_watch")
::menu.character_select.help_copy.insert(8,null)
function Initialize(){::discord.rpc_set_state("Choosing a character")
::discord.rpc_commit()
this.mode<-0
this.anime_set<-::manbow.AnimationSet2D()
local lang=::config.lang==1?"_en":""
this.anime_set.Load("data/system/select/character_select"+lang+".pat",null)
this.anime_set.Load("data/system/select/character_select2.pat",null)
this.anime_set.Load("data/system/select/name/name"+lang+".pat",null)
this.anime_set.Load("data/system/select/stage_name/stage_name"+lang+".pat",null)
this.anime_set.Load("data/system/select/stage_pic/stage_pic.pat",null)
this.anime_set.Load("data/system/select/bgm_name/bgm_name.pat",null)
this.take<-::actor.LoadAnimationData("data/system/select/pic/pic.pat",true)
this.take_id<-{}
local callback=function(){if(!::menu.character_select.anime){return}
local prop=::manbow.Animation2DProperty()
prop.texture_name=this.texture_name
prop.id=this.id
prop.width=this.texture.width
prop.height=this.texture.height
prop.offset_x=this.offset_x
prop.offset_y=this.offset_y
prop.index=1
prop.frame=9999
prop.filter=1
prop.is_loop=true
::menu.character_select.anime.take_id[this.id]<-true
::menu.character_select.anime.anime_set.Create(prop)}
for(local j=0;j<2;j=++j){for(local i=0;i<this.character_id.len();i=++i){local v=this.take[1000*j+1000+i]
local t=::manbow.Texture()
v.id<-1000*j+1000+i
v.texture<-t
if(j==0&&(::menu.character_select.t[0].cursor_master.val==i||::menu.character_select.t[1].cursor_master.val==i)){t.Load(v.texture_name)
callback.call(v)}
else{t.LoadBackground(v.texture_name,v,callback)}}}
this.parts<-[]
local mat=::manbow.Matrix()
local actor
actor=::manbow.AnimationController2D()
actor.Init(this.anime_set)
actor.SetMotion(0,0)
actor.ConnectRenderSlot(::graphics.slot.ui,0)
this.parts.push(actor)
for(local i=1;i<=4;i=++i){actor=::manbow.AnimationController2D()
actor.Init(this.anime_set)
actor.SetMotion(i,0)
actor.ConnectRenderSlot(::graphics.slot.ui,40000)
this.parts.push(actor)}
this.data<-[]
::manbow.CompileFile("data/system/select/script/animation_name.nut",this)
::manbow.CompileFile("data/system/select/script/animation_name_slave.nut",this)
::manbow.CompileFile("data/system/select/script/animation_handle.nut",this)
::manbow.CompileFile("data/system/select/script/animation_master.nut",this)
::manbow.CompileFile("data/system/select/script/animation_slave.nut",this)
::manbow.CompileFile("data/system/select/script/animation_spell.nut",this)
::manbow.CompileFile("data/system/select/script/animation_color.nut",this)
::manbow.CompileFile("data/system/select/script/animation_item.nut",this)
::manbow.CompileFile("data/system/select/script/animation_center.nut",this)
::manbow.CompileFile("data/system/select/script/animation_stage_center.nut",this)
::manbow.CompileFile("data/system/select/script/animation_stage_name.nut",this)
::manbow.CompileFile("data/system/select/script/animation_bgm.nut",this)
local v={}
v.action<-::menu.character_select.weakref()
actor=::manbow.AnimationController2D()
actor.Init(this.anime_set)
actor.SetMotion(40,0)
actor.alpha=0
actor.ConnectRenderSlot(::graphics.slot.ui,10000)
v.actor_character<-actor
actor=::manbow.AnimationController2D()
actor.Init(this.anime_set)
actor.SetMotion(41,0)
actor.alpha=0
actor.ConnectRenderSlot(::graphics.slot.ui,45000)
v.actor_stage<-actor
v.Update<-function(){if(this.action.Update==this.action.UpdateCharacterSelect){if(this.actor_stage.alpha>0){this.actor_stage.alpha-=0.10000000}}
else if(this.actor_stage.alpha<1){this.actor_stage.alpha+=0.10000000}
this.actor_character.alpha=1.00000000-this.actor_stage.alpha}
this.data.push(v)
local v={}
v.action<-::menu.character_select.weakref()
v.anime_set<-this.anime_set
v.device<-[null,null]
v.Update<-function(){foreach(i,v in this.action.device_id){if(this.device[i]){continue}
local s=0
if(v>=4){s=5}
else if(v>=-1){s=v+1}
else{continue}
local d=::manbow.AnimationController2D()
d.Init(this.anime_set)
d.SetMotion(800+i,s)
d.ConnectRenderSlot(::graphics.slot.ui,60000)
local mat=::manbow.Matrix()
mat.SetScaling(0.50000000,0.50000000,0.50000000)
mat.Translate(i==0?8:1280-8,8,0)
d.SetWorldTransform(mat)
this.device[i]=d}}
this.data.push(v)
if(::network.IsPlaying()){v={}
v.text<-::font.CreateSystemStringSmall("")
v.text.ConnectRenderSlot(::graphics.slot.ui,60000)
v.Update<-function(){local delay=::network.GetDelay()
::rollback.update_delay(delay)
this.text.Set("ping:"+delay)
this.text.x=::graphics.width-this.text.width-2
this.text.y=-4}
this.data.push(v)
for(local i=0;i<2;i=++i){v={}
v.icon<-::manbow.Sprite()
v.icon.Initialize(::menu.cursor.texture,160,i*32,32,32)
v.icon.ConnectRenderSlot(::graphics.slot.ui,40000)
v.icon.x=i==0?16:1280-16-32
v.icon.y=36
v.text<-::font.CreateSystemString(::network.player_name[i])
v.text.sx=v.text.sy=0.66000003
v.text.x=i==0?v.icon.x+32:v.icon.x-v.text.width*v.text.sx
v.text.y=v.icon.y+2
v.text.ConnectRenderSlot(::graphics.slot.ui,40000)
v.Update<-function(){}
this.data.push(v)}
if(::network.allow_watch&&!::network.is_parent_vs){local ip_str={}
if(!::setting.misc.hide_ip){ip_str.text<-::font.CreateSystemStringSmall(::punch.get_ip())
ip_str.text.x=10
ip_str.text.y=10
ip_str.text.sx=ip_str.text.sy=1.2
ip_str.text.ConnectRenderSlot(::graphics.slot.front,-1)}
ip_str.Update<-function(){if(::input_all.b2==1){::punch.copy_ip_to_clipboard()}
if(!::network.IsPlaying())this=null}
this.data.push(ip_str)
if(::menu.network.update_help_text){::menu.help.set(::menu.character_select.help_copy)}}}}
function Update(){foreach(v in this.data){v.Update()}}