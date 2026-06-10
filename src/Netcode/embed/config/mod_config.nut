local nativeBoolean  = class extends ::UI.Menu.Enum {
    parent = null;
    table = null;
    section = null;
    key = null;
    sqkey = null;

    constructor(idx,label,tab,sqke,sec,ke,pge) {
        parent = pge;
        table = tab;
        section = sec;
        key = ke;
        sqkey = sqke
        base.constructor(
            idx,
            label,
            table[sqkey].tointeger(),
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
        local sk = sqkey;
        parent.common_callback_ok = function () {
            local ret = (e.val.cursor.val != 0);
            t[sk] = ret;
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
        ::UI.Menu.Title("Squiroll"),
        ::UI.Menu.Header(0,"Hitbox Visualizer"),
        nativeBoolean(1,"enabled",::overlay,"enabled","hitbox_vis","enabled",this)
        ::UI.Menu.Header(2,"Discord(requires restart)"),
        nativeBoolean(3,"enabled",::discord,"enabled","misc","discord_integration",this)
    )
);
