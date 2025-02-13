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
                flags = flags.slice(0, -1); // Slice removes the trailing comma

                if (this.str != flags) {
                    this.str = flags;
                    this.text.Set(format("[%s]", flags));
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
                flags = flags.slice(0, -1); // Slice removes the trailing comma
				if (this.str != flags){
					this.str = flags;
					this.text.Set(format("[%s]", flags));
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
                        if (data[0] > 0){
                            for (local i = 0; i <= data[0]; ++i){
                                bar += i % 3 ? ">" : "";
                            }
                        }
                        if (data[1][0] > 0){
                            for (local i = 0; i < data[1].len(); ++i){
                                local size = data[1][i] - 1;
                                do {
                                    // if(!(size % 3))continue;
                                    bar += !(i & 1) ? "+" : "-";
                                }while(--size > -1);
                            }
                        }
                        if (data[2] > 0){
                            for (local i = 0; i <= data[2]; ++i){
                                bar += i % 3 ? "<" : "";
                            }
                        }
                        this.text.Set(bar);
                        this.text.x = 640 - ((this.text.sx * this.text.width)/2);
                        this.text.y = 360 - (this.text.sy * this.text.height);
                    };
                    root.clear <- function () {
                        this.text.Set("");
                    }
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
                if (this.str != frame) {
                    this.str = frame;
                    if(true)this.framebar.render(this.data);
                    this.text.Set(frame);
                    this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
                    this.text.y = ::setting.frame_data.Y - (this.text.sy * this.text.height);
                }
            };
            // root.render <- function () {
            //     local frame = "";
            //     if (this.data[0] > 0) {
            //         frame = format("startup:%2d ", this.data[0]+1);
            //     }
            //     local activeStr = "";
            //     if (this.data[1][0] != 0) {
            //         for (local i = 0; i < this.data[1].len(); ++i){
            //             if (i > 2 && i != this.data[1].len()-1){
            //                 if (this.data[1][i] == this.data[1][i - 2]) activeStr += "+";
            //                 continue;
            //             }
            //             activeStr += format(!(i & 1) ? "%2d" : "%2d not active",data[1][i]);
            //             activeStr += i != (this.data[1].len()-1) ? ">" : "";
            //         }
            //     }
            //     if (this.data[3][0] != 0) {
            //         activeStr += "+(";
            //         for (local i = 0; i < this.data[3].len(); ++i){
            //             if (i > 2 && i != this.data[3].len()-1){
            //                 if (this.data[3][i] == this.data[3][i - 2]) activeStr += "+";
            //                 continue;
            //             }
            //             activeStr += format(!(i & 1) ? "%2d" : "%2d not active",data[3][i]);
            //             activeStr += i != (this.data[3].len()-1) ? ">" : "";
            //         }
            //         activeStr += ")";
            //     }
            //     if(activeStr != "")frame += format("active:%s ", activeStr);
            //     if (this.data[2] > 0) {
            //         frame += format("recovery:%2d ", this.data[2]);
            //     }
            //     if (this.str != frame) {
            //         this.str = frame;
            //         this.text.Set(frame);
            //         this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
            //         this.text.y = ::setting.frame_data.Y - this.text.height;
            //     }
            // };
            root.tick <- function (active) {
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
            //::actor.actor_list
            // root.tick <- function (hitboxes, player) {
            //     local boxes = [];
            //     for (local i = 0; i < hitboxes.len(); ++i){
            //         if (hitboxes[i].owner != player)continue;
            //         if (hitboxes[i].flagAttack){
            //             if (this.data[2] != 0){
            //                 this.data[1].append(this.data[2]);
            //                 this.data[2] = 0;
            //                 this.data[1].append(0);
            //             }
            //             ++this.data[1][this.data[1].len()-1];
            //             break;
            //         }
            //         if (hitboxes[i].flagState){
            //             ++this.data[this.data[1][0] != 0 ? 2 : 0];
            //             break;
            //         }

            //         if (boxes.len() > 0){
            //             // local new = true;
            //             for (local i = 0; i < boxes.len(); ++i){
            //                 if(boxes[i].flagAttack == hitboxes[i].flagAttack || boxes[i].flagState == hitboxes[i].flagState)continue;
            //                 boxes.append(hitboxes[i]);
            //             }
            //         }else{boxes.append(hitboxes[i])}
            //     }
            //     return boxes;
            // };
            root.clear <- function (motion = 0) {
                this.data = [0,[0],0,[0]];
                this.motion = motion;
                // this.framebar.clear();
            };
        }
	);
    return obj;
}
function CheckFlags (actors,p1,p2){
    // local states = [];
    local attacks = [];
    for ( local i = 0; i < actors.len(); ++i){
        // if (actors[i].flagState){
        //     local flags = "";
        //     if (actors[i].flagState & 0x1) flags += "no input,"; // 1
        //     if (actors[i].flagState & 0x2) flags += "2,"; // 2
        //     if (actors[i].flagState & 0x4) flags += "4,"; // 4
        //     if (actors[i].flagState & 0x8) flags += "8,"; // 8
        //     if (actors[i].flagState & 0x10) flags += "block,"; // 16
        //     if (actors[i].flagState & 0x20) flags += "normal cancel,"; // 32
        //     if (actors[i].flagState & 0x40) flags += "64,"; // 64
        //     if (actors[i].flagState & 0x80) flags += "128,"; // 128
        //     if (actors[i].flagState & 0x100) flags += "can be counter hit,"; // 256
        //     if (actors[i].flagState & 0x200) flags += "can dial,"; // 512
        //     if (actors[i].flagState & 0x400) flags += "bullet whiff,"; // 1024
        //     if (actors[i].flagState & 0x800) flags += "attack block,"; // 2048
        //     if (actors[i].flagState & 0x1000) flags += "graze,"; // 4096
        //     if (actors[i].flagState & 0x2000) flags += "no grab,"; // 8192
        //     if (actors[i].flagState & 0x4000) flags += "dash cancel,"; // 16384
        //     if (actors[i].flagState & 0x8000) flags += "melee immune,"; // 32768
        //     if (actors[i].flagState & 0x10000) flags += "bullet immune,"; // 65536
        //     if (actors[i].flagState & 0x20000) flags += "131072,"; // 131072
        //     if (actors[i].flagState & 0x40000) flags += "262144,"; // 262144
        //     if (actors[i].flagState & 0x80000) flags += "counter on melee,"; // 524288
        //     if (actors[i].flagState & 0x100000) flags += "1048576,"; // 1048576
        //     if (actors[i].flagState & 0x200000) flags += "knock check,"; // 2097152
        //     if (actors[i].flagState & 0x400000) flags += "counter on bullet,"; // 4194304
        //     if (actors[i].flagState & 0x800000) flags += "8388608,"; // 8388608
        //     if (actors[i].flagState & 0x1000000) flags += "no landing,"; // 16777216
        //     if (actors[i].flagState & 0x2000000) flags += "33554432,"; // 33554432
        //     if (actors[i].flagState & 0x4000000) flags += "67108864,"; // 67108864
        //     if (actors[i].flagState & 0x8000000) flags += "134217728,"; // 134217728
        //     if (actors[i].flagState & 0x10000000) flags += "268435456,"; // 268435456
        //     if (actors[i].flagState & 0x20000000) flags += "536870912,"; // 536870912
        //     if (actors[i].flagState & 0x40000000) flags += "1073741824,"; // 1073741824
        //     if (actors[i].flagState & 0x80000000) flags += "invisible,"; // 2147483648
        //     flags = flags.slice(0, -1); // Slice removes the trailing comma
        //     local new = true;
        //     if(i > 0){
        //         for (local m = 0; m < states.len(); ++m){
        //             if (states[m][0] == flags){
        //                 new = false;
        //                 states[m][1]++;
        //                 break;
        //             }
        //         }
        //     }
        //     if(new)states.append([flags,0]);
        // }
        if (actors[i].flagAttack){
            local flags = "";
            if (actors[i].flagAttack & 0x1) flags += "1,"; // 1
            if (actors[i].flagAttack & 0x2) flags += "can be blocked,"; // 2
            if (actors[i].flagAttack & 0x4) flags += "can be blocked,"; // 4
            if (actors[i].flagAttack & 0x8) flags += "8,"; // 8
            if (actors[i].flagAttack & 0x10) flags += "is grab,"; // 16
            if (actors[i].flagAttack & 0x20) flags += "32,"; // 32
            if (actors[i].flagAttack & 0x40) flags += "forced counter,"; // 64
            if (actors[i].flagAttack & 0x80) flags += "can counter,"; // 128
            if (actors[i].flagAttack & 0x100) flags += "forced min rate,"; // 256
            if (actors[i].flagAttack & 0x200) flags += "spellcard,"; // 512
            if (actors[i].flagAttack & 0x400) flags += "1024,"; // 1024
            if (actors[i].flagAttack & 0x800) flags += "melee?,"; // 2048
            if (actors[i].flagAttack & 0x1000) flags += "projectile?,"; // 4096
            if (actors[i].flagAttack & 0x2000) flags += "8192,"; // 8192
            if (actors[i].flagAttack & 0x4000) flags += "16384,"; // 16384
            if (actors[i].flagAttack & 0x8000) flags += "32768,"; // 32768
            if (actors[i].flagAttack & 0x10000) flags += "ungrazeable,"; // 65536
            if (actors[i].flagAttack & 0x20000) flags += "131072,"; // 131072
            if (actors[i].flagAttack & 0x40000) flags += "262144,"; // 262144
            if (actors[i].flagAttack & 0x80000) flags += "instant crush,"; // 524288
            if (actors[i].flagAttack & 0x100000) flags += "no KO,"; // 1048576
            if (actors[i].flagAttack & 0x200000) flags += "forced knock check/fixed juggle,"; // 2097152
            if (actors[i].flagAttack & 0x400000) flags += "forced cross up,"; // 4194304
            if (actors[i].flagAttack & 0x800000) flags += "8388608,"; // 8388608
            if (actors[i].flagAttack & 0x1000000) flags += "grazeable,"; // 16777216
            if (actors[i].flagAttack & 0x2000000) flags += "33554432,"; // 33554432
            if (actors[i].flagAttack & 0x4000000) flags += "67108864,"; // 67108864
            if (actors[i].flagAttack & 0x8000000) flags += "134217728,"; // 134217728
            if (actors[i].flagAttack & 0x10000000) flags += "268435456,"; // 268435456
            if (actors[i].flagAttack & 0x20000000) flags += "536870912,"; // 536870912
            if (actors[i].flagAttack & 0x40000000) flags += "1073741824,"; // 1073741824
            if (actors[i].flagAttack & 0x80000000) flags += "2147483648,"; // 2147483648
            flags = flags.slice(0, -1); // Slice removes the trailing comma
            local new = true;
            if(i > 0){
                for (local m = 0; m < attacks.len(); ++m){
                    if (attacks[m][0] == flags){
                        new = false;
                        attacks[m][1]++;
                        break;
                    }
                }
            }
            if(new)attacks.append([flags,0]);
        }
        ::debug.print("hit from:"+(actors[i].owner == p1 ? "p1" : actors[i] == p1 ? "self" :"p2")+"\n");
    }
    // for (local m = 0; m < states.len(); ++m){
    //     ::debug.print(format("states:[%s] %s\n",states[m][0],states[m][1] > 0 ? format("[%d]",states[m][1]) : ""));
    // }
    for (local m = 0; m < attacks.len(); ++m){
        ::debug.print(format("attacks:[%s] %s\n",attacks[m][0],attacks[m][1] > 0 ? format("[%d]",attacks[m][1]) : ""));
    }
}