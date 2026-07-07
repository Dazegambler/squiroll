class Label extends ::UI.Menu.Entry {
    str_label = "";
    constructor (it, s) {
        base.constructor(it);
        str_label = s;
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang][str_label];
        elem = {
            label = ::UI.Text({
                str = lang[0]
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
        };
        if (lock) {
            elem.label.red *= 0.5;
            elem.label.green *= 0.5;
            elem.label.blue *= 0.5;
        }
    }

    function Enable() {
        if (!lock)return;
        lock = false;
        elem.label.red *= 2;
        elem.label.green *= 2;
        elem.label.blue *= 2;
    }

    function Disable() {
        if (lock)return;
        lock = true;
        elem.label.red *= 0.5;
        elem.label.green *= 0.5;
        elem.label.blue *= 0.5;
    }
}

class Value extends ::UI.Menu.Entry {
    str_val = "";
    constructor (it, s) {
        base.constructor(it);
        str_val = s;
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang][str_val];
        elem = {
            val = ::UI.Text({
                str = lang[0]
                x = ::UI.Menu.right
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
                blue = 0
            })
        };
        if (lock) {
            elem.val.red *= 0.5;
            elem.val.green *= 0.5;
            elem.val.blue *= 0.5;
        } 
    }

    function Enable() {
        if (!lock)return;
        lock = false;
        elem.val.red *= 2;
        elem.val.green *= 2;
        elem.val.blue *= 2;
    }

    function Disable() {
        if (lock)return;
        lock = true;
        elem.val.red *= 0.5;
        elem.val.green *= 0.5;
        elem.val.blue *= 0.5;
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
        local lang = item_table["lang"+::config.lang][str_label];
        elem = {
            label = ::UI.Text({
                str = lang[0]
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            val = ::UI.Text({
                str = ptr.get()
                x = ::UI.Menu.right
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
                dx = @()(::UI.Menu.right - (width * sx))
                blue = 0
            })
        };
        if (lock) {
            foreach(e in elem) {
                e.red *= 0.5; 
                e.green *= 0.5;
                e.blue *= 0.5; 
            }
        }
    }

    function Enable() {
        if (!lock)return;
        lock = false;
        foreach(e in elem) {
            e.red *= 2;
            e.green *= 2;
            e.blue *= 2;
        }
    }

    function Disable() {
        if (lock)return;
        lock = true;
        foreach(e in elem) {
            e.red *= 0.5; 
            e.green *= 0.5;
            e.blue *= 0.5; 
        }
    }
}

class Enum extends ::UI.Menu.Entry {
    str_label = "";
    ptr = null;

    constructor(it, s, p) {
        base.constructor(it);
        str_label = s;
        ptr = p;
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang][str_label];
        local opts = lang.slice(1);
        elem = {
            label = ::UI.Text({
                str = lang[0]
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            val = ::UI.Enum({
                values = opts
                cursor = this.Cursor(1,opts.len(),::input_all)
                x = ::UI.Menu.right
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
                blue = 0
            })
        }
        local w = 0;
        local h = 0;
        foreach (str in opts) {
            elem.val.Set(str);
            if(elem.val.width > w)w = elem.val.width;
            if(elem.val.height > h)h = elem.val.height;
        }
        elem.val.x -= (w * elem.val.sx);
        elem.val.left = elem.val.x - 8;
        elem.val.right = elem.val.x + w + 8;
        elem.val.top = elem.val.y + 10;
        elem.val.bottom = elem.val.top + h + 3;
        elem.val.cursor.val = ptr.get().tointeger();
    
        if (lock) {
            foreach(e in elem) {
                e.red *= 0.5; 
                e.blue *= 0.5; 
                e.green *= 0.5;
            }
        }
    }

    function Enable() {
        if (!lock)return;
        lock = false;
        foreach(e in elem) {
            e.red *= 2;
            e.blue *= 2;
            e.green *= 2;
        }
    }

    function Disable() {
        if (lock)return;
        lock = true;
        foreach(e in elem) {
            e.red *= 0.5; 
            e.blue *= 0.5; 
            e.green *= 0.5;
        }
    }
};

class Sprite extends ::UI.Menu.Entry {
    tex = null;
    X = 0;
    Y = 0;
    lft = 0;
    top = 0;
    hgt = 0;
    wth = 0;

    constructor(x, y, t, l, tp, h, w) {
        base.constructor({});
        X = x;
        Y = y;
        tex = t;
        lft = l;
        top = tp;
        hgt = h;
        wth = w;
    }

    function Initialize() {
        elem = {
            label = ::UI.Sprite({
                x = X
                y = Y
                texture = tex
                left = lft
                top = top
                height = hgt
                width = wth
            })
        };
        if (lock) {
            elem.label.red *= 0.5;
            elem.label.green *= 0.5;
            elem.label.blue *= 0.5;
        }
    }

    function Enable() {
        if (!lock)return;
        lock = false;
        elem.label.red *= 2;
        elem.label.green *= 2;
        elem.label.blue *= 2;
    }

    function Disable() {
        if (lock)return;
        lock = true;
        elem.label.red *= 0.5;
        elem.label.green *= 0.5;
        elem.label.blue *= 0.5;
    }
};

class TitleSprite extends Sprite {
    constructor (t, l, tp, h, w) {
        base.constructor(
            ::UI.Menu.center - (w /2), 
            ::UI.Menu.title_y,
            t,l,tp,h,w
        )
    }
};

class Title extends ::UI.Menu.Entry {
    str_label = "";
    constructor (s) {
        base.constructor({});
        str_label = s;
    }

    function Initialize() {
        elem = {
            label = ::UI.Text({
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
        local lang = item_table["lang"+::config.lang][str_label];
        elem = {
            label = ::UI.Text({
                str = lang[0]
                x = ::UI.Menu.center
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
        };
        elem.label.x -= ((elem.label.width * elem.label.sx) / 2);
        if (lock) {
            elem.label.red *= 0.5;
            elem.label.green *= 0.5;
            elem.label.blue *= 0.5;
        }
    }

    function Enable() {
        if (!lock)return;
        lock = false;
        elem.label.red *= 2;
        elem.label.green *= 2;
        elem.label.blue *= 2;
    }

    function Disable() {
        if (lock)return;
        lock = true;
        elem.label.red *= 0.5;
        elem.label.green *= 0.5;
        elem.label.blue *= 0.5;
    }
};
