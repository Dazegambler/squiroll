class PluginPTR extends ::PTR {
    constructor (r, i, s) {
        get = @()::plugin.cfg[r].data[s][i];
        set = function(v) {
            ::plugin.cfg[r].Set(v,i,s);
            return get();
        }
    }
};

class SquirollPTR extends ::PTR {
    constructor (r, i, s, k) {
        get = @()r[i];
        set = function(v) {
            r[i] = k;
            ::setting.save(s, k, v.tostring());
            return get();
        }
    }
};

class VanillaPTR extends ::PTR {
    constructor (r, i) {
        get = @()r[i]; 
        set = function (v) {
            r[i] = v;
            ::config.Save();
            return get();
        }
    }
};

//class Keybind extends ::UI.Menu.Value {
//    parent = null;
//    device = null;
//    key = null;
//    plugin = null;
//    input = null;
//    config = null;
//    constructor(idx,label,_plugin,_device,_key,_input,page) {
//        device = _device;
//        key = _key;
//        plugin = _plugin;
//        input = _input;
//        parent = page;
//        config = ::plugin.cfg[plugin];
//        base.constructor(
//            idx,
//            label,
//            config.data["bind_"+device][key]+""
//        );
//    }
//
//    function OnClick() {
//        local t = elem.val;
//        local c = config;
//        local p = plugin;
//        local k = key;
//        local d = device;
//        local i = input;
//        parent.Update = function() {
//            if (::plugin.Input.Poll() >= 0)return;
//            Update = function() {
//                local id = ::plugin.Input.Poll();
//                if (id >= 0) {
//                    ::sound.PlaySE("sys_ok");
//                    t.Set(id+"");
//                    if (p in ::plugin.active_modifiers) {
//                        ::plugin.active_modifiers[p].input.Bind(d,i,id);
//                    }
//                    c.Set(id,k,"bind_"+d);
//                    Update = UpdateMain;
//                }
//            }
//        }
//    }
//};
