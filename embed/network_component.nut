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
blacklist <- [];
function func_get_delay()
{
	return 0;
}

function Initialize()
{
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
	icon = [
		null,
		null
	];
	func_get_delay = function ()
	{
		return 0;
	};

	local_icon = ::manbow.Texture().GetBase64("profile.bmp", 32, 32);
	blacklist = ::split(::setting.network.blacklist, ",");
}

function Terminate()
{
	if (upnp_port > 0)
	{
		try
		{
			local ret = ::UPnP.DeletePort(upnp_port, "UDP");
		}
		catch( _e )
		{
		}

		upnp_port = 0;
	}

	inst = null;
	inst_connect = null;
	is_disconnect = true;
}

function IsActive()
{
	return inst != null;
}

// function IsPlaying()
// {
// 	if (inst == null)
// 	{
// 		return false;
// 	}

// 	if (is_watch)
// 	{
// 		return false;
// 	}

// 	return true;
// }

function IsPlaying() {
	return !(inst == null || is_watch);
}

function StartupServer(port,mode) {
	if (::config.network.upnp) {
		upnp_port = port;
		try {
			local ret = ::UPnP.AddPort(port, port, "UDP");
		} catch (e);
	} else upnp_port = 0;

	Initialize();
	local mb_server = ::manbow.NetworkServer();
	mb_server.ConnectRequest = function (id,context,table_in,table_out) {
		table_out.message <- "";
		//add connection request form

		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)::LOBBY.Close();

		if (!("version" in table_in) || table_in.version != GetVersion()) {
			table_out.message = "version";
			return false;
		}

		if (blacklist.find(table_in.address)) {
			table_out.message = "blocked";
			return false;
		}

		if ("is_watch" in table_in) {
			if (id > 0) {
				if (allow_watch) {
					table_out.is_parent_vs <- true;
					table_out.is_watch <- true;
					return true;
				}
				table_out.message = "watch";
				return false;
			}else {
				if (::config.network.allow_watch) {
					table_out.message = "ready";
					return false;
				}
				table_out.message = "watch";
				return false;
			}
		}

		if (id > 0) {
			table_out.message = "busy";
			return false;
		}

		if (inst) return false;

		inst = inst_connect;
		func_get_delay = function () {
			return::network.inst.GetChildDelay(0);
		};
		rand_seed = ::manbow.timeGetTime();
		srand(rand_seed);

		//local settings
		player_name[0] = ::config.network.player_name;
		player_name[1] = "P2";
		color_num[0] = ::savedata.GetColorNum();
		color_num[1] = ::savedata.GetColorNum();
		icon[0] = local_icon;
		icon[1] = null;

		//reply_table
		allow_watch = ::config.network.allow_watch && table_in.allow_watch;
		table_out.rand_seed <- rand_seed;
		table_out.is_parent_vs <- true;
		table_out.allow_watch <- allow_watch;
		table_out.hide_ip <- ::setting.network.hide_ip || !::setting.network.share_watch_ip;
		table_out.use_lobby <- use_lobby;
		::sound.PlaySE(120);
		::loop.Fade(function () {
			::discord.rpc_set_details("VS online");
			::menu.network.Suspend();
			local t = {
				message = "profile"
				name = ::network.player_name[0]
				color = ::network.color_num[0]
				icon = ::network.local_icon
			}
			for (local i = 0; i < ::network.client_num; ++i) ::network.inst.SendToChild(i, t);
			::menu.character_select.Initialize(1);
		});
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
						player_name[1] = table.name;
						color_num[1] = table.color;
						icon[1] = table.icon;
						break;
				}
			}
		} catch (e);
	}.bindenv(this);

	client_num = 2;
	inst_connect = mb_server;
	local ret = mb_server.Init(port, client_num);
	if (mode & 1 && ::LOBBY.GetNetworkState() == 2)::punch.init_wait();
	return ret;
}

// function StartupServer( port, mode )
// {
// 	if (::config.network.upnp)
// 	{
// 		upnp_port = port;

// 		try
// 		{
// 			local ret = ::UPnP.AddPort(port, port, "UDP");
// 		}
// 		catch( _e )
// 		{
// 		}
// 	}
// 	else
// 	{
// 		upnp_port = 0;
// 	}

// 	Initialize();
// 	local mb_server = ::manbow.NetworkServer();
// 	mb_server.ConnectRequest = function ( id, context, table_src, table_dst )
// 	{
// 		table_dst.message <- "";

// 		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)
// 		{
// 			::LOBBY.Close();
// 		}

