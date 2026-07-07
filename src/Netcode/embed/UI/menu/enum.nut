class Enum extends ::UI.Menu.Struct.Enum {
    help = ["B1","ok",null,"B2","cancel",null,"LR","change"];

    function OnClick() {
        if (lock)return;
        local e = elem.val;
        local p = ptr;
        ::menu.help.Set(help);
        target.Update = target.UpdateCommonItem;
        target.anime.highlight.Set(e.left,e.top,e.right,e.bottom);
        target.common_cursor = e.cursor;
        target.common_callback_ok = function() {
            p.set(e.cursor.val);
            e.Set(e.cursor.val);
            anime.highlight.Reset();
            e = p = null;
        };
        target.common_callback_cancel = function() {
            anime.highlight.Reset();
            e = p = null;
        };
    }
};
class Boolean extends Enum {
    function OnClick() {
        if (lock)return;
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
            e = p = null;
        };
        target.common_callback_cancel = function() {
            anime.highlight.Reset();
            e = p = null;
        };
    }
};
