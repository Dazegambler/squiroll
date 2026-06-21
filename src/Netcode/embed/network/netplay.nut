timeout <- 0;
upnp_timeout <- 0;
lobby_user_state <- 0;
lobby_interval <- 10000;
lobby_time_stamp <- ::manbow.timeGetTime() - lobby_interval + 1000; 

function WaitInLobby() {
    if (::LOBBY.GetNetworkState() != 2){
        ::print("Lobby is offline\n");
        return false;
    }
    ::LOBBY.SetExternalPort(::config.network.hosting_port);
    ::LOBBY.SetUserData("" + ::config.network.hosting_port);
    upnp_timeout = 0;
    lobby_user_state = ::LOBBY.WAIT_INCOMMING;
    if (!::config.network.upnp)::LOBBY.SetLobbyUserState(lobby_user_state);
    ::network.use_lobby = true;
    ::network.StartupServer(::config.network.hosting_port,0);
    ::lobby.inc_user_count();
    return true;
}

function SearchInLobby() {
    if (::LOBBY.GetNetworkState() != 2) {
        ::print("Lobby is offline\n");
        return false;
    }
    ::LOBBY.SetExternalPort(::config.network.hosting_port);
    ::LOBBY.SetUserData("" + ::config.network.hosting_port);
    lobby_user_state = ::LOBBY.MATCHING;
    ::LOBBY.SetLobbyUserState(lobby_user_state);
    return true;
}

function Host() {
    ::network.use_lobby = false;
    ::network.StartupServer(::config.network.hosting_port,1);
    ::punch.reset_ip();
}

function Connect(addr,port,mode) {
    ::network.StartupClient(addr,port,mode);
    ::config.network.target_host = addr;
    ::config.network.target_port = port;
    ::config.Save();
}

function FoundMatch() {
    local host = ::LOBBY.GetMatchHost();
    if (host != "") {
        lobby_user_state = ::LOBBY.NO_OPERATION;
        ::LOBBY.SetLobbyUserState(lobby_user_state);
        ::network.Terminate();
        local userdata = ::LOBBY.GetMatchUserData();
        return true;
    }
    return false;
}

function IsConnecting() {
    if (::LOBBY.GetLobbyUserState() == 102) {
        if (timeout++ > 360) {
            if (retry_count++ > 5)lobby_user_state = ::LOBBY.MATCHING;
            ::LOBBY.SetLobbyUserState(lobby_user_state);
            timeout = 0;
            return 2;
        }
        return 1;
    }
    return 0;
}

function IsHostAfk() {
    if (timeout++ < 1800)return false;
    ::print("host is afk\n");
    ::network.HostAFK();
    ::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
    lobby_user_state = ::LOBBY.MATCHING;
    ::LOBBY.SetLobbyUserState(lobby_user_state);
    timeout = 0;
    return true;
}
