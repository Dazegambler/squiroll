function Initialize()
{
	Update = ::menu.network.dialog_wait.Update;
}

function InitializeWithUPnP()
{
	::menu.network.dialog_wait.Initialize.call(this);

	if (::config.network.upnp)
	{
		obj[1].y = -40;
		local action = ::menu.network;

		foreach( i, v in action.item_table.upnp_state )
		{
			local t = ::font.CreateSystemString(v);
			t.sx = t.sy = 0.66000003;
			t.y = 10;
			obj.append(t);
		}

		obj[2].x = -obj[2].width * obj[2].sx - 8;
		obj[3].green = 0;
		obj[3].blue = 0;
		obj[4].blue = 0;
		obj[5].red = 0;
		Update = ::menu.network.dialog_wait.Update2;
	}
}

function Update() {
	if (::punch.ip_available()) {
		::menu.network.update_help_text = true;
		if (::menu.network.display_ip_on_wait) {
			local str = "";
			switch (::LOBBY.GetLobbyUserState()) {
				case 200:
				case 100:
					str = ::menu.network.item_table.wait_incomming[0];
					break;
				case 102:
				case 202:
					str = "Match Found,Connecting...";
					break;
				default:
					str = ::menu.network.item_table.wait_incomming[0]+"("+::LOBBY.GetLobbyUserState()+")";
			}
			// local str = ::menu.network.item_table.wait_incomming[0];
			if (!::setting.network.hide_ip) {
				str = str + " " + ::punch.get_ip();
			}
			obj[1].Set(str);
			obj[1].x = 20 + -obj[1].width / 2;
		}
	}
	if (::network.received_request) {
		local request = ::network.received_request;
		local str = ::format("Match Found...%s#%dms", request.name, ::network.GetDelay());
		obj[1].Set(str);
		obj[1].x = 20 + -obj[1].width / 2;
	}
	::menu.cursor.SetTarget(obj[1].x - 20 + ::graphics.width / 2, obj[1].y + 24 + ::graphics.height / 2, 0.69999999);
	::menu.network.update();
}

function Update2()
{
	local upnp_state = ::UPnP.GetAsyncState();

	switch(::UPnP.GetAsyncState())
	{
	case 0:
		obj[3].visible = true;
		obj[4].visible = false;
		obj[5].visible = false;
		break;

	case 1:
		obj[3].visible = false;
		obj[4].visible = true;
		obj[5].visible = false;
		break;

	case 2:
		if (::UPnP.GetExternalIP() == "")
		{
			obj[3].visible = true;
			obj[4].visible = false;
			obj[5].visible = false;
		}
		else
		{
			obj[3].visible = false;
			obj[4].visible = false;
			obj[5].visible = true;
		}

		break;

	case 3:
		obj[3].visible = false;
		obj[4].visible = true;
		obj[5].visible = false;
		break;
	}

	::menu.network.dialog_wait.Update.call(this);
}
