class main extends ::battle.ModifierClass {
	text = null;
	colors = null;
	constructor() {
		colors = [[1,0,0],[1,1,0],[0,1,0],[0,0,1]];
		text = ::font.CreateSystemString("");
		text.ConnectRenderSlot(::graphics.slot.status,1);
	}

	function Update() {
		local delay = ::network.GetDelay();
		::rollback.update_delay(delay);
		local n = 3;
		if (delay > ::setting.ping.great_threshold)n--;
		if (delay > ::setting.ping.good_threshold)n--;
		if (delay > ::setting.ping.bad_threshold)n--;
		local str = "";
		if (!::setting.ping.simple)str += "ping:" + delay;
		else {
			str += "[";
			local dash = 3 - n;
			for(local z = 0; z < n;++z)str += "/";
			for(local i = 0; i < dash;++i)str += "_";
			str += "]";
		}
		if (::setting.ping.input_delay) str += " [" + ::rollback.get_buffered_frames() + "f]";
		if (::rollback.resyncing()) str += " (resyncing)";
		text.red = colors[n][0];
		text.green = colors[n][1];
		text.blue = colors[n][2];
		text.Set(str);
		text.x = ::setting.ping.x - ((text.width * text.sx) / 2);
		text.y = (::setting.ping.y - text.height);
	}
};
::battle.modifiers.ping_display <- ::battle.Modifier(main,true,function (param) {
	::setting.ping.update_consts();
	return (::network.IsPlaying() && ::setting.ping.enabled);
});
