//squirrel lacks pointers so we make our own
//use only with tables,classes and instances
//you can prob use it with arrays but expect jank
::PTR <- class {
    get = null;
    set = null;
    constructor(r,i) {
        get = @()r[k];
        set = @(v)r[k]=v;
    }
};

//tasofro's UI code is too barebones
//so yes we're also reinventing it
class Text extends ::manbow.String {
	str = "";
    max_length = 576;
    font = ::font.system;
    dx = null;
    dy = null;

	constructor(edit = {}) {
		base.constructor();
		foreach(k,v in edit)this[k] = v;
        Initialize(font);
        SetSpace(-5,0);
		SetOutline(true);
		outline_threshold = 0.16;
		outline_scale = 6.0;
		Set(str);
	}

	function Set(val) {
		base.Set(val);
		str = val;
        sx = ::math.fmin(1,max_length / width);
        if(dx)x = dx();
        if(dy)y = dy();
	}
};

//pointer display
class LiveText extends Text {
    ptr = null;

    function Set(val) {
        ptr.set(val);
    }

    function Update() {
        base.Set(ptr.get());
        base.Update();
    }
};

//graphical enum display
class Enum extends Text {
    values = null;
    cursor = null;
    left = 0;
    right = 0;
    bottom = 0;
    top = 0;

    function Update() {
        Set(values[cursor.val]);
        base.Update();
    }
};

class LiveEnum extends Enum {
    ptr = null;

    function Set(val) {
        ptr.set(val);
    }

    function Update() {
        base.Set(ptr.get());
        base.Update();
    }
};

//i've gone insane so now i'm remaking
//every menu i have to mess with
//hardcoded menus are annoying to edit
class Sprite extends ::manbow.Sprite {
    texture = null;
    left = 0;
    top = 0;
    width = 0;
    height = 0;
    constructor(edit = {}) {
        base.constructor();
		foreach(k,v in edit)this[k] = v;
        Initialize(texture,left,top,width,height);
    }

    function FromBase64(base64) {
        texture.CreateFromBase64(base64,width,height);
        Initialize(texture,left,top,width,height);
    }
};
