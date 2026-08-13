update <- null;

function Check() {
    local now = ::manbow.timeGetTime();
    if (now - time_stamp < interval)return;
    time_stamp = now;

    if (::LOBBY.GetNetworkState() == ::LOBBY.CLOSED)
        ::LOBBY.Connect("","","",::config.network.lobby_name,::config.network.lobby_name);
}

function Update() {
    if(user_state == ::LOBBY.NO_OPERATION)Check();
    if(update)update();
}

function UpdateIdle() {
    ::punch.ignore_ping();
}

function UpdatePrompt() {
    timeout++;
    if (::setting.network.auto_accept || ::input_all.b0 == 1)::network.AcceptMatch();
    if (::input_all.b1 == 1) {
        ::network.RejectMatch();
        update = UpdateMatch;
    }
}

function UpdateMatch() {
    if (::network.request) {
        update = UpdatePrompt;
        return;
    }
    if (::input_all.b1 == 1)HaltInLobby();

    if (::config.network.upnp &&
        ::LOBBY.GetLobbyUserState() == ::LOBBY.NO_OPERATION &&
        (::UPnP.GetAsyncState() == 2 || upnp_timeout++ > 360)
    ) {
        ::LOBBY.SetLobbyUserState(::LOBBY.WAIT_INCOMMING);
    }

    if (IsConnecting() == 2)return;
    else timeout = 0;
   
    local host = FoundMatch();
    if (host) {
        ::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION);
        ::print("match found\n");
        ::network.Terminate();
        local port = ::LOBBY.GetMatchUserData();
        local target = GetHost(host);
        Connect(target.ip,port.tointeger(),0);
        update = UpdateMatchFound;
    }
}

function UpdateMatchFound() {
    if (::input_all.b1 == 1) {
        if (user_state == 102)::lobby.dec_user_count();
        if (::network.request)::network.CancelRequest();
        else {
            ::LOBBY.SetLobbyUserState(::LOBBY.NO_OPERATION);
            ::network.Terminate();
            ::loop.End();
        }
        update = UpdateIdle;
        return;
    }
    if (::network.request) {
        if (IsHostAfk())update = UpdateMatch;
    }else {
        if (!::network.inst && timeout++ > 360) {
            ::LOBBY.SetLobbyUserState(user_state);
            ::print("match connection fail\n");
            ::network.Terminate();
            timeout = 0;
            update = UpdateMatch;
        }
    }
}

function UpdateWaitServer() {
    if (::network.request)::network.AcceptMatch();
}
