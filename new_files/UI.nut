class ptr {
	Get = null;
	Set = null;
	constructor(get,set){
		Get = get;
		Set = set;
	}
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

function ToMenuPage(title,table,text_table = null){
	local arr = [];
	foreach(k,v in table){
		if (typeof(v) != "bool" &&
			typeof(v) != "integer" &&
			typeof(v) != "string" &&
			typeof(v) != "float")continue;
		local obj = {};
        obj.section <- title;
		obj.text <- k in text_table ? text_table[k] : k;
		obj.value <- v;
		arr.append(obj);
	}
	return arr;
}

function InitializeMenu(pages){
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
        item_x = 480;
        item_y = 200;
        item_space = 20;
        item_margin = 42;


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
                local wid = 0;
                local text = ::font.CreateSystemString(v.text);
                text.ConnectRenderSlot(::graphics.slot.front,0);
                text.y = this.item_y + i * this.item_margin - 34;
                wid = text.width + this.item_space;
                obj.push(text);

                local value = ::font.CreateSystemString(v.value);
                value.ConnectRenderSlot(::graphics.slot.front,0);
                value.y = text.y;
                obj.push(value);
                wid += value.width;

                p.item.push(obj);

                if(w < text.width)w = text.width;
                if(_w < wid)_w = wid;
                foreach(i in p.item){
                    i[0].x = (::graphics.width - _w) / 2;
                    i[1].x = i[0].x + w + this.item_space;
                }
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
            // this.cur_item = this.data[this.cursor_page.val][this.cursor_index.val];
            // if (this.cur_item.section in this.proc && this.cur_item.key in this.proc[this.cur_item.section]){
            //     this.proc[this.cur_item.section][this.cur_item.key].call(this);
            // }
            return;
        }
        else if (this.cursor_index.cancel){
            ::loop.End();
        }
    }
}