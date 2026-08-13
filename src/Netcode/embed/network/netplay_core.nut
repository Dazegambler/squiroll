class Server extends ::manbow.NetworkServer {
    Reply = {
        Yes = @(){
            message = "yes"
            rand_seed = ::network.rand_seed
            is_parent_vs = true
            allow_watch = ::network.allow_watch
            hide_ip = ::setting.network.hide_ip || !::setting.network.share_watch_ip
            use_lobby = ::network.use_lobby
            name = ::config.network.player_name.len() > 16 ? "P1" : ::config.network.player_name
            color = ::network.color_num[0]
        };
        
        No = @(){message = "no"};
    }

    constructor() {
        base.constructor();
        //this has to be done this way
        //i hate it
        ConnectRequest = function(id,context,request,reply) {
            local req = HandleRequest(id,request);
            reply.message <- req.message;
            reply.is_parent_vs <- request.is_watch;
            reply.is_watch <- request.is_watch;
            reply.name <- "";
            ::print("Request result:"+req.success+"\n");
            if (req.success && !request.is_watch) {
                ::LOBBY.Close();
                ::network.inst = ::network.inst_connect;
                ::network.func_get_delay = @()::network.inst.GetChildDelay(0);
                ::sound.PlaySE(120);
                ::network.request = {
                    name = request.name
                    color = request.color
                    allow_watch = request.allow_watch
                };
                reply.name = ::config.network.player_name;
            }
            return req.success;
        }.bindenv(this);
        DisconnectChild = function(id) {
            if(id==0)::network.Disconnect(); 
        }.bindenv(this);
        ReceiveFromChild = function(id,table) {
            try {
                switch(table.message) {
                    case "profile":
                        ::print("p2 profile chunk\n");
                        ::network.icon[1] += table.icon_chunk;
                        break;
                    case "nvm":
                        ::network.Terminate();
                        ::netplay.MatchCancelled();
                        break;
                    case "afk":
                        ::network.Terminate();
                        ::netplay.update = ::netplay.UpdateMain;
                        ::loop.End();
                        break;
                }
            }catch(e);
        }.bindenv(this);
    }

    function JoinLobby() {
        if(::LOBBY.GetNetworkState() != 2)return false;
        ::LOBBY.SetExternalPort(::config.network.hosting_port);
        ::LOBBY.SetUserData(""+::config.network.hosting_port);
        if(!::config.network.upnp)::LOBBY.SetLobbyUserState(::LOBBY.WAIT_INCOMMING);
        ::netplay.user_state = ::LOBBY.WAIT_INCOMMING;
        ::lobby.inc_user_count();
        return true;
    }

    function Open(port,mode,lobby) {
        if(lobby&&!(JoinLobby())) {
            ::print("lobby is offline");
            return false;
        }
        if (::config.network.upnp) {
            ::network.upnp_port = port;
            try local ret = ::UPnP.AddPort(port, port, "UDP")
            catch(e);
        }else ::network.upnp_port = 0;
        ::network.Initialize();
        ::network.client_num = 2;
        ::network.inst_connect = this;
        Init(port,client_num); if (mode & 1 && ::LOBBY.GetNetworkState() == 2)::punch.init_wait(); return true; 
    }

    function HandleRequest(id,request) {
        if (request.version != ::GetVersion())
            return {success = false, message = "version"};
        if (::network.inst)
            return {success = false, message = ""};
        if (request.is_watch) {
            if (id == 0)
                return {success = false, message = ::config.network.allow_watch ? "ready" : "watch"};
            if (!::network.allow_watch)
                return {success = false, message = "watch"};
            return {success = true, message = ""};
        }
        if (id > 0)
            return {success = false, message = "busy"};
        return {success = true, message = ""}; 
    }

    function AcceptMatch() {
        ::network.ready = true;
        ::network.player_name = [
            ::config.network.player_name,
            ::network.request.name.len() > 16 ? "P2" : ::network.request.name
        ];
        ::network.color_num = [
            ::savedata.GetColorNum(),
            ::network.request.color
        ];
        ::network.icon = [
            ::network.local_icon,
            ""
        ];
        ::network.rand_seed = ::manbow.timeGetTime();
        ::srand(::network.rand_seed);
        ::network.allow_watch = ::config.network.allow_watch && ::network.request.allow_watch;
        ::network.request = null;
        ::sound.PlaySE(120);
        local packet = Reply.Yes();
        ::loop.Fade(function() {
            ::network.inst.SendToChild(0,packet);
            foreach (chunk in ::network.chunked_icon) 
                ::network.inst.SendToChild(0,{message = "profile",icon_chunk = chunk});
            ::discord.rpc_set_details("VS online");
            ::netplay.update = ::netplay.UpdateIdle;
            ::menu.network.Suspend();
            ::menu.character_select.Initialize(1);
        });
    }

    function RejectMatch() {
        SendToChild(0, Reply.No());
        ::network.Terminate();
        ::LOBBY.Connect("","","", ::config.network.lobby_name, ::config.network.lobby_name);
        ::netplay.user_state = ::LOBBY.WAIT_INCOMMING;
        ::LOBBY.SetLobbyUserState(::netplay.user_state);
        Open(::config.network.hosting_port,0); 
    }
};

