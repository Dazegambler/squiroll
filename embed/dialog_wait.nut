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

		//Match Accepted
		if (::input_all.b0) {
			::network.player_name = [::config.network.player_name, request.name.len() > 16 ? "P2" : request.name];
			::network.color_num = [::savedata.GetColorNum(), request.color];
			::network.icon = [::network.local_icon, ""];
			::network.rand_seed = ::manbow.timeGetTime();
			srand(::network.rand_seed);
			::network.allow_watch = ::config.network.allow_watch && request.allow_watch;
			::network.received_request = null;
			::sound.PlaySE(120);
			::loop.Fade(function () {
				::network.inst.SendToChild(0, {
					message = "yes"
					rand_seed = ::network.rand_seed
					is_parent_vs = true
					allow_watch = ::network.allow_watch
					hide_ip = ::setting.network.hide_ip || !::setting.network.share_watch_ip
					use_lobby = ::network.use_lobby
					name = ::config.network.player_name.len() > 16 ? "P1" : ::config.network.player_name
					color = ::network.color_num[0]
				});
				foreach(chunk in ::network.chunked_icon) {
					::network.inst.SendToChild(0, {
						message = "profile"
						icon_chunk = chunk
					});
				}
				::discord.rpc_set_details("VS online");
				::menu.network.Suspend();
				::menu.character_select.Initialize(1);
			})
		}

		//Match Rejected
		if (::input_all.b1) {
			::network.inst.SendToChild(0, {
				message = "no"
			});
			::network.Disconnect();
			::loop.End();
		}
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
