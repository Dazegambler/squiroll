lobby_prefix <- "th155_";
lobby_version_sig <- GetVersionSignature();
lobby_name <- "Free";
inst <- null;
inst_connect <- null;
return_code <- -1;
client_num <- 0;
is_client <- false;
is_parent_vs <- false;
allow_watch <- false;
is_watch <- false;
hide_host_ip <- true;
host_ip <- "";
is_disconnect <- false;
use_lobby <- false;
upnp_port <- 0;
local_device_id <- 0;
input_local <- null;
rand_seed <- 0;
server_profile <- null;
client_profile <- null;
history <- [];
history_load_count <- 0;
hidden_char <- 0;
use_matching <- false;
numbattle <- 1;
frame_score <- 0;
frame_count <- 0;
player_name <- [
	"",
	""
];
color_num <- [
	8,
	8
];
icon <- [
	null,
	null
];
local_icon <- "";
received_request <- null;
ready <- false;

function Initialize() {
    ready = false;
	inst = null;
	inst_connect = null;
	return_code = -1;
	input_local = null;
	is_client = false;
	is_parent_vs = false;
	is_watch = false;
	hide_host_ip = true;
	host_ip = "";
	allow_watch = false;
	is_disconnect = false;
	client_num = 0;
	received_request = null;
	icon = ["",""];
	func_get_delay <- @()0;
	
    local_icon = ::manbow.Texture().GetBase64("profile.bmp", 32, 32);
    chunked_icon <- [];
    local div = 3;
    local chunk_size = local_icon.len() / div;
    for (local i = 0; i < div; ++i) {
        chunked_icon.push(local_icon.slice(0 + (chunk_size * i), chunk_size * (i + 1)));
    }
}

function Terminate() {
	::menu.network.timeout = 0;
	received_request = null;
	if (upnp_port > 0) {
		try ::UPnP.DeletePort(upnp_port, "UDP")
		catch(_e);
		upnp_port = 0;
	}

	inst = null;
	inst_connect = null;
	is_disconnect = true;
}


function StartupServer(port,mode) {
	if (::config.network.upnp) {
		upnp_port = port;
		try local ret = ::UPnP.AddPort(port, port, "UDP")
		catch (e);
	}else upnp_port = 0;

	Initialize();
	local mb_server = ::manbow.NetworkServer();
	mb_server.ConnectRequest = function (id,context,request,reply) {
		reply.message <- "";
		//||||||||||||||||||||||||||||
		//||Match Rejection Handling||
		//||||||||||||||||||||||||||||

		//version mismatch
		if (!("version" in request) || request.version != GetVersion()) {
			reply.message = "version";
			return false;
		}
		if ("is_watch" in request) {
			if (id > 0) {
				//spectator accepted
				if (allow_watch) {
					reply.is_parent_vs <- true;
					reply.is_watch <- true;
					return true;
				}
				//spectate disabled
				reply.message = "watch";
				return false;
			}else {
				//match not started
				if (::config.network.allow_watch) {
					reply.message = "ready";
					return false;
				}
				//spectate disabled
				reply.message = "watch";
				return false;
			}
		}
		//matched already
		if (id > 0) {
			reply.message = "busy";
			return false;
		}

		//match singleton check
		if (inst) return false;

		//||||||||||||||||||||||||
		//||Match Request Prompt||
		//||||||||||||||||||||||||
		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)::LOBBY.Close();
		inst = inst_connect;
		func_get_delay = @()::network.inst.GetChildDelay(0);
		::sound.PlaySE(120);
		received_request = {
			name = request.name
			color = request.color
			allow_watch = request.allow_watch
		};
		reply.name <- ::config.network.player_name;
		return true;
	}.bindenv(this);

	mb_server.DisconnectChild = function (id) {
		if (id == 0) Disconnect();
	}.bindenv(this);

	mb_server.ReceiveFromChild = function (id,table) {
		try {
			if ("message" in table) {
				switch(table.message) {
					case "profile":
						::print("p2 profile chunk\n");
						icon[1] += table.icon_chunk;
						break;
					case "nvm":
						Terminate();
						::menu.network.update = ::menu.network.UpdateMatch;
						::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
						::menu.network.lobby_user_state = ::LOBBY.WAIT_INCOMMING;
						::LOBBY.SetLobbyUserState(::menu.network.lobby_user_state);
						::network.StartupServer(::config.network.hosting_port, 0);
						break;
					case "afk":
						Terminate();
						::menu.network.update = ::menu.network.UpdateMain;
						::loop.End();
						break;
				}
			}
		} catch (e);
	}.bindenv(this);

	client_num = 2;
	inst_connect = mb_server;
	local ret = mb_server.Init(port,client_num);
	if (mode & 1 && ::LOBBY.GetNetworkState() == 2)::punch.init_wait();
	return ret;
}

