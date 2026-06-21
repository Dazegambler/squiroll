local item_table = {
    lang0 = {
        hide_ip = "Hide ip address(jp)"
        share_ip = "Share ip address(jp)"
        hide_name = "Hide names(jp)"
        hide_pfp = "Hide profiles(jp)"
        auto_accept = "Skip request(jp)"
    }
    lang1 = {
        hide_ip = "Hide ip address"
        share_ip = "Share ip address"
        hide_name = "Hide names"
        hide_pfp = "Hide profiles"
        auto_accept = "Skip request"
    }
};

local ptr = @(i,k)::UI.Menu.Config.SquirollPTR(::setting.network,i,"network",k);
local ptr = {
    hide_ip = ptr("hide_ip","hide_ip")
    share_ip = ptr("share_watch_ip","share_watch_ip")
    hide_name = ptr("hide_opponent_name","hide_name")
    hide_pfp = ptr("hide_profile_pictures","hide_profile_pictures")
    auto_accept = ptr("auto_accept","auto_accept")
}
local boolean = @(i)::UI.Menu.Enum.Boolean(item_table,i,ptr[i]);

::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Struct.Title("Network"),
        boolean("hide_ip"),
        boolean("share_ip"),
        boolean("hide_name"),
        boolean("hide_pfp"),
        boolean("auto_accept")
    )
);

local terminate = Terminate;
function Terminate() {
    ::menu.network.state = 0;
    terminate();
}
