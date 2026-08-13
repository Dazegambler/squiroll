class Matchmaking extends ::UI.Menu.Entry {
    help = ["B1","ok",null,"B2","cancel",null,"LR","change"];
    room_title = [
        "Free","Novice","Veteran",//original lobbies
        "EU","NA","SA","Asia"//squiroll lobbies
    ];
    str_label = "";

    host = null;
    state = 0;

    constructor (it, s) {
        base.constructor(it);
        str_label = s;
        state = 0;
    }

    function OnClick() {
        if (lock)return;
        local btn = this;
        switch (state) {
            case 0:
                ::menu.help.Set(help);
                target.Update = target.UpdateCommonItem;
                target.anime.highlight.Set(
                    btn.elem.val.left,
                    btn.elem.val.top,
                    btn.elem.val.right,
                    btn.elem.val.bottom
                );
                target.common_cursor = btn.elem.val.cursor;
                target.common_callback_ok = function() {
                    btn.elem.val.Set(btn.elem.val.cursor.val);
                    anime.highlight.Reset();
                    btn.state = 1;
                    btn.elem.label.Set(item_table.current().cancel_match[0]);
                    ::netplay.BeginMatchmaking(btn.elem.val.cursor.val,btn.host);
                    btn = null;
                };
                target.common_callback_cancel = function() {
                    anime.highlight.Reset();
                    btn.state = 0;
                    btn = null;
                }
                break;
            case 1:
                ::netplay.HaltInLobby(); 
                btn.state = 0;
                btn.elem.label.Set(item_table.current()[str_label][0]);
                btn = null;
                break;
        }
        
    }

    function Initialize() {
        local lang = item_table.current();
        local opts = room_title;
        if (::debug.dev())opts.push("Dev");
        elem = {
            label = ::UI.Text({
                str = lang[str_label][0]
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            users = ::UI.Text({
                str = lang.users[0]
                x = ::UI.Menu.center
                dx = @()(::UI.Menu.center - ((width * sx) / 2))
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            val = ::UI.Enum({
                values = opts
                cursor = this.Cursor(1,opts.len(),::input_all)
                x = ::UI.Menu.right
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
                blue = 0
            })
        }
        local w = 0;
        local h = 0;
        foreach (str in opts) {
            elem.val.Set(str);
            if (elem.val.width > w)w = elem.val.width;
            if (elem.val.height > h)h = elem.val.height;
        }
        elem.val.x -= (w * elem.val.sx);
        elem.val.left = elem.val.x - 8;
        elem.val.right = elem.val.x + w + 8;
        elem.val.top = elem.val.y + 10;
        elem.val.bottom = elem.val.top + h + 3;
        elem.val.cursor.val = room_title.find(::config.network.lobby_name);
    }

    function Update() {
        local able = ::LOBBY.GetNetworkState() != 2;
        local str = ::format("%s: %s",
            item_table.current().users[0],
            able ? "offline" : ::lobby.user_count()+"" 
        );
        elem.users.Set(str);
        local press_able = able && (state == 0 || ::LOBBY.GetLobbyUserState() != ::LOBBY.NO_OPERATION);
        if (press_able != lock) {
            lock = press_able;
            if (lock)Enable();
            else Disable();
        }
        base.Update();
    }

    function Enable() {
        if (state != 0 || !lock)return;
        lock = false;
        elem.label.red = 1;
        elem.label.green = 1;
        elem.label.blue = 1;
        elem.val.red = 1;
        elem.val.green = 1;
        elem.val.blue = 0;
    }

    function Disable() {
        if (state != 0 || lock)return;
        lock = true;
        elem.label.red = 0.5;
        elem.label.green = 0.5;
        elem.label.blue = 0.5;
        elem.val.red = 0.5;
        elem.val.green = 0.5;
        elem.val.blue = 0;
    }
}


class Search extends Matchmaking {
    constructor (it, s) {
        base.constructor(it,s);
        host = false;
    }
}

class Open extends Matchmaking {
    constructor (it, s) {
        base.constructor(it,s);
        host = true;
    }
}

//class Search extends ::UI.Menu.Struct.Label {
//    state = 0;
//    function OnClick() {
//        if (lock)return;
//        if (::netplay.SearchInLobby()) {
//            ::UI.Popup.Utility.Notification.Top(::UI.Network.Dialog.Matchmaking);
//        }
//    }
//}
//
//class Open extends ::UI.Menu.Struct.Label {
//    function OnClick() {
//        if (lock)return;
//        if (::netplay.WaitInLobby()) {
//            ::UI.Popup.Utility.Notification.Top(::UI.Network.Dialog.Matchmaking);
//        }
//    }
//}

class Host extends ::UI.Menu.Struct.Label {}
class Connect extends ::UI.Menu.Struct.Label {}
class Watch extends ::UI.Menu.Struct.Label {}

class Status extends ::UI.Menu.Struct.Label {
    function Initialize() {
        local lang = item_table.current()[str_label];
        elem = {
            label = ::UI.Text({
                str = lang[0]+": "
                x = ::UI.Menu.center
                dx = @()(::UI.Menu.center - (width * sx))
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            val = ::UI.Text({
                str = lang[1]
                x = ::UI.Menu.center
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
                green = 0
                blue = 0
            })
        }
    }

    function Update() {
        local c = [0,0,0];
        local state = ::LOBBY.GetNetworkState();
        switch (state) {
            case 0:
            case 1:
            case 2:
                c[state] = 1;
                break;
            default:
                state = 0;
                break;
        }
        c[state] = 1;
        foreach (i,k in ["red","green","blue"]) {
            elem.val[k] = c[i];
        } 
        elem.val.Set(item_table.current()[str_label][1+state]);
        base.Update();
    }
}

//class Change extends ::UI.Menu.Entry {
//    help = ["B1","ok",null,"B2","cancel",null,"LR","change"];
//    room_title = [
//        "Free","Novice","Veteran",
//        "EU","NA","SA","Asia"
//    ];
//    str_label = "";
//
//    constructor (it, s) {
//        base.constructor(it);
//        str_label = s;
//    }
//
//    function OnClick() {
//        if (lock)return;
//        local e = elem.val;
//        ::menu.help.Set(help);
//        target.Update = target.UpdateCommonItem;
//        target.anime.highlight.Set(e.left,e.top,e.right,e.bottom);
//        target.common_cursor = e.cursor;
//        target.common_callback_ok = function() {
//            ::netplay.SetLobby(e.cursor.val);
//            e.Set(e.cursor.val);
//            anime.highlight.Reset();
//            e = null;
//        };
//        target.common_callback_cancel = function() {
//            anime.highlight.Reset();
//            e = null;
//        }
//    }
//
//    function Initialize() {
//        local lang = item_table.current();
//        local opts = room_title;
//        if (::debug.dev())opts.push("Dev");
//        elem = {
//            label = ::UI.Text({
//                str = lang[str_label][0]
//                x = ::UI.Menu.left
//                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
//            })
//            users = ::UI.Text({
//                str = lang.users[0]
//                x = ::UI.Menu.center
//                dx = @()(::UI.Menu.center - ((width * sx) / 2))
//                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
//            })
//            val = ::UI.Enum({
//                values = opts
//                cursor = this.Cursor(1,opts.len(),::input_all)
//                x = ::UI.Menu.right
//                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
//                blue = 0
//            })
//        }
//        local w = 0;
//        local h = 0;
//        foreach (str in opts) {
//            elem.val.Set(str);
//            if (elem.val.width > w)w = elem.val.width;
//            if (elem.val.height > h)h = elem.val.height;
//        }
//        elem.val.x -= (w * elem.val.sx);
//        elem.val.left = elem.val.x - 8;
//        elem.val.right = elem.val.x + w + 8;
//        elem.val.top = elem.val.y + 10;
//        elem.val.bottom = elem.val.top + h + 3;
//        elem.val.cursor.val = room_title.find(::config.network.lobby_name);
//        if (lock) {
//            foreach (k,e in elem) {
//                if (k == "users")continue;
//                e.red *= 0.5;
//                e.green *= 0.5;
//                e.blue *= 0.5;
//            }
//        }
//    }
//
//    function Update() {
//        local str = ::format("%s: %s",
//            item_table.current().users[0],
//            ::LOBBY.GetNetworkState() != 2 ? "offline" : ::lobby.user_count()+"" 
//        );
//        elem.users.Set(str);
//        base.Update();
//    }
//
//    function Enable() {
//        if (!lock)return;
//        lock = false;
//        foreach (k,e in elem) {
//            if (k == "users")continue;
//            e.red *= 2;
//            e.green *= 2;
//            e.blue *= 2;
//        }
//    }
//
//    function Disable() {
//        if (lock)return;
//        lock = true;
//        foreach (k,e in elem) {
//            if (k == "users")continue;
//            e.red *= 0.5;
//            e.green *= 0.5;
//            e.blue *= 0.5;
//        }
//    }
//}