function StartupClient(addr,port,mode) {
	Initialize();
	local mb_client = ::manbow.NetworkClient();
	client_num = 3;

	if (mode & 2 && ::LOBBY.GetNetworkState() == 2)::punch.init_connect(addr, port);
	if (!mb_client.Init(0,client_num)) {
		inst = null;
		mb_client = null;
		return false;
	}

	mb_client.ConnectRequest = function (id,context,request,reply) {
		reply.message = "";

		//||||||||||||||||||||||||||||
		//||Match Rejection Handling||
		//||||||||||||||||||||||||||||

		//mismatched versions
		if (!("version" in request) && request.version != ::GetVersion()) {
			reply.message = "version";
			return false;
		}

		//spectate not allowed
		if (!("is_watch" in request)) {
			reply.message = "busy";
			return false;
		}

		//spectate not allowed
		if (!::network.allow_watch) {
			reply.message = "watch";
			return false;
		}

	    reply.is_parent_vs <- ::network.is_parent_vs;
		reply.is_watch <- true;
		return true;
	}


	mb_client.ConnectComplete = function (id,context,reply) {
		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)::LOBBY.Close();
		if (inst) return;
		if ("is_watch" in reply) {
			allow_watch = true;
			is_parent_vs = reply.is_parent_vs;
			is_watch = true;
			inst = inst_connect;
			::sound.PlaySE(120);
			::loop.Fade(function () {
				::discord.rpc_set_details("Spectating");
				::menu.network.Suspend();
				::menu.watch.Initialize();
			});
			return;
		}
		inst = inst_connect;
		func_get_delay = @()::network.inst.GetParentDelay();
		received_request = {name = reply.name};
		return;
	}.bindenv(this);
	mb_client.ConnectReject = function (context,table) {
		if ("message" in table) {
			switch (table.message) {
				case "busy":
					return_code = 1;
					break;
				case "version":
					return_code = 2;
					break;
				case "watch":
					return_code = 3;
					break;
				case "ready":
					return_code = 4;
					break;
				case "blocked":
					return_code = 5;
					break;
			}
		}
	}.bindenv(this);
	mb_client.DisconnectParent = function () {
		if (is_parent_vs) {
			local t = {message = "end_vs"};
			for (local i = 0; i < client_num; ++i) {
				inst.SendToChild(i, t);
			}
			Disconnect();
			return;
		}
		if (is_watch && inst)inst.Reconnect();
	}.bindenv(this);
	mb_client.ReceiveFromParent = function (table) {
		try{
			if ("message" in table) {
				switch (table.message) {
					case "end_vs":
						for (local i = 0; i < ::network_client_num; ++i) {
							::network_inst.SendToChild(i, table);
						}
						Disconnect();
						break;
					case "profile":
						::print("p1 profile image chunk\n");
						icon[0] += table.icon_chunk;
						break;
					case "yes":
						BeginMatch(table);
						break;
					case "no":
						Terminate();
						::menu.network.update = ::menu.network.UpdateMatch;
						::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
						::menu.network.lobby_user_state = ::LOBBY.MATCHING;
						::LOBBY.SetLobbyUserState(::menu.network.lobby_user_state);
						// ::loop.End();
						break;
				}
			}
		} catch (e);
	}.bindenv(this);

	local connect_param = {
		version = ::GetVersion()
		allow_watch = ::config.network.allow_watch
		battle_num = 1
		name = ::config.network.player_name.len() > 16 ? "P2" : ::config.network.player_name
		color = ::savedata.GetColorNum()
	};

	if (mode & 1)connect_param.is_watch <- false;

	host_ip = addr+":"+port;
	inst_connect = mb_client;
	return mb_client.Connect(addr, port, connect_param);
}

