local tex = ::manbow.Texture();
tex.Load("data/system/dialog/mini_window.png");
class Sync {
    static TEX = tex;
    data = null;
    obj = null;
    task = null;
    Update = null;

    constructor (x,y,sx,sy,init) {
        Initialize(x,y,sx,sy,init);
    }

    function Initialize(x,y,Sx,Sy,init) {
        ::loop.Begin(this);
        data = {};
        obj = {
            background = ::UI.Sprite({
                texture = TEX
                x = -(TEX.width * Sx) / 2
                y = -(TEX.height * Sy) / 2
                sx = Sx
                sy = Sy
                width = TEX.width
                height = TEX.height
            })
        };
        init.call(this);
        task = ::loop.GeneratorTask();
        task.Set(function(t) {
            foreach (o in obj)o.ConnectRenderSlot(::graphics.slot.front,10000);
            local mat = ::manbow.Matrix();
            for (local i = 0; i < 6; ++i) {
                mat.SetScaling(i/5,i/5,1);
                mat.Translate(x,y,0);
                foreach (o in obj) {
                    o.alpha = i/5;
                    o.SetWorldTransform(mat);
                }
                yield true;
            }
        }(this));
    }

    function Terminate() {
        task.Set(function(t) {
            local mat = ::manbow.Matrix();
            for (local i = 6.0; i > 0; --i) {
                mat.SetScaling(i/5,i/5,1);
                mat.Translate(-2000/i,-2000/i,0);
                foreach (o in obj) {
                    o.alpha = i / 6;
                    o.SetWorldTransform(mat);
                }
                yield true;
            }
        }(this));
    }
}

class Async extends Sync {
    function Initialize(x,y,Sx,Sy,init) {
        ::loop.AddTask(this);
        data = {};
        obj = {
            background = ::UI.Sprite({
                texture = TEX
                x = -(TEX.width * Sx) / 2
                y = -(TEX.height * Sy) / 2
                sx = Sx
                sy = Sy
                width = TEX.width
                height = TEX.height
            })
        };
        init.call(this);
        task = ::loop.GeneratorTask();
        task.Set(function(t) {
            foreach (o in obj)o.ConnectRenderSlot(::graphics.slot.front,10000);
            local mat = ::manbow.Matrix();
            for (local i = 0; i < 6; ++i) {
                mat.SetScaling(i/5,i/5,1);
                mat.Translate(x,y,0);
                foreach (o in obj) {
                    o.alpha = i/5;
                    o.SetWorldTransform(mat);
                }
                yield true;
            }
        }(this));
    } 
}

Utility <- {};
::manbow.CompileFile("squiroll/UI/popup/utility.nut",Utility);
Floating <- {};
::manbow.CompileFile("squiroll/UI/popup/floating.nut",Floating);
