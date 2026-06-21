class Title extends ::UI.Menu.Entry {
    str_label = "";
    constructor (s) {
        base.constructor({});
        str_label = s;
    }

    function Initialize() {
        elem = {
            label = ::UI.Core.Text({
                str = str_label
                sx = 1.75
                sy = 1.75
                x = ::UI.Menu.center
                y = ::UI.Menu.title_y
            })
        };
        elem.label.x -= ((elem.label.width * elem.label.sx) / 2);
        elem.label.y -= (elem.label.height * elem.label.sy);
    }
};

class Header extends ::UI.Menu.Entry {
    str_label = "";
    constructor(it, s) {
        base.constructor(it);
        str_label = s;
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang];
        elem = {
            label = ::UI.Core.Text({
                str = lang[str_label]
                x = ::UI.Menu.center
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
        };
        elem.label.x -= ((elem.label.width * elem.label.sx) / 2);
    }
};

class Label extends ::UI.Menu.Entry {
    str_label = "";
    constructor (it, s) {
        base.constructor(it);
        str_label = s;
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang];
        elem = {
            label = ::UI.Core.Text({
                str = lang[str_label]
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
        };
    }
}


class Value extends ::UI.Menu.Entry {
    str_val = "";
    constructor (it, s) {
        base.constructor(it);
        str_val = s;
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang];
        elem = {
            val = ::UI.Core.Text({
                str = lang[str_val]
                x = ::UI.Menu.right
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
        };
    }
}

class Variable extends ::UI.Menu.Entry {
    str_label = "";
    ptr = null;
    constructor (it, s, p) {
        base.constructor(it);
        str_label = s;
        ptr = p;
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang];
        elem = {
            label = ::UI.Core.Text({
                str = lang[str_label]
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            val = ::UI.Core.LiveText({
                ptr = this.ptr
                x = ::UI.Menu.right
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
                dx = @()(::UI.Menu.right - (width * sx))
                blue = 0
            })
        };
    }
}

class Sprite extends ::UI.Menu.Entry {
    tex = null;
    lft = 0;
    top = 0;
    hgt = 0;
    wth = 0;

    constructor(it, t, l, tp, h, w) {
        base.constructor({});
        tex = t;
        lft = l;
        top = tp;
        hgt = h;
        wth = w;
    }

    function Initialize() {
        elem = {
            spr = ::UI.Core.Sprite({
                texture = tex
                left = lft
                top = top
                height = hgt
                width = wth
            })
        };
    }
};
