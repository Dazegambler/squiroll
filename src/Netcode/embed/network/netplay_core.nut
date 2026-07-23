class Server extends ::manbow.NetworkServer {
    constructor(port, mode) {
        if (::config.network.upnp) {
            ::netplay.upnp_port = port;
            try local ret = ::UPnP.AddPort(port, port, "UDP")
            catch(e);
        }else ::netplay.upnp_port = 0;
        ::netplay.Initialize();
        base.constructor();
        ::netplay.client_num = 2;
        ::netplay.inst_connect = this;
        Init(port,::netplay.client_num);
        if (mode & 1 && ::LOBBY.GetNetworkState() == 2)::punch.init_wait();
    }

    function HandleRequest(id,request) {
        if (request.version != ::GetVersion())
            return {success = false, message = "version"};
        if (::netplay.inst)
            return {success = false, message = ""};
        if (request.is_watch) {
            if (id == 0)
                return {success = false, message = ::config.network.allow_watch ? "ready" : "watch"};
            if (!::netplay.allow_watch)
                return {success = false, message = "watch"};
            return {success = true, message = ""};
        }
        if (id > 0)
            return {success = false, message = "busy"};
        return {success = true, message = ""}; 
    }
    
    function ConnectRequest(id,context,request,reply) {
        local req = HandleRequest(id,request);
        reply.message <- req.message;
        reply.name <- "";
        reply.is_parent_vs <- request.is_watch;
        reply.is_watch <- request.is_watch;
        if (req.success && !request.is_watch) {
            ::LOBBY.Close();
            ::netplay.inst = ::network.inst_connect;
            ::netplay.func_get_delay = @()::network.inst.GetChildDelay(0);
            ::sound.PlaySE(120);
            reply.name = ::config.network.player_name;
            ::netplay.received_request = {
                name = request.name
                color = request.color
                allow_watch = request.allow_watch
            };
        }
        return req.success;
    }

    function DisconnectChild(id) {
        if(id==0)::netplay.Disconnect(); 
    }

    function ReceiveFromChild(id,table) {
        try {
            switch(table.message) {
                case "profile":
                    ::print("p2 profile chunk\n");
                    ::netplay.icon[1] += table.icon_chunk;
                    break;
                case "nvm":
                    ::netplay.Terminate();
                    ::netplay.MatchCancelled();
                    break;
                case "afk":
                    ::netplay.Terminate();
                    ::netplay.update = ::netplay.UpdateMain;
                    ::loop.End();
                    break;
            }
        }catch(e);
    }

    function Acceptmatch() {
        ready = true;
        player_name = [
            ::config.network.player_name,
            request.name.len() > 16 ? "P2" : request.name
        ];
        color_num = [
            ::savedata.GetColorNum(),
            request.color
        ];
        rand_seed = ::manbow.timeGetTime();
        ::srand(rand_seed);
        allow_watch = ::config.network.allow_watch && request.allow_watch;
        request = null;
        ::sound.PlaySE(120);
        ::loop.Fade(function() {
            
        });
    }
};

class Client extends ::manbow.NetworkClient {
    constructor(addr, port, mode) {
        ::netplay.Initialize();
        base.constructor();
        ::netplay.client_num = 3;
        if (mode & 2 && ::LOBBY.GetNetworkState() == 2)::punch.init_connect(addr, port);
        
        if (!Init(0,::netplay.client_num)) {
            ::netplay.inst = null;
            this = null;
        }
        
        local connect_param = {
            version = ::GetVersion()
            allow_watch = ::config.network.allow_watch
            is_watch = mode & 1
            battle_num = 1
            name = ::config.network.player_name.len() > 16 ? "P2" : ::config.network.player_name
            color = ::savedata.GetColorNum()
        };
        ::netplay.host_ip = addr+":"+port;
        ::netplay.inst_connect = this;
        Connect(addr,port,connect_param);
    }

    function ConnectRequest(id,context,request,reply) {
        reply.message = "";
        if (request.version != ::GetVersion()) {
            reply.message = "version";
            return false;
        }
    
        if (!request.is_watch) {
            reply.message = "busy";
            return false;
        }
    
        if (!::netplay.allow_watch) {
            reply.message = "watch";
            return false;
        }
        reply.is_parent_vs <- ::netplay.is_parent_vs;
        reply.is_watch <- true;
        return true;
    }

    function ConnectComplete(id, context, reply) {
        ::LOBBY.Close();
        if (::netplay.inst)return;
        if (reply.is_watch) {
            ::netplay.allow_watch = true;
            ::netplay.is_parent_vs = reply.is_parent_vs;
            ::netplay.is_watch = true;
            ::netplay.inst = ::network.inst_connect;
            ::sound.PlaySE(120);
            ::loop.Fade(function () {
                ::discord.rpc_set_details("Spectating");
                ::menu.network.Terminate();
                ::menu.watch.Initialize();
            });
            return;
        }
        ::netplay.inst = ::network.inst_connect;
        ::netplay.func_get_delay = @()::network.inst.GetParentDelay();
        ::netplay.received_request = {name = reply.name};
    }

    function ConnectReject(context,table) {
        switch (table.message) {
            case "busy":
                ::netplay.return_code = 1;
                break;
            case "version":
                ::netplay.return_code = 2;
                break;
            case "watch":
                ::netplay.return_code = 3;
                break;
            case "ready":
                ::netplay.return_code = 4;
                break;
            case "blocked":
                ::netplay.return_code = 5;
                break;
        }
    }

    function DisconnectParent() {
        if (::netplay.is_parent_vs) {
            local t = {message = "end_vs"};
            for (local i = 0; i < ::netplay.client_num; ++i)
                ::netplay.inst.SendToChild(i,t);
            ::netplay.Disconnect();
            return;
        }
        if (::netplay.is_watch && ::network.inst)::network.inst.Reconnect();
    }

    function ReceiveFromParent(table) {
        try {
            switch(table.message) {
                case "end_vs":
                    for (local i = 0; i < ::netplay.client_num; ++i)
                        ::netplay.inst.SendToChild(i, table);
                    ::netplay.Disconnect();
                    break;
                case "profile":
                    ::print("p1 profile image chunk\n");
                    ::netplay.icon[0] += table.icon_chunk;
                    break;
                case "yes":
                    ::netplay.BeginMatch(table);
                    break;
                case "no":
                    ::netplay.Terminate();
                    ::netplay.update = ::netplay.UpdateMatch;
                    ::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
                    ::netplay.user_state = ::LOBBY.MATCHING;
                    ::LOBBY.SetLobbyUserState(::netplay.user_state);
                    break;
            }
        }catch(e);
    }
};

function Init() {
    timeout <- 0;
    upnp_timeout <- 0;
    retry_count <- 0;
    user_state <- 0;
    interval <- 10000;
    time_stamp <- ::manbow.timeGetTime() - interval + 1000;

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
