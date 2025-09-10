//flag distribution:
//0x1-A
//0x2-B
//0x4-C
//0x8-E
//0x10-D
//0x20-X- 0x200-X+ 4 priority
//0x40-Y+ 0x400-Y- 8 prioritY
class main extends ::battle.ModifierClass {
    display = class {
        player = null;
        data = null;
        text = null;
        config = null;
        notation = null;

        constructor(idx) {
            player = idx;
            data = [[0,0]];
            text = [];
            config = ::setting.input_display["p"+(player+1)];
            notation = ::split(config.notation,",");

            for (local i = 0; i < config.list_max; ++i) {
                local t = ::font.CreateSystemString("");
                t.x = config.x;
                t.y = config.y - (i * config.offset);
                t.sx = config.sx;
                t.sy = config.sy;
                t.red = config.red;
                t.green = config.green;
                t.blue = config.blue;
                t.alpha = config.alpha;
                t.ConnectRenderSlot(::graphics.slot.status,1);
                text.append(t);
            }
        }

        function getinputs(){
            local inputs = 0;
            local team = ::battle.team[player];
            local input = team.input;
            local x_axis = team.current.direction > 0 ? input.x : -input.x;
            if (x_axis)inputs = inputs | (x_axis < 0 ? 0x20 : 0x200);
            if (input.y)inputs = inputs | (input.y > 0 ? 0x400 : 0x40);

            if(input.b0)inputs = inputs | 0x1;
            if(input.b1)inputs = inputs | 0x2;
            if(input.b2)inputs = inputs | 0x4;
            if(input.b3)inputs = inputs | 0x8;
            if(input.b4)inputs = inputs | 0x10;
            return inputs;
        }

        function parse_directional(direction) {
            local str = notation[4];//5
            if(direction) {
                if(direction == 0x20)str = notation[3];//4
                if(direction == 0x40)str = notation[7];//8
                if(direction == 0x60)str = notation[6];//7
                if(direction == 0x200)str = notation[5];//6
                if(direction == 0x240)str = notation[8];//9
                if(direction == 0x400)str = notation[1];//2
                if(direction == 0x420)str = notation[0];//1
                if(direction == 0x600)str = notation[2];//3
            }
            return str;
        }

        function parse_move(flag,duration) {
            local str = "";
            if(flag & 0x1)str += notation[9];//A
            if(flag & 0x2)str += duration > 12 ? notation[14]/*[B]*/ : notation[10];//B
            if(flag & 0x4)str += notation[11];//C
            if(flag & 0x8)str += notation[12];//E
            if(flag & 0x10)str += notation[13];//D
            return str;
        }

        function Render() {
            foreach (i,_ in text) {
                local str = "";
                if (data.len() > 1 && i < data.len()){
                    local frames = "";
                    local duration = ::math.clamp(data[i][1],0,99);
                    if(config.frame_count)frames += ::format("[%s%d%s]", duration < 10 ? "0" : "", duration, duration == 99 ? "+" : "");
                    local input_str = "";
                    local flag = data[i][0];
                    input_str += parse_directional(flag & 0x660);
                    input_str += parse_move(flag & 0x1F,duration);
                    local str_struct = ["%s","%s"];
                    local str_args = [input_str,input_str];
                    str_struct[player] = "%5s";
                    str_args[player] = frames;
                    str = ::format((str_struct[0]+str_struct[1]),str_args[0],str_args[1]);
                }
                _.Set(str);
                _.x = config.x - ((_.sx*_.width) * player);
            }
        }

        function Update () {
            if (config.enabled) {
                local inputs = getinputs();
                local last = data[0][0];
                if(last != inputs)data.insert(0,[inputs,0]);
                else {
                    if (++data[0][1] > config.timer)data = [[0,0]];
                }
                while(data.len() > config.list_max)data.pop();
            }else data = [[0,0]];
            Render();
        }
    };

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
};
::battle.modifiers.input_display <- ::battle.Modifier(main,false,function (param) {
    ::setting.input_display.update_consts();
    return true;//::setting.input_display.p1.enabled || ::setting.input_display.p2.enabled;
});

