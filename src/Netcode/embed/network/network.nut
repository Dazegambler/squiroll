::plugin.PatchCSV("data/system/network/item.csv",function(table) {table.setting <- ["setting"];});
dialog_wait <- {};
::manbow.CompileFile("data/system/network/dialog_wait.nut", dialog_wait);
dialog_address <- {};
::manbow.CompileFile("data/system/network/dialog_address.nut", dialog_address);
dialog_port <- {};
::manbow.CompileFile("data/system/network/dialog_port.nut", dialog_port);
dialog_connect <- {};
::manbow.CompileFile("data/system/network/dialog_connect.nut", dialog_connect);
anime <- {};
::manbow.CompileFile("data/system/network/network_animation.nut", anime);
help <- [
	"B1",
	"ok",
	null,
	"B2",
	"return",
	null,
	"UD",
	"select"
];
help_cancel <- [
	"B2",
	"cancel"
];
help_cancel_copy <- [
	"B2",
	"cancel",
	null,
	"B3",
	"copy_host"
];
help_port <- [
	"B1",
	"ok",
	null,
	"B2",
	"cancel",
	null,
	"UD",
	"val",
	null,
	"LR",
	"digit"
];
help_addr <- [
	"B1",
	"ok",
	"B2",
	"cancel",
	"B3",
	"clipboard",
	"UD",
	"val",
	"LR",
	"digit"
];
help_item <- [
	"B1",
	"ok",
	null,
	"B2",
	"cancel",
	null,
	"LR",
	"change"
];
help_prompt <- [
	"B1",
	"ok",
	null,
	"B2",
	"cancel",
];
item <- [
	"lobby_incomming",
	"lobby_match",
	"lobby_select",
	null,
	"server",
	"client",
	"watch",
	null,
	"player_name",
	"port",
	"upnp",
	"allow_watch",
	null,
	"exit"
];
room_name <- [
	"Free",
	"Novice",
	"Veteran",
	"EU",
	"NA",
	"SA",
	"Asia",
	"Dev"
];
room_title <- [
	"Free",
	"Novice",
	"Veteran",
	"EU",
	"NA",
	"SA",
	"Asia",
	"Secret Dev Lobby"
];
plugin <- {};
plugin.se_lobby <- ::libact.LoadPlugin("data/plugin/se_lobby.dll");
::LOBBY.SetMaxNickLength(32);
plugin.se_upnp <- ::libact.LoadPlugin("data/plugin/se_upnp.dll");
//plugin.se_infomation <- ::libact.LoadPlugin("data/plugin/se_information.dll");

display_ip_on_wait <- false;
update_help_text <- false;

retry_count <- 0;
lobby_user_state <- 0;
lobby_interval <- 10 * 1000;

function Initialize() {
	item_table <- ::menu.common.LoadItemTextArray("data/system/network/item.csv");
	::menu.cursor.Activate();
	::menu.back.Activate();
	update <- UpdateMain;
	state <- 0;
	
    is_suspend <- false;
	timeout <- 0;
	upnp_timeout <- 0;
	lobby_time_stamp <- ::manbow.timeGetTime() - 9000;
    
    ::LOBBY.SetPrefix(::network.lobby_prefix);
	::LOBBY.SetExternalPort(::config.network.hosting_port);
	::LOBBY.SetVersionSig(::network.lobby_version_sig);
	::LOBBY.SetStrikeFactor(1, 1000);

	cursor_item <- Cursor(0, item.len(), ::input_all);
    local skip = [];
    foreach( v in item )skip.push(v ? 0 : 1);
    cursor_item.SetSkip(skip);
    if (cursor_item.val != 0) {
		cursor_item.val = 0;
		cursor_item.diff = -1;
	}

    target_addr_v <- [];
    for( local i = 0; i < 17; ++i ) {
    	local c = Cursor(0, 10, ::input_all);
    	c.dir = -1;
    	c.enable_ok = false;
    	c.enable_cancel = false;
    	target_addr_v.push(c);
    }
    target_addr_h <- Cursor(1, 17, ::input_all);
    
    server_port_v <- [];
    for( local i = 0; i < 5; ++i ) {
    	local c = Cursor(0, 10, ::input_all);
    	c.dir = -1;
    	c.enable_ok = false;
    	c.enable_cancel = false;
    	server_port_v.push(c);
    }
    server_port_h <- Cursor(1, 5, ::input_all);
    cursor_upnp <- Cursor(1, 2, ::input_all);
    cursor_allow_watch <- Cursor(1, 2, ::input_all);

    cursor_lobby <- Cursor(1, room_name.len(), ::input_all);
	local n = ::config.network.lobby_name;
    ::config.network.lobby_name = room_name[0];
	cursor_lobby.val = 0;
	local i = room_name.find(n);
    if (i) {
        ::config.network.lobby_name = n;
        cursor_lobby.val = i;
    }

	SetHostingPortToCursor(::config.network.hosting_port);
	SetTargetHostToCursor(::config.network.target_host);
	SetTargetPortToCursor(::config.network.target_port);
	cursor_upnp.val = (!::config.network.upnp).tointeger();
	cursor_allow_watch.val = (!::config.network.allow_watch).tointeger();
	cursor_lobby.SetItemNum(room_name.len() - (!::debug.dev()).tointeger());
	BeginAnime();
	::loop.Begin(this);
}

