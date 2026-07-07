class String extends ::UI.Menu.Struct.Variable {
    diag_str = "";
    constructor (it, s, p, dg_str) {
        base.constructor(it, s, p);
        diag_str = dg_str;
    }
    
    function OnClick() {
        if (lock)return;
        local txt = elem.val;
        local p = ptr;
        ::Dialog(2,diag_str,function(ret) {
            if (ret) {
                p.set(ret);
                txt.Set(ret);
            }
            txt = null;
            p = null;
        },p.get()+"");
    }
};

class Float extends String {
    function OnClick() {
        if (lock)return;
        local txt = elem.val;
        local p = ptr;
        ::Dialog(2,diag_str,function(ret) {
            if (ret) {
                p.set(ret.tofloat());
                txt.Set(ret);
            }
            txt = null;
            p = null;
        },p.get()+"");
    }
};

class Integer extends String {
     function OnClick() {
        if (lock)return;
        local txt = elem.val;
        local p = ptr;
        ::Dialog(2,diag_str,function(ret) {
            if (ret) {
                p.set(ret.tointeger());
                txt.Set(ret);
            }
            txt = null;
            p = null;
        },p.get()+"");
    }
};
