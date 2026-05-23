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
    step_frame = false
    bind_step = 2
    bind_toggle = 3
    mode = 0
};
class modifier extends modifier {
	input = null;
    cfg = null;
    text = null;
    i = null;

    constructor() {
        cfg = ::plugin.cfg.framerate_control;
        
        text = ::UI.Core.Text("");
        text.ConnectRenderSlot(::graphics.slot.front,0);

        i = 0;
        
        input = ::manbow.InputSingle();
        local devmap = ::manbow.DeviceMapping();
        devmap.device = -1;
        devmap.b0 = cfg.data.bind_step;
        devmap.b1 = cfg.data.bind_toggle;
        input.SetDeviceAssign(devmap);
        ::input_all.Append(input);
	}

	function PreFrame() {
		if (input.b1 == 1)cfg.Set((cfg.data.mode + 1) % 5,"mode");
        
        i = (i + 1) % cfg.data.mode; 
        
        local b0 = input.b0;
		if (b0 && (!(b0 % 10) || b0 == 1)) {
			::sound.PlaySE("sys_ok");
			i = cfg.data.mode;
		} 
		
        text.Set(cfg.data.mode > 1 ? ::format("1/%s",cfg.data.mode+"") : "");

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
