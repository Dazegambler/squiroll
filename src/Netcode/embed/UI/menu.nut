// CORE ELEMENTS
class Entry {
    label = null;
    visible = null;
    x = 0;
    y = 0;

    constructor(idx,str) {
        visible = false;
        label = ::UI.Core.Text(str,::font.system,576);
        label.y = 200 + (idx * 42) - 34;
        label.x = 320;
    }

    function ConnectRenderSlot(slot,priority) {
        label.ConnectRenderSlot(slot,priority);
    }

    function DisconnectRenderSlot() {
        label.DisconnectRenderSlot();
    }

    function OnClick() {}
    function Update() {
        label.Update();
    }
};

// STRUCTURE ELEMENTS
class Title extends Entry {
    constructor(str) {
        label = ::UI.Core.Text(str,::font.system,576);
        label.sx = label.sy = 1.75;
        label.SetGradation(true);
        label.red2 = 1.0;
        label.green2 = 0.75;
        label.blue2 = 0.83;
        label.red = label.green = label.blue = 2.0;
        label.x = 640 - ((label.width * label.sx) / 2);
        label.y = 96 - (label.height * label.sy);
    }
};

class Header extends Entry {
    constructor(idx,str) {
        label = ::UI.Core.Text(str,::font.system,576);
        label.y = 200 + (idx * 42) - 34;
        label.x = 640 - ((label.wdith * label.sx) / 2);
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
    val = null;
    onclick = null;

    constructor(idx,str,src,on_click) {
        ptr = src;
        onclick = on_click;
        base.constructor(idx,str);
        val = ::UI.Core.Pointer(ptr);
        val.x = ::graphics.width - 320 - (val.width * val.sx);
        val.y = 200 + (idx * 42) - 34;
    }

    function Update() {
        label.Update();
        val.Update();
    }

    function OnClick() {
        onclick();
    }
};

class Enum extends Entry {
    ptr = null;
    val = null;
    onclick = null;

    constructor(idx,str,src,on_click,opts = ["disabled","enabled"]) {
        ptr = src;
        base.constructor(idx,str);
        onclick = on_click;
        val = ::UI.Core.Enum(opts);
        local w = 0;
        local h = 0;
        foreach (v in opts) {
            val.Set(v);
            if (val.width > w)w = val.width;
            if (val.height > h)h = val.height;
        }

        val.x = ::graphics.width - 320 - (w * val.sx);
        val.y = 200 + (idx * 42) - 34;

        val.left = x - 8;
        val.right = x + w + 8;
        val.top = y + 10;
        val.bottom = val.top + h + 3;
        val.cursor.val = ptr.Get().tointeger();
    }

    function Update() {
        label.Update();
        val.Update();
    }

    function OnClick() {
        onclick();
    }
};

class Page {
    uiBase = null;
    item = null;
    visible = null;
    slot = null;
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
        foreach (elem in item) {
            elem.ConnectRenderSlot(_slot,priority);
        }
        slot = _slot;
    }

    function DisconnectRenderSlot() {
        foreach (elem in item) {
            elem.DisconnectRenderSlot();
        }
        slot = null;
    }

    function Update(mat) {
        mat.SetTranslation(x,0,0);
        foreach (i in item) {
            i.visible = visible;
            if (i.visible)i.SetWorldTransform(mat);
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
            foreach (page in action.pages) pager.Append(page.uiBase);   
            pager.Activate(0,-2000);
            ::loop.AddTask(this);
        }

        function Update(){
            pager.Set(action.cursor_page.val);
            local mat = ::manbow.Matrix();
            foreach (page in buffer)page.Update(mat);
            local entry = buffer.item[action.cursor_index.val];
            ::menu.cursor.SetTarget(entry.x - 20, entry.y + 23, 0.7);
        }

        function Terminate() {
            ::loop.DeleteTask(this);
            pager = null;
            hightlight = null;
            buffer = null;
        }
    };
    anime.action <- this.weakref();

    function Initialize() {
        UpdateBuffer(0);
        cursor_index <- this.Cursor(0, anime.buffer[1].item.len() - 1,::input_all);
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
        ::menu.back.Deactivate(true);
        ::menu.cursor.Deactivate();
        ::menu.help.Reset();
    }

    function Index(i) {
        local len = page.len();
        return (i % len + len) % len;
    }

    function UpdateBuffer(pivot) {
        anime.buffer <- [
            pages[Index(pivot - 1)],
            pages[Index(pivot)],
            pages[Index(pivot + 1)]
        ];
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
            anime.buffer[1 - cursor_page.diff].DisconnectRenderSlot();
            UpdateBuffer(cursor_page.val);
            anime.buffer[1 + cursor_page.diff].ConnectRenderSlot(::graphics.slot.front,0);

            local prev = cursor_index.val;
            cursor_index <- this.Cursor(0, page[cursor_page.val].item.len() - 1, ::input_all);
            cursor_index.se_ok = 0;
            cursor_index.val = cursor_index.item_num <= prev ? cursor_index.item_num - 1 : prev;
        }

        cursor_index.Update();
        if (cursor_index.diff && !anime.page[cursor_page.val].item[cursor_index.val].width) {
            cursor_index.val = ::math.min(cursor_index.item_num - 1, cursor_index.val + cursor_index.diff);
        }
        if (cursor_index.ok){
            local item = anime.buffer[1].item[cursor_index.val];
            item.OnClick();
        }else if (cursor_index.cancel){
            ::loop.End();
        }
    }
    page <- vargv;
}
