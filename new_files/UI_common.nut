//TF4's UI code is a mess, i'm making my own modular system for it
class animeBase {
    action = null;
    page = [];
    pager = null;
}

class UIBase {
    elem = [];
    update = null;
    anime = null;
}

class anime extends animeBase {
    constructor(){

    }

    function initialize(){

    }

    function terminate(){
        ::loop.DeleteTask(this);
        this.pager = null;
        this.page = null;
    }

    function update(){
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
    }
}

class UI extends UIBase {
    constructor(_elem/*array*/,_update)
    {
        foreach(page in _elem){
            this.elem.append([]);
            foreach(index,key in page){
                local obj = [];
                this.elem.top().push(obj)
            }
        }
        this.update = _update;
    }

    function initialize(){

    }
}

