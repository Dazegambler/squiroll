Notification <- {
    Left =  class extends ::UI.Popup.Core {
        constructor(init) {
            base.constructor(
                ::graphics.width * 0.18
                ,::graphics.height * 0.08
                ,0.75
                ,0.75
                ,init
            );
        }
    }
    Top =  class extends ::UI.Popup.Core {
        constructor(init) {
            base.constructor(
                ::graphics.width / 2
                ,::graphics.height * 0.08
                ,0.75
                ,0.75
                ,init
            );
        }
    }
    Right =  class extends ::UI.Popup.Core {
        constructor(init) {
            base.constructor(
                ::graphics.width * 0.82
                ,::graphics.height * 0.08
                ,0.75
                ,0.75
                ,init
            );
        }
    }
};

class Dialog extends ::UI.Popup.Core {
    constructor(init) {
        base.constructor(
            ::graphics.width / 2
            ,::graphics.height / 2
            ,1,1
            ,init
        );
    }
};
