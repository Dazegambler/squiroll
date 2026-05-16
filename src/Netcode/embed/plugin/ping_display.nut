config = {
    enabled = true
    simple = false
    great_threshold = 60
    good_threshold = 130
    bad_threshold = 200
};

class modifier extends modifier {
	async = true;
	text = null;
	colors = [[1,0,0],[1,1,0],[0,1,0],[0,0,1]];
    constructor() {
		text = ::UI.core.Text("");
		text.ConnectRenderSlot(::graphics.slot.status,1);
	}

	function Update() {
		local delay = ::network.GetDelay();
		::rollback.update_delay(delay);
        local cfg = ::plugin.cfg.ping_display.data;
		local n = 3;
		if (delay > cfg.great_threshold)n--;
		if (delay > cfg.good_threshold)n--;
		if (delay > cfg.bad_threshold)n--;
		local str = "";
		if (!cfg.simple)str += "ping:" + delay;
		else {
			str += "[";
			local dash = 3 - n;
			for(local z = 0; z < n;++z)str += "/";
			for(local i = 0; i < dash;++i)str += "_";
			str += "]";
		}
    	str += " [" + ::rollback.get_buffered_frames() + "f]";
		if (::rollback.resyncing()) str += " (resyncing)";
		text.red = colors[n][0];
		text.green = colors[n][1];
		text.blue = colors[n][2];
		text.Set(str);
		text.x = 640 - ((text.width * text.sx) / 2);
		text.y = (705 - text.height);
	}

	function Enabled(param) {
		return (::network.IsPlaying() && ::plugin.cfg.ping_display.data.enabled);
	}
};