// 		if (!("version" in table_src) || table_src.version != GetVersion())
// 		{
// 			table_dst.message = "version";
// 			return false;
// 		}

// 		if ("is_watch" in table_src)
// 		{
// 			if (id > 0)
// 			{
// 				if (allow_watch)
// 				{
// 					table_dst.is_parent_vs <- true;
// 					table_dst.is_watch <- true;
// 					return true;
// 				}

// 				table_dst.message = "watch";
// 				return false;
// 			}
// 			else
// 			{
// 				if (::config.network.allow_watch)
// 				{
// 					table_dst.message = "ready";
// 					return false;
// 				}

// 				table_dst.message = "watch";
// 				return false;
// 			}
// 		}

// 		if (id > 0)
// 		{
// 			table_dst.message = "busy";
// 			return false;
// 		}

// 		if (inst)
// 		{
// 			return false;
// 		}

// 		inst = inst_connect;
// 		func_get_delay = function ()
// 		{
// 			return ::network.inst.GetChildDelay(0);
// 		};
// 		rand_seed = ::manbow.timeGetTime();
// 		srand(rand_seed);
// 		player_name[0] = ::config.network.player_name;
// 		player_name[1] = table_src.name.len() > 16 ? "P2" : table_src.name;
// 		color_num[0] = ::savedata.GetColorNum();
// 		color_num[1] = table_src.color;
// 		icon[0] = local_icon;
// 		icon[1] = "icon" in table_src ? table_src.icon : null;
// 		allow_watch = ::config.network.allow_watch && table_src.allow_watch;
// 		table_dst.rand_seed <- rand_seed;
// 		table_dst.is_parent_vs <- true;
// 		table_dst.allow_watch <- allow_watch;
// 		table_dst.hide_ip <- ::setting.network.hide_ip || !::setting.network.share_watch_ip;
// 		table_dst.use_lobby <- use_lobby;
// 		table_dst.name <- ::config.network.player_name.len() > 16 ? "" : ::config.network.player_name;
// 		table_dst.color <- color_num[0];
// 		table_dst.icon <- icon[0];
// 		::sound.PlaySE(120);
// 		::loop.Fade(function ()
// 		{
// 			::discord.rpc_set_details("VS Online");
// 			::menu.network.Suspend();
// 			::menu.character_select.Initialize(1);
// 		});
// 		return true;
// 	}.bindenv(this);
// 	mb_server.DisconnectChild = function ( id )
// 	{
// 		if (id == 0)
// 		{
// 			Disconnect();
// 		}
// 	}.bindenv(this);
// 	mb_server.ReceiveFromChild = function ( id, table )
// 	{
// 	}.bindenv(this);
// 	client_num = 2;
// 	inst_connect = mb_server;
// 	local ret = mb_server.Init(port, client_num);
// 	if (mode & 1 && ::LOBBY.GetNetworkState() == 2) {
// 		::punch.init_wait();
// 	}
// 	return ret;
// }

