class String extends ::UI.Menu.Struct.Variable {
    diag_str = "";
    constructor (it, s, p, diag) {
        base.constructor(it,s,p);
        diag_str = diag;
    }

    function OnClick() {
        local txt = elem.val;
        ::Dialog(2,diag_str,function(ret) {
            if (ret) {
                txt.Set(ret);
            }
        },"");
    }
};
class Float extends ::UI.Menu.Struct.Variable {
    diag_str = "";
    constructor (it, s, p, diag) {
        base.constructor(it,s,p);
        diag_str = diag;
    }

    function OnClick() {
        local txt = elem.val;
        ::Dialog(2,diag_str,function(ret) {
            if (ret) {
                txt.Set(ret.tofloat());
            }
        },"");
    }
};
class Integer extends ::UI.Menu.Struct.Variable {
    diag_str = "";
    constructor (it, s, p, diag) {
        base.constructor(it,s,p);
        diag_str = diag;
    }

    function OnClick() {
        local txt = elem.val;
        ::Dialog(2,diag_str,function(ret) {
            if (ret) {
                txt.Set(ret.tointeger());
            }
        },"");
    }
};
