//squirrel lacks pointers so we make our own
//use only with tables,classes and instances
//you can prob use it with arrays but expect jank
class Pointer {
	src = null;
	key = null;

	constructor(s,k) {
		src = s;
		key = k;
	}

	function Get() {
		return src[key];
	}

	function Set(val) {
		return src[key] <- val;
	}
};

//tasofro's UI code is too barebones
//so yes we're also reinventing it
class Text extends ::manbow.String {
	str = "";
    max_length = 288;
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
        ptr.Set(val);
    }

    function Update() {
        base.Set(ptr.Get());
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
