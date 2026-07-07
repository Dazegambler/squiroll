config = {
    p1 = {
        enabled = false
        x = 0
        y = 185
        sx = 0.6
        sy = 0.6
        red = 0.0
        green = 1.0
        blue = 0.0
        alpha = 1.0
        count = 13
        timer = 200
    }
    p2 = {
        enabled = false
        x = 1280
        y = 185
        sx = 0.6
        sy = 0.6
        red = 0.0
        green = 1.0
        blue = 0.0
        alpha = 1.0
        count = 13
        timer = 200
    }
};

::plugin.Patch("squiroll/config/mod_config.nut",function() {
    //page.extend([
    //    ::UI.Menu.Page(
    //        ::UI.Menu.Title("input display(P1)"),
    //        ::UI.Menu.Config.Boolean(0,"enabled","input_display","p1","enabled",this),
    //        ::UI.Menu.Config.Value(1,"x","input_display","p1","x",this),
    //        ::UI.Menu.Config.Value(2,"y","input_display","p1","y",this),
    //        ::UI.Menu.Config.Value(3,"scale(x)","input_display","p1","sx",this),
    //        ::UI.Menu.Config.Value(4,"scale(y)","input_display","p1","sy",this),
    //        ::UI.Menu.Config.Value(5,"red","input_display","p1","red",this),
    //        ::UI.Menu.Config.Value(6,"green","input_display","p1","green",this),
    //        ::UI.Menu.Config.Value(7,"blue","input_display","p1","blue",this),
    //        ::UI.Menu.Config.Value(8,"alpha","input_display","p1","alpha",this),
    //        ::UI.Menu.Config.Value(9,"count","input_display","p1","count",this),
    //        ::UI.Menu.Config.Value(10,"timer","input_display","p1","timer",this)
    //    ),
    //    ::UI.Menu.Page(
    //        ::UI.Menu.Title("input display(P2)"),
    //        ::UI.Menu.Config.Boolean(0,"enabled","input_display","p2","enabled",this),
    //        ::UI.Menu.Config.Value(1,"x","input_display","p2","x",this),
    //        ::UI.Menu.Config.Value(2,"y","input_display","p2","y",this),
    //        ::UI.Menu.Config.Value(3,"scale(x)","input_display","p2","sx",this),
    //        ::UI.Menu.Config.Value(4,"scale(y)","input_display","p2","sy",this),
    //        ::UI.Menu.Config.Value(5,"red","input_display","p2","red",this),
    //        ::UI.Menu.Config.Value(6,"green","input_display","p2","green",this),
    //        ::UI.Menu.Config.Value(7,"blue","input_display","p2","blue",this),
    //        ::UI.Menu.Config.Value(8,"alpha","input_display","p2","alpha",this),
    //        ::UI.Menu.Config.Value(9,"count","input_display","p2","count",this),
    //        ::UI.Menu.Config.Value(10,"timer","input_display","p2","timer",this)
    //    )
    //]);
});
local display = class {
    player = null;
    data = null;
    text = null;
    config = null;

    constructor(idx) {
        player = idx;
        data = [];
        config = ::plugin.cfg.input_display.data["p"+(player+1)];
        text = ::UI.Text();
        text.ConnectRenderSlot(::graphics.slot.status,1);
    }
    
    function poll() {
        local team = ::battle.team[player];
        local input = team.input;
        local direction = 5 + (::math.clamp(input.x,-1,1) * team.current.direction) + (::math.clamp(input.y,-1,1) * 3 * -1);
        local sum = 
            ((input.b0 > 0).tointeger()) |//A
            ((input.b1 > 0).tointeger() << 1) |//B
            ((input.b2 > 0).tointeger() << 2) |//C
            ((input.b3 > 0).tointeger() << 3) |//E
            ((input.b4 > 0).tointeger() << 4) |//D
            (1 << 4 + direction.tointeger());
        return sum;
    }

    function Render() {
        local str = "";
        foreach (input in data) {
            local dir = -1;
            local c = 0;
            while (dir < 0) {
                if (input[0] & (1 << 5 + c))dir = c + 1;
                c++;
            }
            local sub_str = [
                ::format("[%d]",::math.min(input[1],99)),
                ::format("%d",dir)
            ];
            
            foreach (i,s in ["A","B","C","E","D"]) {
                if (input[0] & (1 << i))sub_str[1] += s; 
            }
            
            if (player)sub_str.reverse();
            str += ::format("%s%s\\n\\n",sub_str[0],sub_str[1]); 
        }
        text.Set(str);
        text.red = config.red;
        text.green = config.green;
        text.blue = config.blue;
        text.alpha = config.alpha;
        text.y = config.y;
        text.sy = config.sy;
        text.sx = ::math.fclamp(text.sx,0.1,config.sx);
        text.x = config.x - ((text.sx * text.width) * player);
    }

    function Update() {
        if (config.enabled) {
            local new = poll();
            if (!data.len() || new != data[0][0])data.insert(0,[new,0]);
            else if (++data[0][1] > config.timer)data = [];
            while(data.len() > config.count)data.pop();
        }else data = [];
        Render();
    }
};

class modifier extends modifier {
    list = [null,null];

    constructor() {
        if (::network.IsPlaying()) {
            local idx = ::network.is_parent_vs.tointeger();
            list[idx] = display(idx);
        }else {
            list[0] = display(0);
            list[1] = display(1);
        }
    }

    function Update() {
        if (::network.IsPlaying()) {
            list[::network.is_parent_vs.tointeger()].Update();
        }else {
            list[0].Update();
            list[1].Update();
        }
    }

    function Release() {
        list = null;
    }

	function Enabled(param) {
		return true;
	}
};
