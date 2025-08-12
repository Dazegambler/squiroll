function strongref(_src, _key) {
    return {
        src = _src
        key = _key
        function get() {
            return this.src[this.key];
        }
        function set(value) {
            return this.src[this.key] <- value;
        }
    };
}

function TextObj(str) {
    return {
        text = null
        calc_x = null
        text_max_length = 0
        x = 0
        str = str

        function Initialize(font = ::font.system) {
            this.text = ::manbow.String();
            this.text.Initialize(font);
            this.text.SetSpace(-5, 0);
            this.text.SetOutline(true);
            this.text.Set("");
            this.text.outline_threshold = 0.16;
            this.text.outline_scale = 6.0;
            return this;
        }

        function Update() {
            this.text.Set(this.str.get());
            this.calc_x();
            // this.text.sx = ::math.min(1, this.text_max_length / this.text.width);
            // this.text.x = this.x - ((this.text.width * this.text.sx) / 2);
        }

        function SetWorldTransform(mat_world) {
            this.text.SetWorldTransform(mat_world);
        }

        function ConnectRenderSlot(slot, priority) {
            this.text.ConnectRenderSlot(slot, priority);
        }

        function Add() {
        }

        function Set(str) {
            this.str.set(str);
            // this.text.Set(this.str.get());
        }

        function SetOutline(enabled) {
            this.text.SetOutline(enabled);
        }

        function SetGradation(enabled) {
            this.text.SetGradation(enabled);
        }

        function SetVertical() {
        }

        function SetSpace(x, y) {
            this.text.SetSpace(x, y);
        }

        }.setdelegate({
        _get = function(idx) {
            return this.text[idx];
        }

        _set = function(idx,val) {
            this.text[idx] = val;
            return val;
        }
    }).Initialize();
}

function CreateText(type,str,SY,SX,red,green,blue,alpha,slot,priority,Update = function(){},init = function(root){}){
    local obj = {};
    switch (type){
        case 3:
            obj.text <- ::font.CreateSpellString(str,red,green,blue);
            break;
        case 2:
            obj.text <- ::font.CreateSubtitleString(str);
                break;
        case 1:
            obj.text <- ::font.CreateSystemStringSmall(str);
            break;
        default:
            obj.text <- ::font.CreateSystemString(str);
            break;
    }
	obj.text.sx = SX;
	obj.text.sy = SY;
	obj.text.red = red;
	obj.text.green = green;
	obj.text.blue = blue;
	obj.text.alpha = alpha;
	obj.text.ConnectRenderSlot(slot, priority);
    obj.Update <- Update;
    obj.setdelegate({
        _get = function(idx) {
            return this.text[idx];
        }

        _set = function(idx,val) {
            this.text[idx] = val;
            return val;
        }
    });
    init(obj);
    return obj;
}

function EnumSelector (val,values) {
    return {
        value = val
        value_table = values
        text = ::font.CreateSystemString("")
        cursor = null
        visible = true
        x = 0
        y = 0
        left = 0
        top = 0
        right = 0
        bottom = 0

        function Show() {
            this.text.visible = true;
        }

        function Hide() {
            this.text.visible = false;
        }

        function Update() {
            if (!this.cursor.active)this.cursor.val = this.value.get().tointeger();
            this.text.Set(value_table[this.cursor.val]);
            this.text.visible = this.visible;
            this.text.x = this.x;
            this.text.y = this.y;
        }

        function SetWorldTransform(mat_world) {
            this.text.SetWorldTransform(mat_world);
        }
    };
}

function Title(str) {
    return [function (page, index) {
            local obj = [::font.CreateSystemString(str)];

            obj[0].ConnectRenderSlot(::graphics.slot.front,0);
            obj[0].sx = obj[0].sy = 1.75;
            obj[0].SetGradation(true);
            obj[0].red2 = 1.0;
            obj[0].green2 = 0.75
            obj[0].blue2 = 0.83;
            obj[0].red = obj[0].green = obj[0].blue = 2.0;
            obj[0].x = this.title_x - ((obj[0].width * obj[0].sx) / 2);
            obj[0].y = this.title_y - (obj[0].height * obj[0].sy);
            obj[0].Set(str);

            page.item.append(obj);
        },
        function (...){}
    ];
}

