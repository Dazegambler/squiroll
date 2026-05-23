::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Title("Squiroll"),
        ::UI.Menu.Header(0,"Hitbox Visualizer"),
        ::UI.Menu.Enum(1,"enabled",(::overlay.enabled).tointeger(),function() {
            local page = ::menu.mod_config;
            ::menu.help.Set(page.help_item);
            page.Update = page.UpdateCommonItem;
            local v = elem.val;
            page.anime.highlight.Set(v.left,v.top,v.right,v.bottom);
            page.common_cursor = v.cursor;
            page.common_callback_ok = function () {
               local ret = (v.cursor.val != 0);
               ::overlay.enabled = ret;
               ::setting.save("hitbox_vis","enabled",ret.tostring());
               page.anime.highlight.Reset();
            };
            page.common_callback_cancel = function () {
                page.anime.highlight.Reset();
            };}),
        ::UI.Menu.Header(2,"Discord(requires restart)"),
        ::UI.Menu.Enum(3,"enabled",(::discord.enabled).tointeger(),function() {
            local page = ::menu.mod_config;
            ::menu.help.Set(page.help_item);
            page.Update = page.UpdateCommonItem;
            local val = elem.val;
            page.anime.highlight.Set(val.left,val.top,val.right,val.bottom);
            page.common_cursor = val.cursor;
            page.common_callback_ok = function () {
               local ret = (val.cursor.val != 0);
               ::discord.enabled = ret;
               ::setting.save("misc","discord_integration",ret.tostring());
               page.anime.highlight.Reset();
            };
            page.common_callback_cancel = function () {
                page.anime.highlight.Reset();
            };})
    )
);
