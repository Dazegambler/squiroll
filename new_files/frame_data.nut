::manbow.compilebuffer("UI.nut", this);
function CreateFlag_state_Display () {
    local obj = this.CreateText(
        0,"",
        ::setting.frame_data.SX,
        ::setting.frame_data.SY,
        ::setting.frame_data.red,
        ::setting.frame_data.green,
        ::setting.frame_data.blue,
        ::setting.frame_data.alpha,
        ::graphics.slot.status,1,
        null,
        function (root) {
            root.str <- "";
            root.render <- function (data) {
                local flags = "";
                if (data & 0x1) flags += "no input,"; // 1
                if (data & 0x2) flags += "2,"; // 2
                if (data & 0x4) flags += "4,"; // 4
                if (data & 0x8) flags += "8,"; // 8
                if (data & 0x10) flags += "block,"; // 16
                if (data & 0x20) flags += "normal cancel,"; // 32
                if (data & 0x40) flags += "64,"; // 64
                if (data & 0x80) flags += "128,"; // 128
                if (data & 0x100) flags += "can be counter hit,"; // 256
                if (data & 0x200) flags += "can dial,"; // 512
                if (data & 0x400) flags += "bullet whiff,"; // 1024
                if (data & 0x800) flags += "attack block,"; // 2048
                if (data & 0x1000) flags += "graze,"; // 4096
                if (data & 0x2000) flags += "no grab,"; // 8192
                if (data & 0x4000) flags += "dash cancel,"; // 16384
                if (data & 0x8000) flags += "melee immune,"; // 32768
                if (data & 0x10000) flags += "bullet immune,"; // 65536
                if (data & 0x20000) flags += "131072,"; // 131072
                if (data & 0x40000) flags += "262144,"; // 262144
                if (data & 0x80000) flags += "counter on melee,"; // 524288
                if (data & 0x100000) flags += "1048576,"; // 1048576
                if (data & 0x200000) flags += "knock check,"; // 2097152
                if (data & 0x400000) flags += "counter on bullet,"; // 4194304
                if (data & 0x800000) flags += "8388608,"; // 8388608
                if (data & 0x1000000) flags += "no landing,"; // 16777216
                if (data & 0x2000000) flags += "33554432,"; // 33554432
                if (data & 0x4000000) flags += "67108864,"; // 67108864
                if (data & 0x8000000) flags += "134217728,"; // 134217728
                if (data & 0x10000000) flags += "268435456,"; // 268435456
                if (data & 0x20000000) flags += "536870912,"; // 536870912
                if (data & 0x40000000) flags += "1073741824,"; // 1073741824
                if (data & 0x80000000) flags += "invisible,"; // 2147483648
                if(flags != "")flags = flags.slice(0, -1); // Slice removes the trailing comma

                if (this.str != flags) {
                    this.str = flags;
                    this.text.Set(flags != "" ? format("flagState:[%s]", flags) : flags);
                    this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
                    this.text.y = ::setting.frame_data.Y;
                }
            };
        }
	);
    return obj;
}
function CreateFlag_attack_Display () {
    local obj = this.CreateText(
        0,"",
        ::setting.frame_data.SX,
        ::setting.frame_data.SY,
        ::setting.frame_data.red,
        ::setting.frame_data.green,
        ::setting.frame_data.blue,
        ::setting.frame_data.alpha,
        ::graphics.slot.status,1,
        null,
        function (root) {
            root.str <- "";
            root.render <- function (data) {
                local flags = "";
                if (data & 0x1) flags += "1,"; // 1
                if (data & 0x2) flags += "can be blocked,"; // 2
                if (data & 0x4) flags += "can be blocked,"; // 4
                if (data & 0x8) flags += "8,"; // 8
                if (data & 0x10) flags += "is grab,"; // 16
                if (data & 0x20) flags += "32,"; // 32
                if (data & 0x40) flags += "forced counter,"; // 64
                if (data & 0x80) flags += "can counter,"; // 128
                if (data & 0x100) flags += "forced min rate,"; // 256
                if (data & 0x200) flags += "spellcard,"; // 512
                if (data & 0x400) flags += "1024,"; // 1024
                if (data & 0x800) flags += "melee?,"; // 2048
                if (data & 0x1000) flags += "projectile?,"; // 4096
                if (data & 0x2000) flags += "8192,"; // 8192
                if (data & 0x4000) flags += "16384,"; // 16384
                if (data & 0x8000) flags += "32768,"; // 32768
                if (data & 0x10000) flags += "ungrazeable,"; // 65536
                if (data & 0x20000) flags += "131072,"; // 131072
                if (data & 0x40000) flags += "262144,"; // 262144
                if (data & 0x80000) flags += "instant crush,"; // 524288
                if (data & 0x100000) flags += "no KO,"; // 1048576
                if (data & 0x200000) flags += "forced knock check/fixed juggle,"; // 2097152
                if (data & 0x400000) flags += "forced cross up,"; // 4194304
                if (data & 0x800000) flags += "8388608,"; // 8388608
                if (data & 0x1000000) flags += "grazeable,"; // 16777216
                if (data & 0x2000000) flags += "33554432,"; // 33554432
                if (data & 0x4000000) flags += "67108864,"; // 67108864
                if (data & 0x8000000) flags += "134217728,"; // 134217728
                if (data & 0x10000000) flags += "268435456,"; // 268435456
                if (data & 0x20000000) flags += "536870912,"; // 536870912
                if (data & 0x40000000) flags += "1073741824,"; // 1073741824
                if (data & 0x80000000) flags += "2147483648,"; // 2147483648
                if(flags != "")flags = flags.slice(0, -1); // Slice removes the trailing comma

				if (this.str != flags){
					this.str = flags;
					this.text.Set(flags != "" ? format("flagAttack:[%s]", flags) : flags);
                    this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
                    this.text.y = ::setting.frame_data.Y+this.text.height;
				}
            };
        }
	);
    return obj;
}
function CreateFrame_data_Display () {
    local obj = this.CreateText(
        0,"",
        ::setting.frame_data.SX,
        ::setting.frame_data.SY,
        ::setting.frame_data.red,
        ::setting.frame_data.green,
        ::setting.frame_data.blue,
        ::setting.frame_data.alpha,
        ::graphics.slot.status,1,
        null,
        function (root) {
            root.str <- "";
            root.data <- [0,[0],0,[0]];
            root.motion <- 0;
            root.hitboxes <- [];
            root.framebar <- this.CreateText(
                0,"",
                1.0,1.0,//SXSY
                1.0,1.0,1.0,1.0,//RGBA
                ::graphics.slot.status,1,
                null,
                function (root) {
                    root.render <- function (data) {
                        local bar = "";
                        local size = 0;
                        if (data[0] > 0){
                            size = data[0];
                            do{bar += !(size % (3*(size/10))) ? ">" : ""}while(--size > -1);
                        }
                        if (data[1][0] > 0){
                            for (local i = 0; i < data[1].len(); ++i){
                                local size = data[1][i] - 1;
                                do {bar += !(size % (1*(size/10))) ? !(i & 1) ? "+" : "-" : "";}while(--size > -1);
                            }
                        }
                        if (data[2] > 0){
                            size = data[2];
                            do{bar += !(size % (3*(size/10))) ? "<" : ""}while(--size > -1);
                        }
                        this.text.Set(bar);
                        this.text.x = 640 - ((this.text.sx * this.text.width)/2);
                        this.text.y = 360 - (this.text.sy * this.text.height);
                    };
                    root.clear <- function () {
                        this.text.Set("");
                        this.text.x = 640 - ((this.text.sx * this.text.width)/2);
                        this.text.y = 360 - (this.text.sy * this.text.height);
                    };
                }
            );
            root.render <- function () {
                local frame = "";
                if (this.data[0] > 0) {
                    frame = format("startup:%2d ", this.data[0]+1);
                }
                local activeStr = "";
                if (this.data[1][0] != 0) {
                    for (local i = 0; i < this.data[1].len(); ++i){
                        if (i > 2 && i != this.data[1].len()-1){
                            if (this.data[1][i] == this.data[1][i - 2]) activeStr += "+";
                            continue;
                        }
                        activeStr += format(!(i & 1) ? "%2d" : "%2d not active",data[1][i]);
                        activeStr += i != (this.data[1].len()-1) ? ">" : "";
                    }
                }
                if (this.data[3][0] != 0) {
                    activeStr += "+(";
                    for (local i = 0; i < this.data[3].len(); ++i){
                        if (i > 2 && i != this.data[3].len()-1){
                            if (this.data[3][i] == this.data[3][i - 2]) activeStr += "+";
                            continue;
                        }
                        activeStr += format(!(i & 1) ? "%2d" : "%2d not active",data[3][i]);
                        activeStr += i != (this.data[3].len()-1) ? ">" : "";
                    }
                    activeStr += ")";
                }
                if(activeStr != "")frame += format("active:%s ", activeStr);
                if (this.data[2] > 0) {
                    frame += format("recovery:%2d ", this.data[2]);
                }
                if(::battle.team[0].current.armor != 0) frame += " ["+::battle.team[0].current.armor+"A]";
                if (this.str != frame) {
                    this.str = frame;
                    if(::setting.frame_data.framebar)this.framebar.render(this.data);
                    this.text.Set(frame);
                    this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
                    this.text.y = ::setting.frame_data.Y - (this.text.sy * this.text.height);
                }
            };
            root.tick <- function (active) {
                //active bits:
                // 1 - same source
                // 2 - different source
                switch (active) {
                    case 2:
                        if (this.data[2] != 0){
                            this.data[3].append(this.data[2]);
                            this.data[2] = 0;
                            this.data[3].append(0);
                        }
                        ++this.data[3][this.data[3].len()-1];
                        break;
                    case 1:
                    case 3:
                        if (this.data[2] != 0){
                            this.data[1].append(this.data[2]);
                            this.data[2] = 0;
                            this.data[1].append(0);
                        }
                        ++this.data[1][this.data[1].len()-1];
                        break;
                    default:
                        ++this.data[this.data[1][0] != 0 || this.data[3][0] != 0 ? 2 : 0];
                        break;
                }
            };
            root.clear <- function (motion = 0) {
                this.data = [0,[0],0,[0]];
                this.motion = motion;
                this.framebar.clear();
            };
        }
	);
    return obj;
}

