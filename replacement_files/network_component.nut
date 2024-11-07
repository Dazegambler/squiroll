this.lobby_prefix <- "th155_";
this.lobby_version_sig <- this.GetVersionSignature();
this.lobby_name <- "Free";
this.inst <- null;
this.inst_connect <- null;
this.return_code <- -1;
this.client_num <- 0;
this.is_client <- false;
this.is_parent_vs <- false;
this.allow_watch <- false;
this.is_watch <- false;
this.is_disconnect <- false;
this.use_lobby <- false;
this.upnp_port <- 0;
this.local_device_id <- 0;
this.input_local <- null;
this.rand_seed <- 0;
this.server_profile <- null;
this.client_profile <- null;
this.history <- [];
this.history_load_count <- 0;
this.hidden_char <- 0;
this.use_matching <- false;
this.numbattle <- 1;
this.frame_score <- 0;
this.frame_count <- 0;
this.player_name <- [
	"",
	""
];
this.color_num <- [
	8,
	8
];
this.icon <- [
	null,
	null
];
function func_get_delay()
{
	return 0;
}

function Initialize()
{
	this.inst = null;
	this.inst_connect = null;
	this.return_code = -1;
	this.input_local = null;
	this.is_client = false;
	this.is_parent_vs = false;
	this.is_watch = false;
	this.allow_watch = false;
	this.is_disconnect = false;
	this.client_num = 0;
	this.icon = [
		null,
		null
	];
	this.func_get_delay = function ()
	{
		return 0;
	};
}

function Terminate()
{
	if (this.upnp_port > 0)
	{
		try
		{
			local ret = ::UPnP.DeletePort(this.upnp_port, "UDP");
		}
		catch( _e )
		{
		}

		this.upnp_port = 0;
	}

	this.inst = null;
	this.inst_connect = null;
	this.is_disconnect = true;
}

function IsActive()
{
	return this.inst != null;
}

function IsPlaying()
{
	if (this.inst == null)
	{
		return false;
	}

	if (this.is_watch)
	{
		return false;
	}

	return true;
}

function StartupServer( port, mode )
{
	if (::config.network.upnp)
	{
		this.upnp_port = port;

		try
		{
			local ret = ::UPnP.AddPort(port, port, "UDP");
		}
		catch( _e )
		{
		}
	}
	else
	{
		this.upnp_port = 0;
	}

	this.Initialize();
	local mb_server = ::manbow.NetworkServer();
	mb_server.ConnectRequest = function ( id, context, table_src, table_dst )
	{
		table_dst.message <- "";

		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)
		{
			::LOBBY.Close();
		}

		if (!("version" in table_src) || table_src.version != this.GetVersion())
		{
			table_dst.message = "version";
			return false;
		}

		if ("is_watch" in table_src)
		{
			if (id > 0)
			{
				if (this.allow_watch)
				{
					table_dst.is_parent_vs <- true;
					table_dst.is_watch <- true;
					return true;
				}

				table_dst.message = "watch";
				return false;
			}
			else
			{
				if (::config.network.allow_watch)
				{
					table_dst.message = "ready";
					return false;
				}

				table_dst.message = "watch";
				return false;
			}
		}

		if (id > 0)
		{
			table_dst.message = "busy";
			return false;
		}

		if (this.inst)
		{
			return false;
		}

		this.inst = this.inst_connect;
		this.func_get_delay = function ()
		{
			return ::network.inst.GetChildDelay(0);
		};
		this.rand_seed = ::manbow.timeGetTime();
		this.srand(this.rand_seed);
		this.player_name[0] = ::config.network.player_name;
		this.player_name[1] = table_src.name.len() > 16 ? "" : table_src.name;
		this.color_num[0] = ::savedata.GetColorNum();
		this.color_num[1] = table_src.color;
		this.icon[1] = "icon" in table_src ? table_src.icon : null;
		this.allow_watch = ::config.network.allow_watch && table_src.allow_watch;
		table_dst.rand_seed <- this.rand_seed;
		table_dst.is_parent_vs <- true;
		table_dst.allow_watch <- this.allow_watch;
		table_dst.use_lobby <- this.use_lobby;
		table_dst.name <- ::config.network.player_name.len() > 16 ? "" : ::config.network.player_name;
		table_dst.color <- this.color_num[0];
		table_dst.icon <- this.icon[0];
		::sound.PlaySE(120);
		::loop.Fade(function ()
		{
			::menu.network.Suspend();
			::menu.character_select.Initialize(1);
		});
		return true;
	}.bindenv(this);
	mb_server.DisconnectChild = function ( id )
	{
		if (id == 0)
		{
			this.Disconnect();
		}
	}.bindenv(this);
	mb_server.ReceiveFromChild = function ( id, table )
	{
	}.bindenv(this);
	this.client_num = 2;
	this.inst_connect = mb_server;
	::debug.print("mb_server.Init("+port+","+this.client_num+") begin\n");
	::debug.fprint("network.log","mb_server.Init("+port+","+this.client_num+") begin\n");
	local ret = mb_server.Init(port, this.client_num);
	::debug.print("mb_server.Init end\n");
	::debug.fprint("network.log","mb_server.Init end\n");
	if (mode & 1) {
		::punch.init_wait();
	}
	return ret;
}

