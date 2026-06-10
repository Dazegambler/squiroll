local nativeBoolean  = class extends ::UI.Menu.Enum {
    parent = null;
    table = null;
    section = null;
    key = null;

    constructor(idx,label,tab,sqke,sec,ke,pge) {
        parent = pge;
        table = tab;
        section = sec;
        key = ke;
        base.constructor(
            idx,
            label,
            table[sqke].tointeger(),
            ["false","true"]
        );
    }

    function OnClick() {
        ::menu.help.Set(parent.help_item);
        parent.Update = parent.UpdateCommonItem;
        parent.anime.highlight.Set(
            elem.val.left,
            elem.val.top,
            elem.val.right,
            elem.val.bottom
        );
        parent.common_cursor = elem.val.cursor;
        local e = elem;
        local t = table;
        local s = section;
        local k = key;
        parent.common_callback_ok = function () {
            local ret = (e.val.cursor.val != 0);
            t[k] = ret;
            ::setting.save(s,k,ret.tostring());
            anime.highlight.Reset();
        };
        parent.common_callback_cancel = function() {
            anime.highlight.Reset();
        };
    }
};

::UI.Menu.Create.call(this
    ::UI.Menu.Page(
        ::UI.Menu.Title("Network"),
        nativeBoolean(1,"hide ip",::setting.network,"hide_ip","network","hide_ip",this),
        nativeBoolean(2,"share ip",::setting.network,"share_watch_ip","network","share_watch_ip",this),
        nativeBoolean(3,"hide names",::setting.network,"hide_opponent_name","network","hide_name",this),
        nativeBoolean(4,"hide profiles",::setting.network,"hide_profile_pictures","network","hide_profile_pictures",this)
    )
);
