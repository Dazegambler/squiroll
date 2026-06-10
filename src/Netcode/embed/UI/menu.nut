// CORE ELEMENTS
class Entry {
    elem = null;
    visible = null;

    constructor(elems) {
        visible = false;
        elem = elems;
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
    constructor(s) {
        base.constructor({
            label = ::UI.Core.Text({
                str = s
                max_length = 576
                sx = 1.75
                sy = 1.75
                x = 640
                y = 96
            })
        });
        elem.label.x -= ((elem.label.width * elem.label.sx) / 2);
        elem.label.y -= (elem.label.height * elem.label.sy);
    }
};

class Header extends Entry {
    constructor(idx,s) {
        base.constructor({
            label = ::UI.Core.Text({
                str = s
                max_length = 576
                x = 640
                y = 166 + (idx * 42)
            })
        });
        elem.label.x -= ((elem.label.width * elem.label.sx) / 2);
    }
};

// LOGICAL ELEMENTS
class Value extends Entry {
    constructor(idx,s,v) {
        base.constructor({
            label = ::UI.Core.Text({
                str = s
                max_length = 576
                x = 320
                y = 166 + (idx * 42)
            }),
            val = ::UI.Core.Text({
                str = v
                x = ::graphics.width - 320
                dx = @()(::graphics.width - 320 - (width * sx))
                y = 166 + (idx * 42)
            })
        });
    }
};

class Enum extends Entry {
    constructor(idx,s,v,opts) {
        base.constructor({
            label = ::UI.Core.Text({
                str = s
                max_length = 576
                x = 320
                y = 166 + (idx * 42)
            }),
            val = ::UI.Core.Enum({
                values = opts
                cursor = this.Cursor(1,opts.len(),::input_all)
                x = ::graphics.width - 320
                y = 166 + (idx * 42)
                blue = 0
            })
        });
        local w = 0;
        local h = 0;
        foreach (str in opts) {
            elem.val.Set(str);
            if (elem.val.width > w)w = elem.val.width;
            if (elem.val.height > h)h = elem.val.height;
        }

        elem.val.x -= (w * elem.val.sx);
        elem.val.left = elem.val.x - 8;
        elem.val.right = elem.val.x + w + 8;
        elem.val.top = elem.val.y + 10;
        elem.val.bottom = elem.val.top + h + 3;
        elem.val.cursor.val = v;
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
Config <- {};
::manbow.CompileFile("squiroll/UI/config.nut",Config);
