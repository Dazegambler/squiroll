class ptr {
	Get = null;
	Set = null;
	constructor(get,set = null){
		Get = get;
		Set = set;
	}
}

class tableptr{
    __ref = null;
    __keys = null;
    constructor(table){
        __ref = table;
    }
    function _get(key)return __ref.rawget(key);
    function _set(key,value)return __ref.rawset(key,value);
    // function _nexti(prev){
    //     if(!__keys)__keys = __ref.keys();
    //     local i = 0;
    //     if(prev)i = __keys.find(prev) + 1;
    //     if(i < __keys.len())return __keys[i];
    //     __keys = null;
    //     return null;
    // }
}

function CreateText(type,str,SY,SX,red,green,blue,alpha,slot,priority,Update = null,init = null){
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
    if(init != null)init(obj);
    obj.Update <- Update;
    return obj;
}

function CreateTextA(type,str,SY,SX,red,green,blue,alpha,slot,priority){
    local obj = null;
    switch (type){
        case 3:
            obj = ::font.CreateSpellString(str,red,green,blue);
            break;
        case 2:
            obj = ::font.CreateSubtitleString(str);
                break;
        case 1:
            obj = ::font.CreateSystemStringSmall(str);
            break;
        default:
            obj = ::font.CreateSystemString(str);
            break;
    }
	obj.sx = SX;
	obj.sy = SY;
	obj.red = red;
	obj.green = green;
	obj.blue = blue;
	obj.alpha = alpha;
	obj.ConnectRenderSlot(slot, priority);
    return obj;
}

// function FilterTable(table,expr){
//     local tb = {};
//     foreach(k,v in table.Get()){
//         if(expr(k,v))continue;
//         tb[k] <- tableptr(table.Get(),k);
//     }
//     return tb;
// }

// {
//     text;
//     value;
//     cursor;
//     section;
//     config_section;
//     key;
// }

function ToConfigMenuPage(section,table,config_table,text_table = null,order = null){
    local function iterate(section,table,config_table,text_table,order){
        local arr = [];
        for(local i = 0; i <= table.len(); ++i)arr.append(null);
        foreach(k,v in table){
            if (typeof(v) != "bool" &&
                typeof(v) != "integer" &&
                typeof(v) != "string" &&
                typeof(v) != "float"){
                continue;
	        }
            local obj = {};
            obj.config <- {
                section = section[1];
                key = config_table[k];
            };
            obj.section <- section[0];
            obj.text <- text_table && k in text_table ? text_table[k] : k;
            obj.table <- table;
            obj.key <- k;

            if (order){
                arr[order.find(k)] = obj;
            }else{
                arr.append(obj);
            }
        }

        return arr.filter(@(i,v)v != null);
    }
    local arrs = [];

    local elems = iterate(section,table,config_table,text_table,order);

    local pages = [[]];
    local c = 0;

    for(local i = 0; i < elems.len(); ++i){
        pages.top().append(elems[i]);
        c++;
        if(c == 12){
            pages.append([]);
            c = 0;
        }
    }
    return pages;
}

