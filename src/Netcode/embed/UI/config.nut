class Boolean extends ::UI.Menu.Enum {
    parent = null;
    section = null;
    key = null;
    config = null;
    constructor(idx,label,plugin,_section,_key,page) {
        section = _section;
        key = _key;
        parent = page;
        config = ::plugin.cfg[plugin];
        base.constructor(
            idx,
            label,
            config.data[section][key].tointeger(),
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
        local s = section;
        local k = key;
        local c = config;
        parent.common_callback_ok = function() {
            c.Set((e.val.cursor.val != 0),k,s);
            anime.highlight.Reset();
        };
        parent.common_callback_cancel = function() {
            anime.highlight.Reset();
        };
    }
};

class Value extends ::UI.Menu.Value {
    parent = null;
    section = null;
    key = null;
    config = null;
    constructor(idx,label,plugin,_section,_key,page) {
        parent = page;
        section = _section;
        key = _key;
        config = ::plugin.cfg[plugin];
        base.constructor(
            idx,
            label,
            config.data[section][key]
        );
    }

    function OnClick() {
        local c = config;
        local k = key;
        local s = section;
        local t = elem.val;
        ::Dialog(2,key,function(ret) {
            if (ret) {
                c.Set(ret,k,s);
                t.Set(ret);
            }
        },"");
    }
};

class Keybind extends ::UI.Menu.Value {
    parent = null;
    device = null;
    key = null;
    plugin = null;
    input = null;
    config = null;
    constructor(idx,label,_plugin,_device,_key,_input,page) {
        device = _device;
        key = _key;
        plugin = _plugin;
        input = _input;
        parent = page;
        config = ::plugin.cfg[plugin];
        base.constructor(
            idx,
            label,
            config.data["bind_"+device][key]+""
        );
    }

    function OnClick() {
        local t = elem.val;
        local c = config;
        local p = plugin;
        local k = key;
        local d = device;
        local i = input;
        parent.Update = function() {
            if (::plugin.Input.Poll() >= 0)return;
            Update = function() {
                local id = ::plugin.Input.Poll();
                if (id >= 0) {
                    ::sound.PlaySE("sys_ok");
                    t.Set(id+"");
                    if (p in ::plugin.active_modifiers) {
                        ::plugin.active_modifiers[p].input.Bind(d,i,id);
                    }
                    c.Set(id,k,"bind_"+d);
                    Update = UpdateMain;
                }
            }
        }
    }
};
