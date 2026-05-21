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
	max_length = null;

	constructor(str,font = ::font.system,max_len = 288) {
		base.constructor();
        max_length = max_len;
		Initialize(font);
		SetSpace(-5,0);
		SetOutline(true);
		outline_threshold = 0.16;
		outline_scale = 6.0;
		Set(str);
	}

	function Set(val) {
		base.Set(val);
		sx = ::math.fmin(1,max_length / width);
	}
};

//pointer display
class LiveText extends Text {
    ptr = null;
    constructor(p) {
        ptr = p;
        base.constructor(ptr.Get());
        blue = 0;
    }

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

    constructor(idx,table) { 
        values = table;
        base.constructor(values[0]);
        blue = 0;
        cursor = this.Cursor(1, values.len(),::input_all);
    }

    function Update() {
        Set(values[cursor.val]);
        base.Update();
    }
};
