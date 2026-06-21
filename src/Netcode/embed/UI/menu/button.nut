class Goto extends ::UI.Menu.Struct.Label {
    destination = null;
    
    constructor (it, s, pg) {
        base.constructor(it, s);
        destination = pg;
    }
    
    function OnClick() {
        ::menu.help.Reset();
        destination.Initialize();
    }
};

class Exit extends ::UI.Menu.Struct.Label {
    function OnClick() {
        ::loop.End();
    }
};