function Text(str) {
    return [function (page, index) {
        local obj = [::font.CreateSystemString(str)];
        obj[0].ConnectRenderSlot(::graphics.slot.front,0);
        obj[0].y = this.item_y + index * this.item_margin - 34;
        obj[0].sx = ::math.min(1, (this.item_max_length*2) / obj[0].width);
        obj[0].x = this.item_x;

        page.item.push(obj);
        },
        function(...){}
    ];
}

function Button(str,onclick) {
    return [function (page, index) {
        local obj = [::font.CreateSystemString(str)];
        obj[0].ConnectRenderSlot(::graphics.slot.front,0);
        obj[0].y = this.item_y + index * this.item_margin - 34;
        obj[0].sx = ::math.min(1, this.item_max_length / obj[0].width);
        obj[0].x = this.item_x;

        page.item.push(obj);
        },
        onclick
    ];
}

function Enum(str,_value,onedit,options = ["disabled","enabled"]) {
    local value = this.strongref(_value[0],_value[1]);
    return [function (page, index) {
        local obj = [::font.CreateSystemString(str),::UI.EnumSelector(value,options)];
        obj[0].ConnectRenderSlot(::graphics.slot.front,0);
        obj[0].y = this.item_y + index * this.item_margin - 34;
        obj[0].sx = ::math.min(1, this.item_max_length / obj[0].width);
        obj[0].x = this.item_x;

        obj[1].text.blue = 0;
        obj[1].text.ConnectRenderSlot(::graphics.slot.front,0);
        local w = 0;
        local h = 0;
        foreach (val in options) {
            obj[1].text.Set(val);
            if (obj[1].text.width > w)w = obj[1].text.width;
            if (obj[1].text.height > h)h = obj[1].text.height;
        }

        obj[1].x = ::graphics.width - this.item_x - (w * obj[1].text.sx);
        obj[1].y = this.item_y + index * this.item_margin - 34;

        obj[1].left = obj[1].x - 8;
        obj[1].right = obj[1].x + w + 8;
        obj[1].top = obj[1].y + 10;
        obj[1].bottom = obj[1].top + h + 3;
        obj[1].cursor = this.Cursor(1, options.len(),::input_all);
        // local val = value.get();
        // if (typeof val == "bool") {
        //     obj[1].cursor.val = val ? 1 : 0;
        // }else if (typeof val == "integer") {
        //     obj[1].cursor.val = val % options.len();
        // }

        page.item.push(obj);
        },
        onedit
    ];
}

function ValueField(str,_value,onedit = function(...){}) {
    local value = this.strongref(_value[0],_value[1]);
    return[function (page, index) {
        local obj = [::font.CreateSystemString(str), ::UI.TextObj(value)];
        obj[0].ConnectRenderSlot(::graphics.slot.front,0);
        obj[0].y = this.item_y + index * this.item_margin - 34;
        obj[0].sx = ::math.min(1, this.item_max_length / obj[0].width);
        obj[0].x = this.item_x;

        obj[1].blue = 0;
        obj[1].ConnectRenderSlot(::graphics.slot.front,0);
        obj[1].y = this.item_y + index * this.item_margin - 34;
        local max_length = this.item_max_length;
        local x = this.item_x;
        obj[1].calc_x = function () {
            this.text.sx = ::math.min(1, max_length / this.text.width);
            this.text.x = ::graphics.width - x - (this.text.width * this.text.sx);
        };
        // obj[1].sx = ::math.min(1, this.item_max_length / obj[1].width);
        // obj[1].x = ::graphics.width - this.item_x - (obj[1].width * obj[1].sx);

        page.item.push(obj);
    },
    onedit
    ];
}

function Page(...) {
    return function () {
        this.anime.data.push([]);
        this.proc.push([]);
        foreach (elem in vargv) {
            this.anime.data.top().push(elem[0]);
            this.proc.top().push(elem[1]);
        }
    };
}

