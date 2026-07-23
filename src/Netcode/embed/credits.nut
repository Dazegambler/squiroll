local credit = class extends ::UI.Menu.Entry {
    str_label = "";
    str_val = "";

    constructor (it, l, v) {
        base.constructor(it);
        str_label = l;
        str_val = v;
    }

    function Initialize() {
        local lang = item_table.current();
        elem = {
            label = ::UI.Text({
                str = lang[str_label][0]
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            val = ::UI.Text({
                str = lang[str_val][0]
                x = ::UI.Menu.right
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
                dx = @()(::UI.Menu.right - (width * sx))
            })
        };
    }
};

local item_table = {
    current = @()this["lang"+::config.lang]
    lang0 = {
        zero = ["zero318"],khang = ["khangaroo"]
        hagb = ["hagb"],shoxla = ["shoxla"]
        sog = ["SonofGod1998"],dec = ["dec"]
        taku = ["Takuneru"],caba = ["cabadmdp"]
        armonte = ["armonte"],tom = ["-tom-"]
        fear = ["fearnagae"],penguin = ["JustAPenguin"]
        rest = ["and to all who helped test the early releases(jp)"]
    }
    lang1 = {
        zero = ["zero318"],khang = ["khangaroo"]
        hagb = ["hagb"],shoxla = ["shoxla"]
        sog = ["SonofGod1998"],dec = ["dec"]
        taku = ["Takuneru"],caba = ["cabadmdp"]
        armonte = ["armonte"],tom = ["-tom-"]
        fear = ["fearnagae"],penguin = ["JustAPenguin"]
        rest = ["and to all who helped test the early releases"]
    }
};

::UI.Menu.Create.call(this,
    ::UI.Menu.Page(
        ::UI.Menu.Struct.Title("Special thanks to"),
        credit(item_table,"zero","khang"),
        credit(item_table,"hagb","shoxla"),
        credit(item_table,"sog","dec"),
        credit(item_table,"taku","caba"),
        credit(item_table,"armonte","tom"),
        credit(item_table,"fear","penguin"),
        ::UI.Menu.Struct.Header(item_table,"rest")
    )
);