function Terminate() {
	state = -1;
	::menu.help.Reset();
	::menu.back.Deactivate();
	::menu.cursor.Deactivate();
	EndAnimeDelayed();
	update = null;
	if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)::LOBBY.Close();
    ::network.Terminate();
}

function Suspend() {
	::loop.End(::menu.network);
	is_suspend = true;
	::menu.title.Hide();
	::menu.help.Reset();
	::menu.cursor.Deactivate();
	::menu.back.Deactivate(true);
	::effect.Clear();
	EndAnime();
}

function Resume() {
	if (!is_suspend)return;

	is_suspend = false;
	::sound.PlayBGM(::savedata.GetTitleBGMID());
	::menu.title.Show();

	if (::network.return_code == 0)::Dialog(0, ::menu.common.GetMessageText("disconnect"));

	::network.Terminate();
	update = UpdateMain;
	timeout = 0;
	upnp_timeout = 0;
	::menu.cursor.Activate();
	::menu.back.Activate();
	BeginAnime();
}

function LobbyUpdate() {
    local now = ::manbow.timeGetTime();
	if (now - lobby_time_stamp < lobby_interval)return;
	lobby_time_stamp = now;

	if (::config.network.lobby_name != "") {
		if (::LOBBY.GetNetworkState() == ::LOBBY.CLOSED)
			::LOBBY.Connect("", "", "", ::config.network.lobby_name, ::config.network.lobby_name);
	}else if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED) {
		::LOBBY.Close();
		lobby_time_stamp -= 9000;
	}
}

function Update() {
	if (::input_all.b10 == 1) {
		::sound.PlaySE("sys_cancel");
		::loop.End();
		return;
	}

    LobbyUpdate();	
    if (update)update();
}

function UpdateMain() {
	::discord.rpc_commit_details_and_state("Idle", "");

	::menu.help.Set(help);
	cursor_item.Update();
	::punch.ignore_ping();

	if (::input_all.b0 == 1) {
		::input_all.Lock();
		::network.local_device_id = ::input_all.GetLastDevice();

		switch(cursor_item.val) {
		case 0://wait in lobby
			if (::LOBBY.GetNetworkState() == 2) {
				::discord.rpc_commit_details_and_state("Waiting in " + room_title[cursor_lobby.val], "");

				::LOBBY.SetExternalPort(::config.network.hosting_port);
				::LOBBY.SetUserData("" + ::config.network.hosting_port);

				upnp_timeout = 0;
				if (!::config.network.upnp)::LOBBY.SetLobbyUserState(::LOBBY.WAIT_INCOMMING);

				lobby_user_state = ::LOBBY.WAIT_INCOMMING;
				::network.use_lobby = true;
				::network.StartupServer(::config.network.hosting_port, 0);
				::lobby.inc_user_count();
				update = UpdateMatch;
				display_ip_on_wait = false;
				update_help_text = false;
				::Dialog(-1, item_table.wait_incomming[0], null, dialog_wait.InitializeWithUPnP);
			}

			break;

		case 1://search in lobby
			if (::LOBBY.GetNetworkState() == 2) {
				::discord.rpc_commit_details_and_state("Searching in " + ::config.network.lobby_name, "");

				::LOBBY.SetExternalPort(::config.network.hosting_port);
				::LOBBY.SetUserData("" + ::config.network.hosting_port);
				::LOBBY.SetLobbyUserState(::LOBBY.MATCHING);
				lobby_user_state = ::LOBBY.MATCHING;
				update = UpdateMatch;
				display_ip_on_wait = false;
				update_help_text = true;
				::Dialog(-1, item_table.find[0], null, dialog_wait.Initialize);
			}

			break;

		case 2://select lobby
			update = UpdateSelectLobby;
			break;

		case 4://wait incomming
			::discord.rpc_commit_details_and_state("Waiting for connection", "");

			::network.use_lobby = false;
			::network.StartupServer(::config.network.hosting_port, 1);
			update = UpdateWaitServer;
			::punch.reset_ip();
			update_help_text = false;
			display_ip_on_wait = true;
			::Dialog(-1, item_table.wait_incomming[0], null, dialog_wait.InitializeWithUPnP);
			break;

		case 5://connecting to opponent
			target_addr_h.val = 0;
			::Dialog(-1, item_table.input_address[0], null, dialog_address.Initialize);
			break;

		case 6://watch
			target_addr_h.val = 0;
			::Dialog(-1, item_table.input_address[0], null, dialog_address.Initialize);
			break;

		case 8://network settings
			state = 1;
            ::menu.help.Reset();
			::menu.network_config.Initialize();
			break;
		case 9://player name
			::Dialog(2, ::menu.common.GetMessageText("input_name"), function ( ret ) {
				if (ret) {
					::config.network.player_name = ret;
					::config.Save();
				}
			}, ::config.network.player_name);
			break;

		case 10://port number
			SetHostingPortToCursor(::config.network.hosting_port);
			server_port_h.val = 0;
			::Dialog(-1, item_table.input_port[0], null, dialog_port.Initialize);
			break;

		case 11://use upnp
			update = UpdateUPnP;
			break;

		case 12://allow watch
			update = UpdateAllowWatch;
			break;

		case 14://exit
			::loop.End();
			break;
		}
	}else if (::input_all.b1 == 1)::loop.End();
}