function StartupClient( addr, port, mode )
{
	this.Initialize();
	local mb_client = ::manbow.NetworkClient();

	this.client_num = 3;

	if (!mb_client.Init(0, this.client_num))
	{
		this.inst = null;
		mb_client = null;
		return false;
	}
	mb_client.ConnectRequest = function ( id, context, table_src, table_dst )
	{
		table_dst.message <- "";

		if (!("version" in table_src) && table_src.version != ::GetVersion())
		{
			table_dst.message = "version";
			return false;
		}

		if (!("is_watch" in table_src))
		{
			table_dst.message = "busy";
			return false;
		}

		if (!::network.allow_watch)
		{
			table_dst.message = "watch";
			return false;
		}

		table_dst.is_parent_vs <- ::network.is_parent_vs;
		table_dst.is_watch <- true;
		return true;
	};
	mb_client.ConnectComplete = function ( id, context, _reply_table )
	{
		if (::LOBBY.GetNetworkState() != ::LOBBY.CLOSED)
		{
			::LOBBY.Close();
		}

		if (this.inst)
		{
			return;
		}

		if ("is_watch" in _reply_table)
		{
			this.allow_watch = true;
			this.is_parent_vs = _reply_table.is_parent_vs;
			this.is_watch = true;
			this.inst = this.inst_connect;
			::sound.PlaySE(120);
			::loop.Fade(function ()
			{
				::menu.network.Suspend();
				::menu.watch.Initialize();
			});
			return;
		}

		this.inst = this.inst_connect;
		this.is_parent_vs = true;
		this.is_client = true;
		this.rand_seed = _reply_table.rand_seed;
		this.srand(this.rand_seed);
		this.player_name[0] = _reply_table.name.len() > 16 ? "" : _reply_table.name;
		this.player_name[1] = ::config.network.player_name;
		this.color_num[0] = _reply_table.color;
		this.color_num[1] = ::savedata.GetColorNum();
		this.icon[0] = "icon" in _reply_table ? _reply_table.icon : null;
		this.allow_watch = _reply_table.allow_watch;
		this.use_lobby = _reply_table.use_lobby;
		this.func_get_delay = function ()
		{
			return ::network.inst.GetParentDelay();
		};
		::sound.PlaySE(120);
		::loop.Fade(function ()
		{
			::menu.network.Suspend();
			::menu.character_select.Initialize(1);
		});
		return;
	}.bindenv(this);
	mb_client.ConnectReject = function ( context, table )
	{
		if ("message" in table)
		{
			if (table.message == "busy")
			{
				this.return_code = 1;
			}

			if (table.message == "version")
			{
				this.return_code = 2;
			}

			if (table.message == "watch")
			{
				this.return_code = 3;
			}

			if (table.message == "ready")
			{
				this.return_code = 4;
			}
		}
	}.bindenv(this);
	mb_client.DisconnectParent = function ()
	{
		if (this.is_parent_vs)
		{
			local t = {};
			t.message <- "end_vs";

			for( local i = 0; i < this.client_num; i++ )
			{
				this.inst.SendToChild(i, t);
			}

			this.Disconnect();
			return;
		}

		if (this.is_watch && this.inst)
		{
			this.inst.Reconnect();
			return;
		}
	}.bindenv(this);
	mb_client.ReceiveFromParent = function ( table )
	{
		try
		{
			if ("message" in table)
			{
				if (table.message == "end_vs")
				{
					for( local i = 0; i < ::network_client_num; i++ )
					{
						::network_inst.SendToChild(i, table);
					}

					this.Disconnect();
					  // [027]  OP_POPTRAP        1      0    0    0
					return;
				}
			}
		}
		catch( _e )
		{
		}
	}.bindenv(this);
	local connect_param = {};
	connect_param.version <- ::GetVersion();
	connect_param.allow_watch <- ::config.network.allow_watch;
	connect_param.name <- ::config.network.player_name.len() > 16 ? "" : ::config.network.player_name;
	connect_param.color <- ::savedata.GetColorNum();
	connect_param.extra <- this.icon[1];
	connect_param.battle_num <- 1;

	if (mode & 1)
	{
		connect_param.is_watch <- false;
	}
	if (mode & 2) {

	}

	this.inst_connect = mb_client;
	::debug.print("mb_client.Connect("+addr+","+port+","+connect_param+") begin\n");
	::debug.fprint("network.log","mb_client.Connect("+addr+","+port+","+connect_param+") begin\n");
	return mb_client.Connect(addr, port, connect_param);
	::debug.print("mb_client.Connect end\n");
	::debug.fprint("network.log","mb_client.Connect end\n");
}

function Disconnect( scene = true )
{
	if (this.is_disconnect)
	{
		return;
	}

	if (!::network.IsActive())
	{
		return;
	}

	this.is_disconnect = true;

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
	return this.func_get_delay();
}

function BeginStreaming()
{
	this.inst.BeginStreaming();
}

function EndStreaming()
{
	this.inst.EndStreaming();
}

function BeginStreamingPlay( func_begin, func_end )
{
	this.inst.BeginStreamingPlay(func_begin, func_end);
}

function IsEnableStreamingBuffer()
{
	return this.inst.StreamingPlay();
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
	local ex = this.regexp("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{1,5}");
	local ret = ex.search(text);

	if (ret == null)
	{
		return "";
	}

	return text.slice(ret.begin, ret.end);
}
