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

room_name <- ["Free","Novice","Veteran","EU","NA","SA","Asia","Dev"];
if (::config.network.lobby_name == "")::config.network.lobby_name = room_name[0];

help_prompt <- ["B1","ok",null,"B2","cancel"];
help_cancel <- ["B2","cancel"];

::manbow.CompileFile("squiroll/network/netplay_update.nut",this);

function WaitInLobby() {
    if (::LOBBY.GetNetworkState() != 2){
        ::print("Lobby is offline\n");
        return false;
    }
    ::LOBBY.SetExternalPort(::config.network.hosting_port);
    ::LOBBY.SetUserData("" + ::config.network.hosting_port);
    upnp_timeout = 0;
    if (!::config.network.upnp)::LOBBY.SetLobbyUserState(::LOBBY.WAIT_INCOMMING);
    user_state  = ::LOBBY.WAIT_INCOMMING;
    ::network.use_lobby = true;
    ::network.StartupServer(::config.network.hosting_port,0);
    ::lobby.inc_user_count();
    update = UpdateMatch;
    return true;
}

function SearchInLobby() {
    if (::LOBBY.GetNetworkState() != 2) {
        ::print("Lobby is offline\n");
        return false;
    }
    ::LOBBY.SetExternalPort(::config.network.hosting_port);
    ::LOBBY.SetUserData("" + ::config.network.hosting_port);
    user_state = ::LOBBY.MATCHING;
    ::LOBBY.SetLobbyUserState(user_state);
    update = UpdateMatch;
    return true;
}

function WaitInPractice() {
    
}

function SearchInPractice() {
}

function HaltInLobby() {
    if(user_state == ::LOBBY.WAIT_INCOMMING)::lobby.dec_user_count();
    ::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION);
    ::network.Terminate();
    //::loop.End();
    update = UpdateIdle;
}

function SetLobby(idx) {
    ::config.network.lobby_name = room_name[idx];
    ::config.Save();
    time_stamp = ::manbow.timeGetTime() - 9000;
    ::LOBBY.Close();
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
        ::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION);
        ::network.Terminate();
        return host;
    }
    return null;
}

function IsConnecting() {
    if (::LOBBY.GetLobbyUserState() == 102) {
        if (timeout++ > 360) {
            if (retry_count++ > 5)::LOBBY.SetLobbyUserState(::LOBBY.MATCHING);
            ::LOBBY.SetLobbyUserState(user_state);
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
    ::LOBBY.SetLobbyUserState(::LOBBY.MATCHING);
    update = UpdateMatch;
    timeout = 0;
    return true;
}

function MatchCancelled() {
    ::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
    user_state = ::LOBBY.WAIT_INCOMMING;
    ::LOBBY.SetLobbyUserState(user_state);
    ::network.StartupServer(::config.network.hosting_port, 0);
    update = UpdateMatch;
}

function GetHost(str) {
    local ret = {ip="",port=-1};
    local delim = str.find(":");
    if (!delim)return ret;
    ret.ip = str.slice(0,delim);
    ret.port = str.slice(delim+1);
    return ret;
}
::loop.AddTask(this);