function UpdateSelectLobby() {
	::menu.help.Set(help_item);
	cursor_lobby.Update();

	if (cursor_lobby.ok) {
		::config.network.lobby_name = room_name[cursor_lobby.val];
		::config.Save();
		lobby_time_stamp = ::manbow.timeGetTime() - 9000;
		::LOBBY.Close();
		update = UpdateMain;
	}

	if (cursor_lobby.cancel)update = UpdateMain;
}

function UpdateUPnP() {
	::menu.help.Set(help_item);
	cursor_upnp.Update();

	if (cursor_upnp.ok) {
		::config.network.upnp = cursor_upnp.val == 0 ? true : false;
		::config.Save();
		update = UpdateMain;
	}

	if (cursor_upnp.cancel)update = UpdateMain;
}

function UpdateAllowWatch() {
	::menu.help.Set(help_item);
	cursor_allow_watch.Update();

	if (cursor_allow_watch.ok) {
		::config.network.allow_watch = cursor_allow_watch.val == 0 ? true : false;
		::config.Save();
		update = UpdateMain;
	}

	if (cursor_allow_watch.cancel)update = UpdateMain;
}

function UpdateInputPort() {
	::menu.help.Set(help_port);
	server_port_h.Update();
	server_port_v[server_port_h.val].Update();

	if (::input_all.b0 == 1) {
		local port = 0;
		for( local i = 0; i < 5; ++i ) {
			port *= 10;
			port += server_port_v[i].val;
		}

		::config.network.hosting_port = port;
		::config.Save();
		::loop.End();
	}else if (::input_all.b1 == 1)::loop.End();
}

function UpdateWaitServer() {
	if (::network.received_request)::network.AcceptMatch();
	if (::input_all.b1 == 1) {
		::network.Terminate();
		update = UpdateMain;
		::loop.End();
	}
	if (::input_all.b2 == 1)::punch.copy_ip_to_clipboard();
	::menu.help.Set(update_help_text ? help_cancel_copy : help_cancel);
}

function UpdateInputAddr() {
	::menu.help.Set(help_addr);
	target_addr_h.Update();
	target_addr_v[target_addr_h.val].Update();

	if (::input_all.b0 == 1) {
        local addr = ::format(
            "%d.%d.%d.%d"
            , target_addr_v[0] * 100 + target_addr_v[1] * 10 + target_addr_v[2]
            , target_addr_v[3] * 100 + target_addr_v[4] * 10 + target_addr_v[5]
            , target_addr_v[6] * 100 + target_addr_v[7] * 10 + target_addr_v[8]
            , target_addr_v[9] * 100 + target_addr_v[10] * 10 + target_addr_v[11]
        );
       	local port = 0;
		for( local i = 12; i < 12 + 5; ++i ) {
			port = port * 10;
			port = port + target_addr_v[i].val;
		}

		::network.StartupClient(addr, port, item[cursor_item.val] == "watch" ? 3 : 2);
		update = UpdateWaitClient;
		::config.network.target_host = addr;
		::config.network.target_port = port;
		::config.Save();
		::loop.End();
		::Dialog(-1, item_table[item[cursor_item.val] == "watch" ? "connect_watch" : "connect"][0], null, dialog_connect.Initialize);
	}else if (::input_all.b1 == 1) {
		::network.Terminate();
		::loop.End();
	}

	if (::input_all.b2 == 1) {
		local ret = GetIPAddress(::manbow.GetClipboardString());
		if (ret != "") {
			SetTargetHostToCursor(GetHostName(ret));
			SetTargetPortToCursor(GetHostPort(ret).tointeger());
		}
	}
}