class Client extends ::manbow.NetworkClient {
    Reply = {
        Connect = @(mode){
            version = ::GetVersion()
            allow_watch = ::config.network.allow_watch
            is_watch = mode & 1
            battle_num = 1
            name = ::config.network.player_name.len() > 16 ? "P2" : ::config.network.player_name
            color = ::savedata.GetColorNum()
        }
        Afk = @(){message = "afk"};
        Cancel = @(){message = "nvm"};
    }

    constructor() {
        base.constructor();
        ConnectRequest = function(id,context,request,reply) {
            reply.message = "";
            if (request.version != ::GetVersion()) {
                reply.message = "version";
                return false;
            }
        
            if (!request.is_watch) {
                reply.message = "busy";
                return false;
            }
        
            if (!::network.allow_watch) {
                reply.message = "watch";
                return false;
            }
            reply.is_parent_vs <- ::network.is_parent_vs;
            reply.is_watch <- true;
            return true;
        }.bindenv(this);
        ConnectComplete = function(id, context, reply) {
            ::LOBBY.Close();
            if (reply.is_watch) {
                ::network.allow_watch = true;
                ::network.is_parent_vs = reply.is_parent_vs;
                ::network.is_watch = true;
                ::network.inst = ::network.inst_connect;
                ::sound.PlaySE(120);
                ::loop.Fade(function () {
                    ::discord.rpc_set_details("Spectating");
                    ::menu.network.Suspend();
                    ::menu.watch.Initialize();
                });
                return;
            }
            ::network.inst = ::network.inst_connect;
            ::network.func_get_delay = @()::network.inst.GetParentDelay();
            ::network.request = {name = reply.name};
        }.bindenv(this);
        ConnectReject = function(context,table) {
            switch (table.message) {
                case "busy":
                    ::network.return_code = 1;
                    break;
                case "version":
                    ::network.return_code = 2;
                    break;
                case "watch":
                    ::network.return_code = 3;
                    break;
                case "ready":
                    ::network.return_code = 4;
                    break;
                case "blocked":
                    ::network.return_code = 5;
                    break;
            }
        }.bindenv(this);
        DisconnectParent = function() {
            if (::network.is_parent_vs) {
                local t = {message = "end_vs"};
                for (local i = 0; i < ::network.client_num; ++i)
                    SendToChild(i,t);
                ::network.Disconnect();
                return;
            }
            if (::network.is_watch)Reconnect();
        }.bindenv(this);
        ReceiveFromParent = function(table) {
            try {
                switch(table.message) {
                    case "end_vs":
                        for (local i = 0; i < ::network.client_num; ++i)
                            SendToChild(i, table);
                        ::network.Disconnect();
                        break;
                    case "profile":
                        ::print("p1 profile image chunk\n");
                        ::network.icon[0] += table.icon_chunk;
                        break;
                    case "yes":
                        MatchAccepted(table);
                        break;
                    case "no":
                        ::network.Terminate();
                        ::netplay.update = ::netplay.UpdateMatch;
                        ::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
                        ::netplay.user_state = ::LOBBY.MATCHING;
                        ::LOBBY.SetLobbyUserState(::netplay.user_state);
                        break;
                }
            }catch(e);
        }.bindenv(this); 
    }

