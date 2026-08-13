left <- 300;
right <- ::graphics.width - left;
center <- ::graphics.width / 2;
item_y <- 166;
title_y <- 96;
spacing <- 42;
width <- 548;

// CORE ELEMENTS
class Entry {
    visible = false;
    lock = false;
    idx = 0;
    target = null;
    elem = null;
    item_table = null;

    constructor(it) {
        item_table = it;
    }

    function OnClick() {}
    function Enable() {}
    function Disable() {}
    function Initialize() {}

    function Release() {
        foreach (e in elem)if("Release" in e)e.Release();
        elem = null;
    }

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

class Mutex {
    entries = null;
    constructor(...) {
        entries = vargv;
    }

    function Lock() {
        foreach (entry in entries) {
            entry.Disable();
        }
    }

    function Unlock() {
        foreach (entry in entries) {
            entry.Enable();
        }
    }
}

class Page {
    visible = false;
    state = 0;
    x = 0;
    y = 0;
    item = [];
    uiBase = null;

    constructor(...) {
        uiBase = UIBase();
        uiBase.target = this;
        item = vargv;
    }

    function Release() {
        foreach (e in item)e.Release();
    }

    function Initialize() {
        foreach (e in item)e.Initialize();
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
    common_cursor <- null;
    common_callback_ok <- null;
    common_callback_cancel <- null;
    is_suspend <- false;

    anime <- {
        function Initialize() {
            highlight <- UIItemHighlight();
            pager <- UIPager();
            foreach (page in action.page) {
                page.Initialize();
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
            foreach(p in action.page)p.Release();
            ::loop.DeleteTask(this);
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
        Update <- UpdateMain;
        BeginAnime();
        ::loop.Begin(this);
    }

    function Terminate() {
        ::menu.help.Reset();
        ::menu.back.Deactivate();
        ::menu.cursor.Deactivate();
        anime.pager.Deactivate(-1);
        EndAnimeDelayed();
        Update = null;
    }

    function Suspend() {
        ::loop.End(this);
        is_suspend = true;
        ::menu.help.Reset();
        ::menu.cursor.Deactivate();
        ::menu.back.Deactivate(true);
        ::effect.Clear();
        EndAnime();
    }

    function Resume() {
        if (!is_suspend)return;

        is_suspend = false;
        ::sound.PlayBGM(::savedata.GetTitleBGMID());
        if (::network.return_code == 0)::dialog(0, ::menu.common.GetMessageText("disconnect"));

        ::network.Terminate();
        Update = UpdateMain;
        ::menu.cursor.Activate();
        ::menu.back.Activate();
        BeginAnime();
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
            local p = page[cursor_page.val];
            local item = p.item[cursor_index.val];
            ::sound.PlaySE("sys_ok");
            item.OnClick();
        }else if (cursor_index.cancel){
            ::loop.End();
        }
    }
    
    function Add(...) {
        page.extend(vargv);
        foreach (p in page) {
            foreach (i,e in p.item) {
                e.target = this;
                e.idx = i - 1;
            }
        }
    }

    page <- vargv;
    foreach (p in page) {
        foreach (i,e in p.item) {
            e.target = this;
            e.idx = i - 1;
        }
    }
}
//OBJECTS
Struct <- {};
::manbow.CompileFile("squiroll/UI/menu/struct.nut",Struct);
Value <- {};
::manbow.CompileFile("squiroll/UI/menu/value.nut",Value);
Enum <- {};
::manbow.CompileFile("squiroll/UI/menu/enum.nut",Enum);
Button <- {};
::manbow.CompileFile("squiroll/UI/menu/button.nut",Button);
//MENU TYPES
Config <- {};
::manbow.CompileFile("squiroll/UI/menu/config.nut",Config);
