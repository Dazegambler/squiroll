//::manbow.CompileFile("data/system/network/dialog_address.nut", dialog.address);
//::manbow.CompileFile("data/system/network/dialog_port.nut", dialog.port);
//::manbow.CompileFile("data/system/network/dialog_connect.nut", dialog.connect);

item_table <- ::menu.common.LoadItemTextArrayUI("data/system/network/item.csv");
local fixArr = @(arr)[arr[0],arr[2],arr[1]]; 
item_table.lang0.upnp = fixArr(item_table.lang0.upnp);
item_table.lang1.upnp = fixArr(item_table.lang1.upnp);
item_table.lang0.allow_watch = fixArr(item_table.lang0.allow_watch);
item_table.lang1.allow_watch = fixArr(item_table.lang1.allow_watch);

local add = function(...) {
    for (local i = 0; i < vargv.len(); i = i+3) {
        local key = vargv[i];
        item_table.lang0[key] <- vargv[i+1];
        item_table.lang1[key] <- vargv[i+2];
    }
}
add(
    "users",["Users(jp)"],["Users"]
    ,"hide_ip",["Hide ip address(jp)","false","true"],["Hide ip address","false","true"]
    ,"share_ip",["Share ip address(jp)","false","true"],["Share ip address","false","true"]
    ,"hide_name",["Hide names(jp)","false","true"],["Hide names","false","true"]
    ,"hide_pfp",["Hide profiles(jp)","false","true"],["Hide profiles","false","true"]
    ,"auto_accept",["Skip request(jp)","false","true"],["Skip request","false","true"]
    ,"cancel_match",["Cancel standby(jp)"],["Cancel standby"]

    ,"match_found",["Match found!(jp)"],["Match found!"]
);

local title = ::manbow.Texture();
title.Load("data/system/network/network_font.png");

local p = @(i,k)::UI.Config.SquirollPTR(::setting.network,i,"network",k);
local bol = @(i,sqi,k)::UI.Menu.Enum.Boolean(item_table,i,p(sqi,k));

local Ptr = @(i)::UI.Config.VanillaPTR(::config.network,i);
::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Struct.TitleSprite(title,800,416,64,224)
        ,::UI.Network.Buttons.Status(item_table,"lobby_state")
        //,::UI.Network.Buttons.Change(item_table,"lobby_select")
        ,::UI.Network.Buttons.Open(item_table,"lobby_incomming")
        ,::UI.Network.Buttons.Search(item_table,"lobby_match")
        ,::UI.Network.Buttons.Host(item_table,"server")
        ,::UI.Network.Buttons.Connect(item_table,"client")
        ,::UI.Network.Buttons.Watch(item_table,"watch")
        ,::UI.Menu.Value.String(item_table,"player_name",Ptr("player_name"),::menu.common.GetMessageText("input_name"))
        ,::UI.Menu.Enum.Boolean(item_table,"upnp",Ptr("upnp"))
        ,::UI.Menu.Enum.Boolean(item_table,"allow_watch",Ptr("allow_watch"))
    )
    ::UI.Menu.Page(
        ::UI.Menu.Struct.TitleSprite(title,800,416,64,224)
        ,bol("hide_ip","hide_ip","hide_ip")
        ,bol("share_ip","share_watch_ip","share_watch_ip")
        ,bol("hide_name","hide_opponent_name","hide_name")
        ,bol("hide_pfp","hide_profile_pictures","hide_profile_pictures")
        ,bol("auto_accept","auto_accept","auto_accept")
    )
);

//mutex <- {
//    matchmaking = ::UI.Menu.Mutex(
//        page[0].item[2]
//        ,page[0].item[3]
//        ,page[0].item[4]
//        ,page[0].item[5]
//        ,page[0].item[6]
//        ,page[0].item[7]
//        ,page[0].item[8]
//        ,page[0].item[9]
//        //,page[0].item[10]
//        ,page[1].item[1]
//        ,page[1].item[2]
//        ,page[1].item[3]
//        ,page[1].item[4]
//        ,page[1].item[5]
//    )
//}

//local u = UpdateMain;
//function UpdateMain() {
//    if (::LOBBY.GetLobbyUserState() == ::LOBBY.NO_OPERATION)mutex.matchmaking.Unlock();
//    else mutex.matchmaking.Lock();
//    u();
//}
