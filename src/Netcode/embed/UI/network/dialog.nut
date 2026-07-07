function Matchmaking() {
    data = {
        item_table = ::menu.network.item_table.current()    
    };
    obj.text <- ::UI.Text({
        str = ""
        dx = @()(-width / 2)
        dy = @()(-height / 2 - 8)
    });
    Update = function() {
        local str = "";
        switch (::LOBBY.GetLobbyUserState()) {
            case 100:
            case 200:
            case 102:
            case 202:
                str += data.item_table.wait_incomming[0];
                break;
            default:
                str += "Standby...";
                break;
        }
        local req = ::network.received_request;
        if (req) {
            ::UI.Popup.Utility.Dialog(::UI.Network.Dialog.Prompt);
            return;
        }
        
        obj.text.Set(str);
        
        if (::menu.network.page[0].item[0].elem)::menu.network.Update();
        ::netplay.Update();
    };

    if (::config.network.upnp) {
        obj.text.dy = null;
        obj.text.y = -40;
        obj.status <- ::UI.Text({
            str = ""
            ,sx = 0.66
            ,sy = 0.66
            ,y = 10
        });
        obj.status_str <- ::UI.Text({
            str = data.item_table.upnp_state[0]
            ,sx = 0.66
            ,sy = 0.66
            ,dx = @()(-width * sx - 8)
            ,y = 10
        });

        local update = Update;
        Update = function() {
            local upnp_state = ::UPnP.GetAsyncState();
            switch (upnp_state) {
                case 0:
                    obj.status.Set(data.item_table.upnp_state[1]);
                    obj.status.red = 1;
                    obj.status.green = 0;
                    obj.status.blue = 0;
                    break;
                case 1:
                    obj.status.Set(data.item_table.upnp_state[2]);
                    obj.status.red = 1;
                    obj.status.green = 1;
                    obj.status.blue = 0;
                    break;
                case 2:
                    if (::UPnP.GetExternalIP() == "") {
                        obj.status.Set(data.item_table.upnp_state[1]);
                        obj.status.red = 1;
                        obj.status.green = 0;
                        obj.status.blue = 0;
                    }else {
                        obj.status.Set(data.item_table.upnp_state[3]);
                        obj.status.red = 0;
                        obj.status.green = 1;
                        obj.status.blue = 1;
                    }
                    break;
                case 3:
                    obj.status.Set(data.item_table.upnp_state[2]);
                    obj.status.red = 1;
                    obj.status.green = 1;
                    obj.status.blue = 0;
                    break;
            }
            update();
        }
    }
}

function Prompt() {
    data = {
        item_table = ::menu.network.item_table.current()
    }
    obj.text <- ::UI.Text({
        str = ""
        dx = @()(-width / 2)
        dy = @()(-height / 2 - 8)
    });
    Update = function() {
        local req = ::network.received_request;
        local timeleft = 30 - (::netplay.timeout / 60);
        if (!timeleft)::loop.End();
        local str = ::format("%s \\n%s#%dms(%d)"
            data.item_table.match_found[0]
            ,req.name
            ,::network.GetDelay()
            ,timeleft
        );

        obj.text.Set(str);
        ::netplay.Update();
    }
}
