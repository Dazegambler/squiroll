// CORE ELEMENTS
class Entry {
    elem = null;
    visible = null;

    constructor(idx,str) {
        visible = false;
        elem = {
            label = ::UI.Core.Text(str,::font.system,576)
        };
        elem.label.y = 200 + (idx * 42) - 34;
        elem.label.x = 320;
    }

    function OnClick() {}
  
    function ConnectRenderSlot(slot,priority) {
        foreach (e in elem)e.ConnectRenderSlot(slot,priority);
    }

    function DisconnectRenderSlot() {
        foreach (e in elem)e.DisconnectRenderSlot();
    }

    function SetWorldTransform(mat) {
        foreach (e in elem)e.SetWorldTransform(mat);
    }

    function Update() {
        foreach (e in elem) {
            e.visible = visible;
            e.Update();
        }
    }
};

// STRUCTURE ELEMENTS
class Title extends Entry {
    constructor(str) {
        elem = {
            label = ::UI.Core.Text(str,::font.system,576)
        };
        elem.label.sx = 1.75;
        elem.label.sy = 1.75;
        elem.label.SetGradation(true);
        elem.label.red2 = 1.0;
        elem.label.green2 = 0.75;
        elem.label.blue2 = 0.83;

        elem.label.x = 640 - ((elem.label.width * elem.label.sx) / 2);
        elem.label.y = 96 - (elem.label.height * elem.label.sy);
    }
};

class Header extends Entry {
    constructor(idx,str) {
        elem = {
            label = ::UI.Core.Text(str,::font.system,576)
        };
        elem.label.y = 200 + (idx * 42) - 34;
        elem.label.x = 640 - ((elem.label.width * elem.label.sx) / 2);
    }
};

// LOGICAL ELEMENTS
class Button extends Entry {
    onclick = null;
    constructor(idx,str,on_click) {
        base.constructor(idx,str)
        onclick = on_click;
    }

    function OnClick() {
        onclick();
    }
};

class Value extends Entry {
    ptr = null;
    onclick = null;

    constructor(idx,str,src,on_click) {
        ptr = src;
        onclick = on_click;
        base.constructor(idx,str);
        local val = elem.val <- ::UI.Core.LiveText(ptr);
        val.x = ::graphics.width - 320 - (val.width * val.sx);
        val.y = 200 + (idx * 42) - 34;
    }

    function OnClick() {
        onclick();
    }
};

class Enum extends Entry {
    onclick = null;

    constructor(idx,str,init,on_click,opts = ["disabled","enabled"]) {
        base.constructor(idx,str);
        onclick = on_click;
        local val = elem.val <- ::UI.Core.Enum(idx,opts);
        local w = 0;
        local h = 0;
        foreach (v in opts) {
            val.Set(v);
            if (val.width > w)w = val.width;
            if (val.height > h)h = val.height;
        }

        val.x = ::graphics.width - 320 - (w * val.sx);
        val.y = 200 + (idx * 42) - 34;

        val.left = val.x - 8;
        val.right = val.x + w + 8;
        val.top = val.y + 10;
        val.bottom = val.top + h + 3;
        val.cursor.val = init;
    }

    function OnClick() {
        onclick();
    }
};

class Page {
    uiBase = null;
    item = null;
    visible = null;
    x = null;
    y = null;

    constructor(...) {
        uiBase = UIBase();
        uiBase.target = this;
        visible = false;
        x = 0;
        y = 0;
        item = vargv;
    }

    function ConnectRenderSlot(_slot,priority) {
        foreach (elem in item)elem.ConnectRenderSlot(_slot,priority);
    }

    function DisconnectRenderSlot() {
        foreach (elem in item)elem.DisconnectRenderSlot();
    }

    function Update(mat) {
        mat.SetTranslation(x,0,0);
        foreach (i in item) {
            i.visible = visible;
            i.SetWorldTransform(mat);
            i.Update();
        }
    }
};

function Create(...) {
    help <- ["B1","ok",null,"B2","return",null,"UD","select"];
    help_item <- ["B1","ok",null,"B2","cancel",null,"LR","change"];

    common_cursor <- null;
    common_callback_ok <- null;
    common_callback_cancel <- null;

    anime <- {
        function Initialize() {
            highlight <- UIItemHighlight();
            pager <- UIPager();
            foreach (page in action.page) {
                pager.Append(page.uiBase);   
                page.ConnectRenderSlot(::graphics.slot.front,0);
            }
            pager.Activate(0,-2000);
            ::loop.AddTask(this);
        }

        function Update(){
            pager.Set(action.cursor_page.val);
            local mat = ::manbow.Matrix();
            foreach (p in action.page)p.Update(mat);
            local entry = action.page[action.cursor_page.val].item[action.cursor_index.val].elem.label;
            ::menu.cursor.SetTarget(entry.x - 20, entry.y + 23, 0.7);
        }

        function Terminate() {
            ::loop.DeleteTask(this);
            pager = null;
            highlight = null;
            foreach(page in action.page)page.DisconnectRenderSlot();
        }
    };
    anime.action <- this.weakref();

    function Initialize() {
        cursor_index <- this.Cursor(0, page[0].item.len(),::input_all);
        cursor_index.se_ok = 0;

        cursor_page <- this.Cursor(1, page.len(), ::input_all);
        cursor_page.enable_ok = false;
        cursor_page.enable_cancel = false;
        
        ::menu.cursor.Activate();
        ::menu.back.Activate();
        ::menu.help.Set(help);
        Update <- UpdateMain;
        BeginAnime();
        ::loop.Begin(this);
    }

    function Terminate() {
        EndAnime();
        delete cursor_page;
        delete cursor_index;
        ::menu.back.Deactivate(true);
        ::menu.cursor.Deactivate();
        ::menu.help.Reset();
    }

    function UpdateCommonItem() {
        common_cursor.Update();
        if (common_cursor.ok) {
            common_callback_ok();
            Update = UpdateMain;
        } else if (common_cursor.cancel) {
            common_callback_cancel();
            Update = UpdateMain;
        }
    }

    function UpdateMain() {
        ::menu.help.Set(help);
        
        cursor_page.Update();
        if (cursor_page.diff) {
            local prev = cursor_index.val;
            cursor_index <- this.Cursor(0, page[cursor_page.val].item.len(), ::input_all);
            cursor_index.se_ok = 0;
            cursor_index.val = cursor_index.item_num <= prev ? cursor_index.item_num - 1 : prev;
        }
        
        cursor_index.Update();
        if (cursor_index.ok){
            local item = page[cursor_page.val].item[cursor_index.val];
            item.OnClick();
        }else if (cursor_index.cancel){
            ::loop.End();
        }
    }
    page <- vargv;
}
