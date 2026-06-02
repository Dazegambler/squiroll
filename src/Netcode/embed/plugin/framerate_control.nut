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
        step = 2
        none = 3
        half = 4
        third = 5
        quarter = 6
        manual = 7
    }
    bind_controller = {
        step = -1
        none = -1
        half = -1
        third = -1
        quarter = -1
        manual = -1
    }
};
local bind_func = function(id,table,key,cfg_key) {
    return ::UI.Menu.Value(
        id,cfg_key,::plugin.cfg.framerate_control.data["bind_"+table][cfg_key],
        function () {
            local cfg = ::plugin.cfg.framerate_control;
            local page = ::menu.mod_config;
            local text = elem.val;
            page.Update = function() {
                if (::plugin.Input.Poll() >= 0)return;
                Update = function() {
                    local id = ::plugin.Input.Poll();
                    if (id >= 0) {
                        ::sound.PlaySE("sys_ok");
                        text.Set(id+"");
                        if ("framerate_control" in ::plugin.active_modifiers) {
                            ::plugin.active_modifiers.framerate_control.input.Bind(table,key,id); 
                        }
                        cfg.Set(id,cfg_key,"bind_"+table);
                        Update = UpdateMain;
                    }
                }
            }
        }
    );
};
::plugin.Patch("squiroll/config/mod_config.nut",function() {
    local cfg = ::plugin.cfg.framerate_control;
    page.extend([
        ::UI.Menu.Page(
            ::UI.Menu.Title("Framerate controls(1/2)"),
            ::UI.Menu.Header(0,"Binds(keyboard)"),
            bind_func(1,"keyboard","b0","step"),
            bind_func(2,"keyboard","b1","none"),
            bind_func(3,"keyboard","b2","half"),
            bind_func(4,"keyboard","b3","third"),
            bind_func(5,"keyboard","b4","quarter"),
            bind_func(6,"keyboard","b5","manual")
        ),
        ::UI.Menu.Page(
            ::UI.Menu.Title("Framerate controls(2/2)"),
            ::UI.Menu.Header(0,"Binds(controller)"),
            bind_func(1,"controller","b0","step"),
            bind_func(2,"controller","b1","none"),
            bind_func(3,"controller","b2","half"),
            bind_func(4,"controller","b3","third"),
            bind_func(5,"controller","b4","quarter"),
            bind_func(6,"controller","b5","manual")
        ) 
    ]);
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
            keyboard = ::plugin.Input.InputDevice({
                device = -1
                b0 = cfg.data.bind_keyboard.step
                b1 = cfg.data.bind_keyboard.none
                b2 = cfg.data.bind_keyboard.half
                b3 = cfg.data.bind_keyboard.third
                b4 = cfg.data.bind_keyboard.quarter
                b5 = cfg.data.bind_keyboard.manual
            })
            controller = ::plugin.Input.InputDevice({
                device = 0
                b0 = cfg.data.bind_controller.step
                b1 = cfg.data.bind_controller.none
                b2 = cfg.data.bind_controller.half
                b3 = cfg.data.bind_controller.third
                b4 = cfg.data.bind_controller.quarter
                b5 = cfg.data.bind_controller.manual
            })
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
