local function boolfield(idx,label,sqkey,key) {
    return ::UI.Menu.Enum(idx,label,(::setting.network[sqkey]).tointeger(),function() {
        local page = ::menu.network_config;
        ::menu.help.Set(page.help_item);
        page.Update = page.UpdateCommonItem;
        local Enum = elem.val;
        page.anime.highlight.Set(Enum.left,Enum.top,Enum.right,Enum.bottom);
        page.common_cursor = Enum.cursor;
        page.common_callback_ok = function() {
            local ret = (Enum.cursor.val != 0);
            ::setting.network[sqkey] = ret;
            ::setting.save("network",key,ret.tostring());
            page.anime.highlight.Reset();
        };
        page.common_callback_cancel = function(){
            page.anime.highlight.Reset();
        };
    })
}

::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Title("Network"),
        boolfield(1,"hide ip","hide_ip","hide_ip"),
        boolfield(2,"share ip","share_watch_ip","share_watch_ip"),
        boolfield(3,"hide names","hide_opponent_name","hide_name"),
        boolfield(4,"hide profiles","hide_profile_pictures","hide_profile_pictures")
    )
);