function UpdateWaitClient() {
	::menu.help.Set(help_cancel);
	if (::input_all.b1 == 1) {
		::network.Terminate();
		update = UpdateMain;
		::loop.End();
		::Dialog(-1, item_table.input_address[0], null, dialog_address.Initialize);
	}
    
    local ret = ::network.return_code;
    if (ret) {
        update = UpdateMain;
        ::loop.End();
        local str = "";
        switch (ret) {
            case 1:
                str = ::menu.common.GetMessageText("error_busy");
                break;
            case 2:
                str = ::menu.common.GetMessageText("error_version");
                break;
            case 3:
                str = ::menu.common.GetMessageText("error_watch");
                break;
            case 4:
                str = ::menu.common.GetMessageText("error_ready");
                break;
            case 5:
                str = "user has blocked you";
                break;
        }
        ::Dialog(0, str);
        ::network.Terminate();
    }
}

function UpdatePrompt() {
    timeout++;
    ::menu.help.Set(help_prompt);
    if (::setting.network.auto_accept || ::input_all.b0 == 1)::network.AcceptMatch();
    if (::input_all.b1 == 1) {
        ::network.RejectMatch();
        update = UpdateMatch;
    }
}

function UpdateMatch() {
	::menu.help.Set(help_cancel);

	if (::network.received_request) {
        update = UpdatePrompt;
        return;
    }
	if (::input_all.b1 == 1) {
		if (cursor_item.val == 0)::lobby.dec_user_count();
		::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION);
		::network.Terminate();
		::loop.End();
		update = UpdateMain;
		return;
	}
	
    if (::config.network.upnp &&
        ::LOBBY.GetLobby.UserState() == ::LOBBY.NO_OPERATION &&
        (::UPnP.GetAsyncState() == 2 || upnp_timeout++ > 360)
    ) {
        ::LOBBY.SetLobbyUserState(::LOBBY.WAIT_INCOMMING);
    }

    if (::netplay.IsConnecting() == 2)return;
    else ::netplay.timeout = 0;
	
	//client only
	local st_host = ::LOBBY.GetMatchHost();
    if (st_host != "") {
		::print(st_host+"\n");
        ::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION);
		::network.Terminate();
	    local st_userdata = ::LOBBY.GetMatchUserData();
        ::network.StartupClient(GetHostName(st_host), st_userdata.tointeger(), 0);
		update = UpdateMatchWait;
		return;
	}
}

//client only
function UpdateMatchWait() {
	::menu.help.Set(help_cancel);

	if (::input_all.b1 == 1) {
		if (cursor_item.val == 0)::lobby.dec_user_count();//should never trigger
		if (::network.received_request)::network.CancelRequest();
	    else {	
            ::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION);
		    ::network.Terminate();
		    ::loop.End();
		}
        update = UpdateMain;
		return;
	}

    if (::network.received_request) {
	    if (::netplay.IsHostAfk())update = UpdateMatch;
    }else {
        //unsure if needed
        if (timeout++ > 360) {
            ::print("failed to match start\n");
            ::LOBBY.SetLobbyUserState(lobby_user_state);
            ::network.Terminate();
            timeout = 0;
            update = UpdateMatch;
        }
    }
}

function SetTargetHostToCursor( t ) {
	for( local i = 0; i < 4; i = ++i ) {
		local val = 0;
		local d = t.find(".");

		if (d) {
			val = t.slice(0, d).tointeger();
			t = t.slice(d + 1);
		}else val = t.tointeger();

		target_addr_v[i * 3 + 2].val = val % 10;
		val /= 10;
		target_addr_v[i * 3 + 1].val = val % 10;
		val /= 10;
		target_addr_v[i * 3].val = val;
	}
}

function SetHostingPortToCursor( t ) {
	local t = ::config.network.hosting_port;
	for( local i = 4; i >= 0; i = --i ) {
		server_port_v[i].val = t % 10;
		t /= 10;
	}
}

function SetTargetPortToCursor( t ) {
	for( local i = 4; i >= 0; --i ) {
		target_addr_v[12 + i].val = t % 10;
		t /= 10;
	}
}

function GetHostName( _str ) {
	local delimit_pos = _str.find(":");
    if (!delimit_pos)return _str;
	return _str.slice(0,delimit_pos);
}

function GetHostPort( _str ) {
	local delimit_pos = _str.find(":");
    if(!delimit_pos)return null;
	return _str.slice(delimit_pos+1);
}

function GetIPAddress( text ) {
	local ex = regexp("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{1,5}");
	local ret = ex.search(text);
    if(!ret)return "";
	return text.slice(ret.begin, ret.end);
}