    function JoinLobby() {
        if(::LOBBY.GetNetworkState() != 2)return false;
        ::LOBBY.SetExternalPort(::config.network.hosting_port);
        ::LOBBY.SetUserData(""+::config.network.hosting_port);
        ::netplay.user_state = ::LOBBY.MATCHING;
        ::LOBBY.SetLobbyUserState(::netplay.user_state);
        return true;
    }

    function Join(addr,port,mode) {
        ::network.Initialize();
        ::network.client_num = 3;
        if (mode & 2 && ::LOBBY.GetNetworkState() == 2)::punch.init_connect(addr, port);
        if (!Init(0,::network.client_num)) {
            ::network.inst = null;
            this = null;
        }
        
        ::network.host_ip = addr+":"+port;
        ::network.inst_connect = this;
        ::print(::format("Send Connection request to %s\n",::network.host_ip));
        Connect(addr,port,Reply.Connect(mode));
    }

    function MatchAccepted(reply) {
        ::network.request = null;
        ::network.ready = true;
        ::network.is_parent_vs = true;
        ::network.is_client = true;
        ::network.allow_watch = reply.allow_watch;
        ::network.hide_host_ip = reply.hide_ip;
        ::network.use_lobby = reply.use_lobby;
        ::network.rand_seed = reply.rand_seed;
        ::srand(::network.rand_seed);

        ::network.player_name = [
            reply.name.len() > 16 ? "P1" : reply.name,
            ::config.network.player_name
        ];
    
        ::network.color_num = [
            reply.color,
            ::savedata.GetColorNum()
        ];
    
        ::network.icon = [
            "",
            ::network.local_icon
        ];

        ::sound.PlaySE(120);
        ::loop.Fade(function() {
            foreach (chunk in ::network.chunked_icon)
                ::network.inst.SendToParent({message = "profile",icon_chunk = chunk});
            ::discord.rpc_set_details("VS Online");
            ::menu.network.Suspend();
            ::menu.character_select.Initialize(1);
        });
    }

    function HostAFK() {
        SendToParent(AFK());
        ::network.Terminate();
    }

    function CancelRequest() {
        SendToParent(CANCEL());
        ::network.Terminate();
        ::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
        ::netplay.user_state = ::LOBBY.NO_OPERATION;
        ::LOBBY.SetLobbyUserState(::netplay.user_state);
        ::netplay.update = ::netplay.UpdateIdle;
    }
};

function Init() {
    timeout <- 0;
    upnp_timeout <- 0;
    upnp_port <- 0;
    retry_count <- 0;
    user_state <- 0;
    interval <- 10000;
    time_stamp <- ::manbow.timeGetTime() - interval + 1000;

    request <- null;
    inst <- null;
    inst_connect <- null;
    state <- 
        0       |//is_client
        0 << 1  |//is_watch
        0 << 2  |//is_parent_vs
        1 << 3  ;//is_disconnect

    ::libact.LoadPlugin("data/plugin/se_lobby.dll");
    ::libact.LoadPlugin("data/plugin/se_upnp.dll");
    
    ::LOBBY.SetMaxNickLength(32);
    ::LOBBY.SetPrefix(::network.lobby_prefix);
    ::LOBBY.SetExternalPort(::config.network.hosting_port);
    ::LOBBY.SetVersionSig(::network.lobby_version_sig);
    ::LOBBY.SetStrikeFactor(1, 1000);

    if (::config.network.lobby_name == "") {
        ::config.network.lobby_name = "Free";
        ::config.Save();
    }
}

function Terminate() {
    if (upnp_port > 0)
        try ::UPnP.DeletePort(upnp_port, "UDP")
        catch(_e);
    timeout = upnp_port = 0;
    request = inst = inst_connect = null;
    state = 0 | 0 << 1 | 0 << 2 | 1 << 3;
}

function Disconnect(scene = true) {
    if (is_disconnect||inst == null)return;
    is_disconnect = true;

    if (scene)
        ::loop.Fade(function() {
            if (::netplay.inst)::netplay.Terminate();
        });
    else Terminate();
}
