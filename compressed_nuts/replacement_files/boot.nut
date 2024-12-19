function Initialize(){if(::setting.misc.skip_intro){::graphics.FadeIn(15)
::manbow.CompileFile("data/script/initialize.nut",this.getroottable())
::actor.Initialize()
::menu.title.Initialize()}else{local texture=::manbow.Texture()
texture.Load("data/system/boot/boot.png")
this.sprite<-::manbow.Sprite()
this.sprite.Initialize(texture,0,0,texture.width,texture.height)
this.sprite.ConnectRenderSlot(::graphics.slot.front,0)
this.count<-0
::graphics.FadeIn(15)
::loop.Begin(this)}}
function Terminate(){this.sprite=null}
function Update(){this.count++
if(this.count==15){local begin=::manbow.timeGetTime()
::manbow.CompileFile("data/script/initialize.nut",this.getroottable())
::actor.Initialize()
while(::manbow.timeGetTime()-begin<2000){this.Sleep(1)}
::loop.Fade(function(){::loop.End()
::menu.title.Initialize()})}}