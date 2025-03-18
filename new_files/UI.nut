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

function LoadCSVFromBuffer(src/*filename*/) {
    local item_table = {};
    return item_table;
}