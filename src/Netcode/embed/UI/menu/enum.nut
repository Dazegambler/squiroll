class Enum extends ::UI.Menu.Entry {
    help = ["B1","ok",null,"B2","cancel",null,"LR","change"];
    str_label = "";
    values = [];
    ptr = null;

    constructor(it, s, p, opts) { 
        base.constructor(it);
        str_label = s;
        ptr = p;
        values.extend(opts);
    }

    function Initialize() {
        local lang = item_table["lang"+::config.lang];
        local opts = [];
        foreach (v in values)opts.push(lang[v]);
        elem = {
            label = ::UI.Core.Text({
                str = lang[str_label]
                max_length = ::UI.Menu.width
                x = ::UI.Menu.left
                y = ::UI.Menu.item_y + (idx * ::UI.Menu.spacing)
            })
            val = ::UI.Core.Enum({
                values = opts
                cursor = this.Cursor(1,opts.len(),::input_all)
                max_length = ::UI.Menu.width
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
        local i = ptr.get();
        elem.val.cursor.val = typeof i == "bool" ? i.tointeger() : i;
    }

    function OnClick() {
        local e = elem.val;
        ::menu.help.Set(help);
        target.Update = target.UpdateCommonItem;
        target.anime.highlight.Set(e.left,e.top,e.right,e.bottom);
        target.common_cursor = e.cursor;
        target.common_callback_ok = function() {
            ptr.set(e.cursor.val);
            e.Set(e.cursor.val);
            anime.highlight.Reset();
        };
        target.common_callback_cancel = function() {
            anime.highlight.Reset();
        };
    }
};
class Boolean extends Enum {
    values = ["disabled","enabled"];
    item_table = {
        lang0 = {//jp
            disabled = "disabled"
            enabled = "enabled"
        }
        lang1 = {//en
            disabled = "disabled"
            enabled = "enabled"
        }
    };

    constructor (it, s, p) {
        base.constructor(it,s,p,[]);
    }

    function OnClick() {
        local e = elem.val;
        local p = ptr;
        ::menu.help.Set(help);
        target.Update = target.UpdateCommonItem;
        target.anime.highlight.Set(e.left,e.top,e.right,e.bottom);
        target.common_cursor = e.cursor;
        target.common_callback_ok = function() {
            p.set(e.cursor.val != 0);
            e.Set(e.cursor.val);
            anime.highlight.Reset();
        };
        target.common_callback_cancel = function() {
            anime.highlight.Reset();
        };
    }
};