function InitializeConfigMenu(pages){
	//helpers
	this.help <- ["B1","ok",null,"B2","return",null,"UD","select",null,"LR","page"];

    //main objects
    this.Update <- null;
	this.data <- pages;
    this.common_cursor <- null;
    this.common_cursor_ok <- null;
    this.common_cursor_cancel <- null;
    this.anime <- {
        title_x = 640;
        title_y = 96;
        item_x = 320;
        item_y = 200;
        item_space = 20;
        item_margin = 42;
        item_max_length = 288;

        function Initialize(){
            this.pager <- this.UIPager();
            this.page <- [];
            foreach(pg in this.action.data){
                AddPage(pg);
            }
            this.pager.Activate(0);
            this.cur_page <- this.action.cursor_page.val;
            ::loop.AddTask(this);
        }

        function Terminate(){
            ::loop.DeleteTask(this);
            this.pager = null;
            this.page = null;
        }

        function Update(){
            this.pager.Set(this.action.cursor_page.val);
            local mat = ::manbow.Matrix();

            foreach( p, _page in this.page )
            {
                mat.SetTranslation(_page.x, 0, 0);

                foreach( i, _item in _page.item )
                {
                    foreach( obj in _item )
                    {
                        obj.visible = _page.visible;

                        if (obj.visible)
                        {
                            obj.SetWorldTransform(mat);
                        }
                    }
                }
            }
            local t = this.page[this.action.cursor_page.val].item[this.action.cursor_index.val][0];
            ::menu.cursor.SetTarget(t.x - 20, t.y + 23, 0.69999999);
        }

        function AddPage(elems){
            local p = {};
            p.x <- 0;
            p.y <- 0;
            p.visible <- true;
            this.page.append(p);
            local ui = this.UIBase();
            ui.target = p.weakref();
            ui.ox = 0;
            this.pager.Append(ui);
            p.item <- [];
            local w = 0;
            local _w = 0;
            foreach(i,v in elems){
                local obj = [];

                local text = ::font.CreateSystemString(v.text);
                text.ConnectRenderSlot(::graphics.slot.front,0);
                text.y = this.item_y + i * this.item_margin - 34;
                if(text.width*text.sx > this.item_max_length)text.sx = this.item_max_length / text.width;
                text.x = this.item_x;
                obj.push(text);

                local value = ::font.CreateSystemString(v.table[v.key]);
                value.ConnectRenderSlot(::graphics.slot.front,0);
                value.y = text.y;
                if(value.width*value.sx > this.item_max_length)value.sx = this.item_max_length / value.width;
                value.x = ::graphics.width - this.item_x - (value.width * value.sx);
                obj.push(value);

                p.item.push(obj);
            }
            local title = [];
            local section = ::font.CreateSystemString(elems[0].section);
            section.ConnectRenderSlot(::graphics.slot.front,0);
            section.sx = section.sy = 1.5;
            section.red = section.blue = 0;
            section.x = this.title_x - (section.width * section.sx)/2;
            section.y = this.title_y - (section.height * section.sy);
            title.append(section);
            p.item.push(title);
        }
    };
    this.anime.action <- this.weakref();


    //functions
    function Initialize(){
        ::loop.Begin(this);
        this.cursor_index <- this.Cursor(0,this.data[0].len(),::input_all);
        this.cursor_index.se_ok = 0;

        this.cursor_page <- this.Cursor(1, this.data.len(),::input_all);
        this.cursor_page.enable_ok = false;
        this.cursor_page.enable_cancel = false;

        this.cur_index <- -1;
        this.cur_page <- -1;

        ::menu.cursor.Activate();
        ::menu.back.Activate();
        ::menu.help.Set(this.help);
        this.Update = this.UpdateMain;
        this.BeginAnime();
    }

    function Terminate(){
        this.EndAnime();
        ::menu.back.Deactivate(true);
        ::menu.cursor.Deactivate();
        ::menu.help.Reset();
    }

    function UpdateMain()
    {
        this.cursor_page.Update();

        if (this.cursor_page.diff){
            local prev = this.cursor_index.val;
            this.cursor_index <- this.Cursor(0, this.data[this.cursor_page.val].len(), ::input_all);
            this.cursor_index.se_ok = 0;
            this.cursor_index.val = this.cursor_index.item_num <= prev ? this.cursor_index.item_num - 1 : prev;
        }

        this.cursor_index.Update();

        if (this.cursor_index.ok){
            local item = this.data[this.cursor_page.val][this.cursor_index.val];
            local anim = this.anime;
            local value_txt = anim.page[this.cursor_page.val].item[this.cursor_index.val][1];
            ::Dialog(2,item.text,function (ret){
                if (ret){
                    local r = item.table[item.key];
                    switch(typeof(r)){
                        case "bool":
                            r = ret == "true" ? true : false;
                            break;
                        case "integer":
                            r = ret.tointeger();
                            break;
                        case "float":
                            r = ret.tofloat();
                            break;
                    }
                    item.table[item.key] = r;
                    ::setting.save(item.config.section,item.config.key,ret);

                    value_txt.Set(ret);
                    if(value_txt.width*value_txt.sx > anim.item_max_length)value_txt.sx = anim.item_max_length / value_txt.width;
                    value_txt.x = ::graphics.width - anim.item_x - (value_txt.width * value_txt.sx);

                }
            },item.table[item.key].tostring());
            return;
        }
        else if (this.cursor_index.cancel){
            ::loop.End();
        }
    }
}