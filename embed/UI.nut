function PtrRef(_src, _key) {
    return {
        src = _src
        key = _key
        function GetVal() {
            return this.src[this.key];
        }
        function SetVal(value) {
            return this.src[this.key] <- value;
        }
    };
}

function TextObj(str) {
    return {
        text = null
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
            this.text.Set(this.str());
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
            this.str = str;
            this.text.Set(this.str());
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

function EnumSelector (values) {
    return {
        active = false
        value_table = values
        text = ::font.CreateSystemString("")
        cursor = null
        highlight = this.UIItemHighlight()
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
            this.text.Set(value_table[this.cursor.val]);
            this.text.visible = this.visible;
            this.text.x = this.x;
            this.text.y = this.y;
            if (this.active = this.cursor.active) {
                this.highlight.Set(this.left,this.top,this.right,this.bottom);
            } else this.highlight.Reset();
        }

        function SetWorldTransform(mat_world) {
            this.text.SetWorldTransform(mat_world);
        }
    };
}

function Title(str) {
    return [function (page, index) {
            local page_name = [::font.CreateSystemString(str)];
            page_name[0].ConnectRenderSlot(::graphics.slot.front,0);
            page_name[0].sx = page_name[0].sy = 1.5;
            page_name[0].red = page_name[0].blue = 0;
            page_name[0].x = this.title_x - ((page_name[0].width * page_name[0].sx) / 2);
            page_name[0].y = this.title_y - (page_name[0].height * page_name[0].sy);

            page.item.append(page_name);
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

function Enum(str,value,onedit,options = ["disabled","enabled"]) {
    return [function (page, index) {
        local obj = [::font.CreateSystemString(str),::UI.EnumSelector(options)];
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
        if (typeof value == "bool") {
            obj[1].cursor.val = value ? 1 : 0;
        }else if (typeof value == "integer") {
            obj[1].cursor.val = value % options.len();
        }

        page.item.push(obj);
        },
        onedit
    ];
}

function ValueField(str,value,onedit = function(...){}) {
    return[function (page, index) {
        local obj = [::font.CreateSystemString(str), ::UI.TextObj(value)];
        obj[0].ConnectRenderSlot(::graphics.slot.front,0);
        obj[0].y = this.item_y + index * this.item_margin - 34;
        obj[0].sx = ::math.min(1, this.item_max_length / obj[0].width);
        obj[0].x = this.item_x;

        obj[1].blue = 0;
        obj[1].ConnectRenderSlot(::graphics.slot.front,0);
        obj[1].y = this.item_y + index * this.item_margin - 34;
        obj[1].sx = ::math.min(1, this.item_max_length / obj[1].width);
        obj[1].x = ::graphics.width - this.item_x - (obj[1].width * obj[1].sx);

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

        function Initialize() {
            this.select_obj <- {};
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
            this.select_obj = null;
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
            this.proc[this.cursor_page.val][this.cursor_index.val].call(this,this.cursor_page.val,this.cursor_index.val);
        }else if (this.cursor_index.cancel){
            ::loop.End();
        }
    }
    foreach (elem in vargv)elem.call(this);
}