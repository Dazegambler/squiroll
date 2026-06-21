// local test = ::font.CreateSystemString(" \f");
// ::print(format("width:%d\n",test.width - 12));
//'b' 19
//'B' 20
//'d' 19
//'D' 23
//'s' 16
//'S' 19
//'c' 17
//'C' 21
//'#' 23
//' ' 7
//'~' 14
//'/' 14
//'|-' 21
//'-' 13
//'_' 14
//'|' 8
//'[]' 28
//" []" 40
//" [" 26
//" " 12
// "   " 26
config = {
    bind_keyboard = {
        device = -1
        b0 = 2//step
        b1 = 3//none
        b2 = 4//half
        b3 = 5//third
        b4 = 6//quarter
        b5 = 7//manual
    }
    bind_controller = {
        device = 0
        b0 = -1//step
        b1 = -1//none
        b2 = -1//half
        b3 = -1//third
        b4 = -1//quarter
        b5 = -1//manual
    }
};


::plugin.Patch("squiroll/config/mod_config.nut",function() {
    //page.extend([
    //    ::UI.Menu.Page(
    //        ::UI.Menu.Title("Framerate controls(keyboard)"),
    //        ::UI.Menu.Config.Keybind(0,"step","framerate_control","keyboard","b0","b0",this),
    //        ::UI.Menu.Config.Keybind(1,"none","framerate_control","keyboard","b1","b1",this),
    //        ::UI.Menu.Config.Keybind(2,"half","framerate_control","keyboard","b2","b2",this),
    //        ::UI.Menu.Config.Keybind(3,"third","framerate_control","keyboard","b3","b3",this),
    //        ::UI.Menu.Config.Keybind(4,"quarter","framerate_control","keyboard","b4","b4",this),
    //        ::UI.Menu.Config.Keybind(5,"manual","framerate_control","keyboard","b5","b5",this)
    //    ),
    //    ::UI.Menu.Page(
    //        ::UI.Menu.Title("Framerate controls(controller)"),
    //        ::UI.Menu.Config.Keybind(0,"step","framerate_control","controller","b0","b0",this),
    //        ::UI.Menu.Config.Keybind(1,"none","framerate_control","controller","b1","b1",this),
    //        ::UI.Menu.Config.Keybind(2,"half","framerate_control","controller","b2","b2",this),
    //        ::UI.Menu.Config.Keybind(3,"third","framerate_control","controller","b3","b3",this),
    //        ::UI.Menu.Config.Keybind(4,"quarter","framerate_control","controller","b4","b4",this),
    //        ::UI.Menu.Config.Keybind(5,"manual","framerate_control","controller","b5","b5",this)
    //    )
    //]);
});

class modifier extends modifier {
	cfg = null;
    input = null;
    text = null;
    mode = null;
    i = null;

    constructor() {
        cfg = ::plugin.cfg.framerate_control;
        text = ::UI.Core.Text("");
        text.ConnectRenderSlot(::graphics.slot.front,0);

        i = 0;
        
        input = ::plugin.Input.InputManager({
            keyboard = ::plugin.Input.InputDevice(cfg.data.bind_keyboard)
            controller = ::plugin.Input.InputDevice(cfg.data.bind_controller)
        });
	}

	function PreFrame() {
        if(input.b1 == 1)mode = 0;//normal
        if(input.b5 == 1)mode = 1;//manual
		if(input.b2 == 1)mode = 2;//1/2
        if(input.b3 == 1)mode = 3;//1/3
        if(input.b4 == 1)mode = 4;//1/4

        i = (i + 1) % mode; 
        
        local b0 = input.b0;
        if (b0 && (!(b0 % 10) || b0 == 1)) {
            ::sound.PlaySE("sys_ok");
			i = mode;
		} 
		
        text.Set(mode > 1 ? ::format("1/%s",mode+"") : "");

        return !!i;
	}

    function Release() {
        text.Release();
        input.Release();   
    }

	function Enabled(param) {
		local enabled = (::network.IsPlaying != true);
		return enabled;
	}
};