function StartupClient(addr,port,mode) {
	Initialize();
	local mb_client = ::manbow.NetworkClient();
	client_num = 3;

	if (mode & 2 && ::LOBBY.GetNetworkState() == 2) {
		::punch.init_connect(addr, port);
	}
	if (!mb_client.Init(0,client_num)) {
		inst = null;
		mb_client = null;
		return false;
	}

	mb_client.ConnectRequest = function (id,context,table_in,table_out) {
		table_out.message <- "";

		if (!("version" in table_in) && table_in.version != ::GetVersion()) {
			table_out.message = "version";
			return false;
		}

		if (!("is_watch" in table_in)) {
			table_out.message = "busy";
			return false;
		}

		if (!::network.allow_watch) {
			table_out.message = "watch";
			return false;
		}

		if (::network.blacklist.find(table_in.address)) {
			table_out.message = "blocked";
			return false;
		}

		table_out.is_parent_vs <- ::network.is_parent_vs;
		table_out.is_watch <- true;
		return true;
	};

	mb_client.ConnectComplete = function (id,context,reply_table) {
		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED) {
			::LOBBY.Close();
		}

		if (inst) return;

		if ("is_watch" in reply_table) {
			allow_watch = true;
			is_parent_vs = reply_table.is_parent_vs;
			is_watch = true;
			inst = inst_connect;
			::sound.PlaySE(120);
			::loop.Fade(function() {
				::discord.rpc_set_details("Spectating");
				::menu.network.Suspend();
				::menu.watch.Initialize();
			});
			return;
		}

		inst = inst_connect;
		is_parent_vs = true;
		is_client = true;
		rand_seed = reply_table.rand_seed;
		srand(rand_seed);

		player_name[0] = "P1";
		player_name[1] = ::config.network.player_name;
		color_num[0] = ::savedata.GetColorNum();
		color_num[1] = ::savedata.GetColorNum();
		icon[0] = null;
		icon[1] = local_icon;

		allow_watch = reply_table.allow_watch;
		hide_host_ip = !("hide_ip" in reply_table) || reply_table.hide_ip;
		use_lobby = reply_table.use_lobby;

		funct_get_delay = function () {
			return ::network.inst.GetParentDelay();
		}
		::sound.PlaySE(120);
		::loop.Fade(function () {
			::discord.rpc_set_details("VS Online");
			::menu.network.Suspend();
			local t = {
				message = "profile"
				name = player_name[1]
				color = color_num[1]
				icon = local_icon
			}
			for (local i = 0; i < client_num; ++i) inst.SendtoChild(i, t);
			::menu.Character_select.Initialize(1);
		});
		return;
	}.bindenv(this);
	mb_client.ConnectReject = function (context,table) {
		if ("message" in table) {
			switch(table.message) {
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
			local t = {
				message = "end_vs"
			};
			for (local i = 0; i < client_num; ++i) {
				inst.SendToChild(i, t);
			}
			Disconnect();
			return;
		}
		if (is_watch && inst) {
			isnt.Reconnect();
		}
	}.bindenv(this);
	mb_client.ReceiveFromParent = function (table) {
		try {
			if ("message" in table) {
				switch(table.message) {
					case "end_vs":
						for (local i = 0; i < ::network_client_num; ++i) {
							::network_inst.SendToChild(i, table);
						}
						Disconnect();
						break;
					case "profile":
						player_name[1] = table.name;
						color_num[1] = table.color;
						icon[1] = table.icon;
						break;
				}
			}
		} catch (e);
	}.bindenv(this);

	local connect_param = {
		version = ::GetVersion()
		address = addr
		allow_watch = ::config.network.allow_watch
		battle_num = 1
	};

	if (mode & 1) {
		connect_param.is_watch <- false;
	}
	host_ip = addr+":"+port;
	inst_connect = mb_client;
	return mb_client.Connect(addr, port, connect_param);
}

// function StartupClient( addr, port, mode )
// {
// 	Initialize();
// 	local mb_client = ::manbow.NetworkClient();

// 	client_num = 3;

// 	if (mode & 2 && ::LOBBY.GetNetworkState() == 2) {
// 		::punch.init_connect(addr, port);
// 	}
// 	if (!mb_client.Init(0, client_num))
// 	{
// 		inst = null;
// 		mb_client = null;
// 		return false;
// 	}
// 	mb_client.ConnectRequest = function ( id, context, table_src, table_dst )
// 	{
// 		table_dst.message <- "";

// 		if (!("version" in table_src) && table_src.version != ::GetVersion())
// 		{
// 			table_dst.message = "version";
// 			return false;
// 		}

// 		if (!("is_watch" in table_src))
// 		{
// 			table_dst.message = "busy";
// 			return false;
// 		}

// 		if (!::network.allow_watch)
// 		{
// 			table_dst.message = "watch";
// 			return false;
// 		}

// 		table_dst.is_parent_vs <- ::network.is_parent_vs;
// 		table_dst.is_watch <- true;
// 		return true;
// 	};
// 	mb_client.ConnectComplete = function ( id, context, _reply_table )
// 	{
// 		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)
// 		{
// 			::LOBBY.Close();
// 		}

// 		if (inst)
// 		{
// 			return;
// 		}

// 		if ("is_watch" in _reply_table)
// 		{
// 			allow_watch = true;
// 			is_parent_vs = _reply_table.is_parent_vs;
// 			is_watch = true;
// 			inst = inst_connect;
// 			::sound.PlaySE(120);
// 			::loop.Fade(function ()
// 			{
// 				::discord.rpc_set_details("Spectating");
// 				::menu.network.Suspend();
// 				::menu.watch.Initialize();
// 			});
// 			return;
// 		}