function FrameDataDisplay(player){
    local color = [::setting.frame_data.red,::setting.frame_data.green,::setting.frame_data.blue,::setting.frame_data.alpha];
    local scale = [::seting.frame_data.SX,::setting.frame_data.SY];
    local display = {
        previous_data = null
        team = player
    };
    display.frame_data <- {
        str = ""
        max_w = 128
    };

    local frame = display.frame_data.text <- ::font.CreateSystemString("");
    frame.sx = scale[0];
    frame.sy = scale[1];
    frame.red = color[0];
    frame.green = color[1];
    frame.blue = color[2];
    frame.alpha = color[3];
    frame.ConnectRenderSlot(::graphics.slot.status,1);

    // {
    //     count = 0;//frames
    //     frames = [[0],[0,0,0,0],[0]];//startup,active,recovery
    //     cancels = [[10,69420]...];//frame,cancel bits
    //     armor = [[-1,1,10]...];//value,start,end
    // }
    display.frame_data.Render <- function (data) {
        local frame = "";
        local types = ["startup:","active:","recovery:"];
        foreach(i,v in data.frames){
            local t = types[i];
            foreach(_i,_v in v){
                t += format(!(i&1) ? "%2d" : "%2d not active",_v);
            }
            frame += t;
        }

        // if(::battle.team[0].current.armor != 0)
        if(data.armor.top()[2] == data.count){
            local _armor = data.armor.top();
            frame +=  format("[%2dA](%2dF)",_armor[0],(_armor[2]-_armor[1]));
        }

        if (this.str != frame) {
            this.str = frame;
            this.text.Set(frame);
            if (this.text.width*this.text.sx > this.max_w)this.text.sx = this.max_w / this.text.width;
            this.text.x = ::setting.frame_data.X
            this.text.y = ::setting.frame_data.Y;
        }
    };

    display.flag_state <- {
        str = ""
        max_w = 128
    };

    local flag_state = display.flag_state.text <- ::font.CreateSystemString("");
    flag_state.sx = scale[0];
    flag_state.sy = scale[1];
    flag_state.red = color[0];
    flag_state.green = color[1];
    flag_state.blue = color[2];
    flag_state.alpha = color[3];
    flag_state.ConnectRenderSlot(::graphics.slot.status,1);

    display.flag_state.Render <- function (data) {
        local flags = "";
        if (data & 0x1) flags += "no input,"; // 1
        if (data & 0x2) flags += "2,"; // 2
        if (data & 0x4) flags += "4,"; // 4
        if (data & 0x8) flags += "8,"; // 8
        if (data & 0x10) flags += "block,"; // 16
        if (data & 0x20) flags += "normal cancel,"; // 32
        if (data & 0x40) flags += "64,"; // 64
        if (data & 0x80) flags += "128,"; // 128
        if (data & 0x100) flags += "can be counter hit,"; // 256
        if (data & 0x200) flags += "can dial,"; // 512
        if (data & 0x400) flags += "bullet whiff,"; // 1024
        if (data & 0x800) flags += "attack block,"; // 2048
        if (data & 0x1000) flags += "graze,"; // 4096
        if (data & 0x2000) flags += "no grab,"; // 8192
        if (data & 0x4000) flags += "dash cancel,"; // 16384
        if (data & 0x8000) flags += "melee immune,"; // 32768
        if (data & 0x10000) flags += "bullet immune,"; // 65536
        if (data & 0x20000) flags += "131072,"; // 131072
        if (data & 0x40000) flags += "262144,"; // 262144
        if (data & 0x80000) flags += "counter on melee,"; // 524288
        if (data & 0x100000) flags += "1048576,"; // 1048576
        if (data & 0x200000) flags += "knock check,"; // 2097152
        if (data & 0x400000) flags += "counter on bullet,"; // 4194304
        if (data & 0x800000) flags += "8388608,"; // 8388608
        if (data & 0x1000000) flags += "no landing,"; // 16777216
        if (data & 0x2000000) flags += "33554432,"; // 33554432
        if (data & 0x4000000) flags += "67108864,"; // 67108864
        if (data & 0x8000000) flags += "134217728,"; // 134217728
        if (data & 0x10000000) flags += "268435456,"; // 268435456
        if (data & 0x20000000) flags += "536870912,"; // 536870912
        if (data & 0x40000000) flags += "1073741824,"; // 1073741824
        if (data & 0x80000000) flags += "invisible,"; // 2147483648
        if (flags != "") flags = flags.slice(0, -1); // Slice removes the trailing comma

        if (this.str != flags) {
            this.str = flags;
            this.text.Set(flags != "" ? format("flagState:[%s]", flags) : flags);
            if (this.text.width*this.text.sx > this.max_w)this.text.sx = this.max_w / this.text.width;
            this.text.x = ::setting.frame_data.X;
            this.text.y = ::setting.frame_data.Y + (frame.height * frame.text.sy);
        }
    };

    display.flag_attack = {
        str = ""
        max_w = 128
    }

    local flag_attack = display.flag_attack.text <- ::font.CreateSystemString("");
    flag_attack.sx = scale[0];
    flag_attack.sy = scale[1];
    flag_attack.red = color[0];
    flag_attack.green = color[1];
    flag_attack.blue = color[2];
    flag_attack.alpha = color[3];
    flag_attack.ConnectRenderSlot(::graphics.slot.status,1);

    display.flag_attack.Render <- function (data) {
        local flags = "";
        if (data & 0x1) flags += "1,"; // 1
        if (data & 0x2) flags += "can be blocked,"; // 2
        if (data & 0x4) flags += "can be blocked,"; // 4
        if (data & 0x8) flags += "8,"; // 8
        if (data & 0x10) flags += "is grab,"; // 16
        if (data & 0x20) flags += "32,"; // 32
        if (data & 0x40) flags += "forced counter,"; // 64
        if (data & 0x80) flags += "can counter,"; // 128
        if (data & 0x100) flags += "forced min rate,"; // 256
        if (data & 0x200) flags += "spellcard,"; // 512
        if (data & 0x400) flags += "1024,"; // 1024
        if (data & 0x800) flags += "melee?,"; // 2048
        if (data & 0x1000) flags += "projectile?,"; // 4096
        if (data & 0x2000) flags += "8192,"; // 8192
        if (data & 0x4000) flags += "16384,"; // 16384
        if (data & 0x8000) flags += "32768,"; // 32768
        if (data & 0x10000) flags += "ungrazeable,"; // 65536
        if (data & 0x20000) flags += "131072,"; // 131072
        if (data & 0x40000) flags += "262144,"; // 262144
        if (data & 0x80000) flags += "instant crush,"; // 524288
        if (data & 0x100000) flags += "no KO,"; // 1048576
        if (data & 0x200000) flags += "forced knock check/fixed juggle,"; // 2097152
        if (data & 0x400000) flags += "forced cross up,"; // 4194304
        if (data & 0x800000) flags += "8388608,"; // 8388608
        if (data & 0x1000000) flags += "grazeable,"; // 16777216
        if (data & 0x2000000) flags += "33554432,"; // 33554432
        if (data & 0x4000000) flags += "67108864,"; // 67108864
        if (data & 0x8000000) flags += "134217728,"; // 134217728
        if (data & 0x10000000) flags += "268435456,"; // 268435456
        if (data & 0x20000000) flags += "536870912,"; // 536870912
        if (data & 0x40000000) flags += "1073741824,"; // 1073741824
        if (data & 0x80000000) flags += "2147483648,"; // 2147483648
        if (flags != "")flags = flags.slice(0, -1); // Slice removes the trailing comma

        if (this.str != flags){
            this.str = flags;
            this.text.Set(flags != "" ? format("flagAttack:[%s]", flags) : flags);
            if (this.text.width*this.text.sx > this.max_w)this.text.sx = this.max_w / this.text.width;
            this.text.x = ::setting.frame_data.X;
            this.text.y = ::setting.frame_data.Y + (frame.height * frame.sy) + (flag_state.height * flag_state.sy);
        }
    };

    // display.framebar <- {
    //     action = display;
    //     str = "";
    // };

    // local bar = display.framebar.bar <- ::font.CreateSystemString("");
    // bar.red = bar.green = bar.blue = bar.alpha = 1;
    // bar.sx = bar.sy = 1;
    // bar.ConnectRenderSlot(::graphics.slot.status,1);

    // local cursor = display.framebar.cursor <- ::font.CreateSystemString("");
    // cursor.red = cursor.green = cursor.blue = cursor.alpha = 1;
    // cursor.sx = cursor.sy = 1;
    // cursor.ConnectRenderSlot(::graphics.slot.status,1);

    // display.framebar.Render <- function (data) {
    //     local cur = "";
    //     local bar = "";
    //     local size = 0;
    //     size += data[0];
    //     if (data[0] > 0){
    //         size = data[0];
    //         do{
    //             bar += "|";

    //         }while(--size > -1);
    //     }
    //     if (data[1][0] > 0){
    //         for (local i = 0; i < data[1].len(); ++i){
    //             local size = data[1][i] - 1;
    //             do {bar += !(size % (1*(size/10))) ? !(i & 1) ? "+" : "-" : "";}while(--size > -1);
    //         }
    //     }
    //     if (data[2] > 0){
    //         size = data[2];
    //         bar += size > 1 ? "" : "|"
    //         do{
    //             bar += "|";
    //         }while(--size > 0);
    //     }
    //     this.text.Set(bar);
    //     this.text.x = 640 - ((this.text.sx * this.text.width)/2);
    //     this.text.y = 360 - (this.text.sy * this.text.height);
    // };

    display.Update <- function () {
        // local data = {
        //     count = 0;
        //     frames = [];
        //     cancels = [];
        //     armor = [];
        // };

        // local p = team.current;

        // local flag_state = 0;
        // local flag_attack = 0;
        // if(::setting.frame_data.enabled){
        //     if(::setting.frame_data.input_flags){
        //         flag_state = p.flagState;
        //         flag_attack = p.flagAttack;
        //     }
        //     data = this.previous_data ? this.previous_data;
        //     // if (::setting.frame_data.IsFrameActive())
        // }

        // this.frame_data.Render(data);
        // this.flag_state.Render(flag_state);
        // this.flag_attack.Render(flag_attack);
    };

    return display;
}