function Menu(...) {
    this.help <- ["B1","ok",null,"B2","return",null,"UD","select"];
    this.help_item <- ["B1","ok",null,"B2","cancel",null,"LR","change"];
    this.Update <- null;

    this.common_cursor <- null;
    this.common_callback_ok <- null;
    this.common_callback_cancel <- null;

    this.proc <- [];
    this.anime <- {
        data = []
        title_x = 640
        title_y = 96
        item_x = 320
        item_y = 200
        item_space = 20
        item_margin = 42
        item_max_length = 288
        highlight = this.UIItemHighlight()

        function Initialize() {
            // this.select_obj <- {};
            this.pager <- this.UIPager();
            this.page <- [];
            foreach (i,pag in this.data) {
                local p = {};
                p.x <- 0;
                p.y <- 0;
                p.visible <- true;
                this.page.append(p);
                local ui = this.UIBase();
                ui.target = p.weakref();
                this.pager.Append(ui);
                p.item <- [];

                foreach(i,elem in pag)elem(p,i);
            }
            this.pager.Activate(0);
            ::loop.AddTask(this);
        }

        function Update(){
            this.pager.Set(this.action.cursor_page.val);
            local mat = ::manbow.Matrix();

            foreach( p, _page in this.page )
            {
                mat.SetTranslation(_page.x, 0, 0);

                foreach( i, item in _page.item )
                {
                    foreach( obj in item )
                    {
                        obj.visible = _page.visible;

                        if (obj.visible)obj.SetWorldTransform(mat);
                        if ("Update" in obj)obj.Update();
                    }
                }
            }
            local t = this.page[this.action.cursor_page.val].item[this.action.cursor_index.val][0];
            ::menu.cursor.SetTarget(t.x - 20, t.y + 23, 0.69999999);
        }


        function Terminate() {
            ::loop.DeleteTask(this);
            this.pager = null;
            this.page = null;
            // this.select_obj = null;
        }
    };
    this.anime.action <- this.weakref();

    function Initialize() {
        this.cursor_index <- this.Cursor(0, this.anime.data[0].len() - 1,::input_all);
        this.cursor_index.se_ok = 0;

        this.cursor_page <- this.Cursor(1, this.anime.data.len(), ::input_all);
        this.cursor_page.enable_ok = false;
        this.cursor_page.enable_cancel = false;

        ::menu.cursor.Activate();
        ::menu.back.Activate();
        ::menu.help.Set(this.help);
        this.Update = this.UpdateMain;
        this.BeginAnime();
        ::loop.Begin(this);
    }

    function Terminate() {
        this.EndAnime();
        ::menu.back.Deactivate(true);
        ::menu.cursor.Deactivate();
        ::menu.help.Reset();
    }

    function UpdateCommonItem() {
        this.common_cursor.Update();
        if (this.common_cursor.ok) {
            this.common_callback_ok();
            this.Update = this.UpdateMain;
        } else if (this.common_cursor.cancel) {
            this.common_callback_cancel();
            this.Update = this.UpdateMain;
        }
    }

    function UpdateMain() {
        ::menu.help.Set(this.help);
        this.cursor_page.Update();

        if (this.cursor_page.diff) {
            local prev = this.cursor_index.val;
            this.cursor_index <- this.Cursor(0, this.anime.data[this.cursor_page.val].len() - 1, ::input_all);
            this.cursor_index.se_ok = 0;
            this.cursor_index.val = this.cursor_index.item_num <= prev ? this.cursor_index.item_num - 1 : prev;
        }

        this.cursor_index.Update();

        if (this.cursor_index.diff && !this.anime.page[this.cursor_page.val].item[this.cursor_index.val][0].width) {
            this.cursor_index.val = ::math.min(this.cursor_index.item_num - 1, this.cursor_index.val + this.cursor_index.diff);
        }
        if (this.cursor_index.ok){
            local item = this.anime.page[this.cursor_page.val].item[this.cursor_index.val];
            this.proc[this.cursor_page.val][this.cursor_index.val].call(this,item);
        }else if (this.cursor_index.cancel){
            ::loop.End();
        }
    }
    foreach (elem in vargv)elem.call(this);
}