// 		inst = inst_connect;
// 		is_parent_vs = true;
// 		is_client = true;
// 		rand_seed = _reply_table.rand_seed;
// 		srand(rand_seed);
// 		player_name[0] = _reply_table.name.len() > 16 ? "P1" : _reply_table.name;
// 		player_name[1] = ::config.network.player_name;
// 		color_num[0] = _reply_table.color;
// 		color_num[1] = ::savedata.GetColorNum();
// 		icon[0] = "icon" in _reply_table ? _reply_table.icon : null;
// 		icon[1] = local_icon;
// 		allow_watch = _reply_table.allow_watch;
// 		hide_host_ip = !("hide_ip" in _reply_table) || _reply_table.hide_ip;
// 		use_lobby = _reply_table.use_lobby;
// 		func_get_delay = function ()
// 		{
// 			return ::network.inst.GetParentDelay();
// 		};
// 		::sound.PlaySE(120);
// 		::loop.Fade(function ()
// 		{
// 			::discord.rpc_set_details("VS Online");
// 			::menu.network.Suspend();
// 			::menu.character_select.Initialize(1);
// 		});
// 		return;
// 	}.bindenv(this);
// 	mb_client.ConnectReject = function ( context, table )
// 	{
// 		if ("message" in table)
// 		{
// 			if (table.message == "busy")
// 			{
// 				return_code = 1;
// 			}

// 			if (table.message == "version")
// 			{
// 				return_code = 2;
// 			}

// 			if (table.message == "watch")
// 			{
// 				return_code = 3;
// 			}

// 			if (table.message == "ready")
// 			{
// 				return_code = 4;
// 			}
// 		}
// 	}.bindenv(this);
// 	mb_client.DisconnectParent = function ()
// 	{
// 		if (is_parent_vs)
// 		{
// 			local t = {};
// 			t.message <- "end_vs";

// 			for( local i = 0; i < client_num; i++ )
// 			{
// 				inst.SendToChild(i, t);
// 			}

// 			Disconnect();
// 			return;
// 		}

// 		if (is_watch && inst)
// 		{
// 			inst.Reconnect();
// 			return;
// 		}
// 	}.bindenv(this);
// 	mb_client.ReceiveFromParent = function ( table )
// 	{
// 		try
// 		{
// 			if ("message" in table)
// 			{
// 				if (table.message == "end_vs")
// 				{
// 					for( local i = 0; i < ::network_client_num; i++ )
// 					{
// 						::network_inst.SendToChild(i, table);
// 					}

// 					Disconnect();
// 					  // [027]  OP_POPTRAP        1      0    0    0
// 					return;
// 				}
// 			}
// 		}
// 		catch( _e )
// 		{
// 		}
// 	}.bindenv(this);
// 	local connect_param = {};
// 	connect_param.version <- ::GetVersion();
// 	connect_param.allow_watch <- ::config.network.allow_watch;
// 	connect_param.name <- ::config.network.player_name.len() > 16 ? "" : ::config.network.player_name;
// 	connect_param.color <- ::savedata.GetColorNum();
// 	connect_param.icon <- local_icon;
// 	connect_param.battle_num <- 1;

// 	if (mode & 1)
// 	{
// 		connect_param.is_watch <- false;
// 	}
// 	host_ip = addr + ":" + port;

// 	inst_connect = mb_client;
// 	return mb_client.Connect(addr, port, connect_param);
// }

function Disconnect( scene = true )
{
	if (is_disconnect)
	{
		return;
	}

	if (!::network.IsActive())
	{
		return;
	}

	is_disconnect = true;

	if (scene)
	{
		::loop.Fade(function ()
		{
			if (::network.IsActive())
			{
				::network.Terminate();
				::loop.End(::menu.network);
			}
		});
	}
	else
	{
		::network.Terminate();
	}

	return;
}

function GetDelay()
{
	return func_get_delay();
}

function BeginStreaming()
{
	inst.BeginStreaming();
}

function EndStreaming()
{
	inst.EndStreaming();
}

function BeginStreamingPlay( func_begin, func_end )
{
	inst.BeginStreamingPlay(func_begin, func_end);
}

function IsEnableStreamingBuffer()
{
	return inst.StreamingPlay();
}

function GetHostName( _str )
{
	local delimit_pos = _str.find(":");

	if (delimit_pos != null)
	{
		return _str.slice(0, delimit_pos);
	}

	return _str;
}

function GetHostPort( _str )
{
	local delimit_pos = _str.find(":");

	if (delimit_pos != null)
	{
		return _str.slice(delimit_pos + 1);
	}

	return null;
}

function GetIPAddress( text )
{
	local ex = regexp("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{1,5}");
	local ret = ex.search(text);

	if (ret == null)
	{
		return "";
	}

	return text.slice(ret.begin, ret.end);
}
