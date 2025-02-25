::manbow.compilebuffer("UI.nut", this);

function CreateInput_display(idx,player_config){
    //flag distribution:
    //0x1-A
    //0x2-B
    //0x4-C
    //0x8-E
    //0x10-D
    //0x20-X- 0x200-X+ 4 priority
    //0x40-Y+ 0x400-Y- 8 prioritY
    local input = {
        player = idx;
        data = [[0,0]];
        text = [];
        notation = split(player_config.notation,",");
        timer = player_config.timer; //frames
        size = player_config.list_max;
        pos = [player_config.X,player_config.Y];
        scale = [player_config.SX,player_config.SY];
        offset = player_config.offset;
        frame_count_enabled = player_config.frame_count;

        function getinputs(idx){
            local inputs = 0;
            local team = ::battle.team[(::network.IsPlaying() ? ::network.is_parent_vs : idx == 1) ? 1 : 0];
            local input = team.input;
            local x_axis = team.current.direction > 0 ? input.x : -input.x;
            if (x_axis != 0)inputs = inputs | (x_axis < 0 ? 0x20 : 0x200);
            if (input.y != 0)inputs = inputs | (input.y > 0 ? 0x400 : 0x40);

            if(input.b0)inputs = inputs | 0x1;
            if(input.b1)inputs = inputs | 0x2;
            if(input.b2)inputs = inputs | 0x4;
            if(input.b3)inputs = inputs | 0x8;
            if(input.b4)inputs = inputs | 0x10;
            return inputs;
        }

        function Update () {
            local inputs = [this.getinputs(this.player),0];
            if(this.data[0][0] == inputs[0])inputs[1] = ++this.data[0][1];
            if(!inputs[1]){
                this.data.insert(0,inputs);
                if(this.data.len() > this.size)do{this.data.pop();}while(this.data.len() > this.size);
            }
            if(!this.data[0][0] && this.data[0][1] > this.timer)this.data = [[0,0]];
            for (local i = 0; i < this.text.len(); ++i){
                local str = "";
                if (this.data.len() > 1 && i < this.data.len()){
                    local frames = "";
                    if(this.frame_count_enabled)frames += this.data[i][1] < 100 ? format("[%2d]",this.data[i][1]) : "[99+]";
                    local input_str = "";
                    local direction = this.data[i][0] & 0x660;
                    switch(direction){
                        case 0x20:
                            input_str += this.notation[3];//"4";
                            break;
                        case 0x40:
                            input_str += this.notation[7];//"8";
                            break;
                        case 0x60:
                            input_str += this.notation[6];//"7";
                            break;
                        case 0x200:
                            input_str += this.notation[5];//"6";
                            break;
                        case 0x240:
                            input_str += this.notation[8];//"9";
                            break;
                        case 0x400:
                            input_str += this.notation[1];//"2";
                            break;
                        case 0x420:
                            input_str += this.notation[0];//"1";
                            break;
                        case 0x600:
                            input_str += this.notation[2];//"3";
                            break;
                        default:
                            input_str += this.notation[4];//"5";
                            break;
                    }
                    for( local z = 0; z < 5; ++z){
                        if(this.data[i][0] & 1 << z)input_str += (this.data[i][1] > 12 && z == 1) ? this.notation[14] : this.notation[9+z];
                    }
                    str += format(this.player != 0 ? "%8s%5s" : "%5s%8s",this.player != 0 ? input_str : frames,this.player != 0 ? frames : input_str);
                }
                this.text[i].text.Set(str);
                this.text[i].text.x = this.pos[0] - (this.player > 0 ? this.text[i].text.sx*this.text[i].text.width : 0);
            }
        };
    }
    for (local i = 0; i < input.size; ++i) {
        input.text.append(this.CreateText(
            0,"",
            player_config.SX,player_config.SY,
            player_config.red,player_config.green,player_config.blue,player_config.alpha,
            ::graphics.slot.ui,1
            ,null,
            function (root){
                root.text.x = player_config.X;
                root.text.y = (player_config.Y - (i * player_config.offset));
                root.Set <- function (text) {this.text.Set(text);}
            }
        ));
    }
    return input;
}