function Disconnect( scene = true ) {
	if (is_disconnect || !IsActive())return;
	is_disconnect = true;

	if (scene) {
		::loop.Fade(function () {
			if (::network.IsActive()) {
				::network.Terminate();
				::loop.End(::menu.network);
			}
		});
	}else::network.Terminate();
}


function BeginMatch(table) {
	received_request = null;
	ready = true;
	is_parent_vs = true;
	is_client = true;
	rand_seed = table.rand_seed;
	srand(rand_seed);

	player_name = [table.name.len() > 16 ? "P1" : table.name,::config.network.player_name];
	color_num = [table.color, ::savedata.GetColorNum()];
	icon = ["", local_icon];

	allow_watch = table.allow_watch;
	hide_host_ip = !("hide_ip" in table) || table.hide_ip;
	use_lobby = table.use_lobby;

	// func_get_delay = function () {
	// 	return::network.inst.GetParentDelay();
	// }
	::sound.PlaySE(120);
	::loop.Fade(function () {
        foreach (chunk in ::network.chunked_icon) {
		    ::network.inst.SendToParent({
			    message = "profile"
			    icon_chunk = chunk
		    });
        }
		::discord.rpc_set_details("VS Online");
		::menu.network.Suspend();
		::menu.character_select.Initialize(1);
	});
}

function CancelRequest() {
	inst.SendToParent({message = "nvm"});
	Terminate();
	::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
	::menu.network.lobby_user_state = ::LOBBY.NO_OPERATION;
	::LOBBY.SetLobbyUserState(::menu.network.lobby_user_state);
	::loop.End();
}

function HostAFK() {
	inst.SendToParent({message = "afk"});
	Terminate();
}

function AcceptMatch() {
	ready = true;
	player_name = [::config.network.player_name, received_request.name.len() > 16 ? "P2" : received_request.name];
	color_num = [::savedata.GetColorNum(), received_request.color];
	icon = [local_icon, ""];
	rand_seed = ::manbow.timeGetTime();
	srand(rand_seed);
	allow_watch = ::config.network.allow_watch && received_request.allow_watch;
	received_request = null;
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
		foreach (chunk in ::network.chunked_icon) {
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

function RejectMatch() {
	::network.inst.SendToChild(0, {message = "no"});
	Terminate();
	::LOBBY.Connect("", "", "", ::config.network.lobby_name, ::config.network.lobby_name);
	::menu.network.lobby_user_state = ::LOBBY.WAIT_INCOMMING;
	::LOBBY.SetLobbyUserState(::menu.network.lobby_user_state);
	StartupServer(::config.network.hosting_port, 0);
}

IsActive <- @()inst != null;
IsPlaying <- @()inst && !is_watch;
IsEnableStreamingBuffer <- @()inst.StreamingPlay();
GetDelay <- @()func_get_delay();

function BeginStreaming() {
	inst.BeginStreaming();
}

function EndStreaming() {
	inst.EndStreaming();
}

function BeginStreamingPlay( func_begin, func_end ) {
	inst.BeginStreamingPlay(func_begin, func_end);
}

function GetHostName( _str ) {
	local delimit_pos = _str.find(":");

    if (!delimit_pos)return _str;
	return _str.slice(0, delimit_pos);
}

function GetHostPort( _str ) {
	local delimit_pos = _str.find(":");

    if (!delimit_pos)return null;
	return _str.slice(delimit_pos+1);
}

function GetIPAddress( text ) {
	local ex = regexp("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{1,5}");
	local ret = ex.search(text);

    if (!ret)return "";
	return text.slice(ret.begin, ret.end);
}
