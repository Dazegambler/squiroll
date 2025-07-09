::manbow.compilebuffer("UI.nut", this);
// function CreateFlag_state_Display () {
//     local obj = this.CreateText(
//         0,"",
//         ::setting.frame_data.SX,
//         ::setting.frame_data.SY,
//         ::setting.frame_data.red,
//         ::setting.frame_data.green,
//         ::setting.frame_data.blue,
//         ::setting.frame_data.alpha,
//         ::graphics.slot.status,1,
//         null,
//         function (root) {
//             root.str <- "";
//             root.render <- function (data) {
//                 local flags = "";
//                 if (data & 0x1) flags += "no input,"; // 1
//                 if (data & 0x2) flags += "2,"; // 2
//                 if (data & 0x4) flags += "4,"; // 4
//                 if (data & 0x8) flags += "8,"; // 8
//                 if (data & 0x10) flags += "block,"; // 16
//                 if (data & 0x20) flags += "special cancel,"; // 32
//                 if (data & 0x40) flags += "64,"; // 64
//                 if (data & 0x80) flags += "128,"; // 128
//                 if (data & 0x100) flags += "can be counter hit,"; // 256
//                 if (data & 0x200) flags += "can dial,"; // 512
//                 if (data & 0x400) flags += "bullet cancel,"; // 1024
//                 if (data & 0x800) flags += "attack block,"; // 2048
//                 if (data & 0x1000) flags += "graze,"; // 4096
//                 if (data & 0x2000) flags += "no grab,"; // 8192
//                 if (data & 0x4000) flags += "dash cancel,"; // 16384
//                 if (data & 0x8000) flags += "melee immune,"; // 32768
//                 if (data & 0x10000) flags += "bullet immune,"; // 65536
//                 if (data & 0x20000) flags += "131072,"; // 131072
//                 if (data & 0x40000) flags += "262144,"; // 262144
//                 if (data & 0x80000) flags += "counter on melee,"; // 524288
//                 if (data & 0x100000) flags += "1048576,"; // 1048576
//                 if (data & 0x200000) flags += "knock check,"; // 2097152
//                 if (data & 0x400000) flags += "counter on bullet,"; // 4194304
//                 if (data & 0x800000) flags += "8388608,"; // 8388608
//                 if (data & 0x1000000) flags += "no landing,"; // 16777216
//                 if (data & 0x2000000) flags += "33554432,"; // 33554432
//                 if (data & 0x4000000) flags += "67108864,"; // 67108864
//                 if (data & 0x8000000) flags += "134217728,"; // 134217728
//                 if (data & 0x10000000) flags += "268435456,"; // 268435456
//                 if (data & 0x20000000) flags += "536870912,"; // 536870912
//                 if (data & 0x40000000) flags += "1073741824,"; // 1073741824
//                 if (data & 0x80000000) flags += "invisible,"; // 2147483648
//                 if(flags != "")flags = flags.slice(0, -1); // Slice removes the trailing comma

//                 if (this.str != flags) {
//                     this.str = flags;
//                     this.text.Set(flags != "" ? format("flagState:[%s]", flags) : flags);
//                     this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
//                     this.text.y = ::setting.frame_data.Y;
//                 }
//             };
//         }
// 	);
//     return obj;
// }
// function CreateFlag_attack_Display () {
//     local obj = this.CreateText(
//         0,"",
//         ::setting.frame_data.SX,
//         ::setting.frame_data.SY,
//         ::setting.frame_data.red,
//         ::setting.frame_data.green,
//         ::setting.frame_data.blue,
//         ::setting.frame_data.alpha,
//         ::graphics.slot.status,1,
//         null,
//         function (root) {
//             root.str <- "";
//             root.render <- function (data) {
//                 local flags = "";
//                 if (data & 0x1) flags += "1,"; // 1
//                 if (data & 0x2) flags += "can be blocked,"; // 2
//                 if (data & 0x4) flags += "can be blocked,"; // 4
//                 if (data & 0x8) flags += "8,"; // 8
//                 if (data & 0x10) flags += "is grab,"; // 16
//                 if (data & 0x20) flags += "32,"; // 32
//                 if (data & 0x40) flags += "forced counter,"; // 64
//                 if (data & 0x80) flags += "can counter,"; // 128
//                 if (data & 0x100) flags += "forced min rate,"; // 256
//                 if (data & 0x200) flags += "spellcard,"; // 512
//                 if (data & 0x400) flags += "1024,"; // 1024
//                 if (data & 0x800) flags += "melee?,"; // 2048
//                 if (data & 0x1000) flags += "projectile?,"; // 4096
//                 if (data & 0x2000) flags += "8192,"; // 8192
//                 if (data & 0x4000) flags += "16384,"; // 16384
//                 if (data & 0x8000) flags += "32768,"; // 32768
//                 if (data & 0x10000) flags += "ungrazeable,"; // 65536
//                 if (data & 0x20000) flags += "131072,"; // 131072
//                 if (data & 0x40000) flags += "262144,"; // 262144
//                 if (data & 0x80000) flags += "instant crush,"; // 524288
//                 if (data & 0x100000) flags += "no KO,"; // 1048576
//                 if (data & 0x200000) flags += "forced knock check/fixed juggle,"; // 2097152
//                 if (data & 0x400000) flags += "forced cross up,"; // 4194304
//                 if (data & 0x800000) flags += "8388608,"; // 8388608
//                 if (data & 0x1000000) flags += "grazeable,"; // 16777216
//                 if (data & 0x2000000) flags += "33554432,"; // 33554432
//                 if (data & 0x4000000) flags += "67108864,"; // 67108864
//                 if (data & 0x8000000) flags += "134217728,"; // 134217728
//                 if (data & 0x10000000) flags += "268435456,"; // 268435456
//                 if (data & 0x20000000) flags += "536870912,"; // 536870912
//                 if (data & 0x40000000) flags += "1073741824,"; // 1073741824
//                 if (data & 0x80000000) flags += "2147483648,"; // 2147483648
//                 if(flags != "")flags = flags.slice(0, -1); // Slice removes the trailing comma

// 				if (this.str != flags){
// 					this.str = flags;
// 					this.text.Set(flags != "" ? format("flagAttack:[%s]", flags) : flags);
//                     this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
//                     this.text.y = ::setting.frame_data.Y+this.text.height;
// 				}
//             };
//         }
// 	);
//     return obj;
// }
// function CreateFrame_data_Display () {
//     local obj = this.CreateText(
//         0,"",
//         ::setting.frame_data.SX,
//         ::setting.frame_data.SY,
//         ::setting.frame_data.red,
//         ::setting.frame_data.green,
//         ::setting.frame_data.blue,
//         ::setting.frame_data.alpha,
//         ::graphics.slot.status,1,
//         null,
//         function (root) {
//             root.str <- "";
//             root.data <- [0,[0],0,[0]];
//             root.motion <- 0;
//             root.hitboxes <- [];
//             root.framebar <- this.CreateText(
//                 0,"",
//                 1.0,1.0,//SXSY
//                 1.0,1.0,1.0,1.0,//RGBA
//                 ::graphics.slot.status,1,
//                 null,
//                 function (root) {
//                     root.render <- function (data) {
//                         local bar = "";
//                         local size = 0;
//                         if (data[0] > 0){
//                             size = data[0];
//                             do{bar += !(size % (3*(size/10))) ? ">" : ""}while(--size > -1);
//                         }
//                         if (data[1][0] > 0){
//                             for (local i = 0; i < data[1].len(); ++i){
//                                 local size = data[1][i] - 1;
//                                 do {bar += !(size % (1*(size/10))) ? !(i & 1) ? "+" : "-" : "";}while(--size > -1);
//                             }
//                         }
//                         if (data[2] > 0){
//                             size = data[2];
//                             do{bar += !(size % (3*(size/10))) ? "<" : ""}while(--size > -1);
//                         }
//                         this.text.Set(bar);
//                         this.text.x = 640 - ((this.text.sx * this.text.width)/2);
//                         this.text.y = 360 - (this.text.sy * this.text.height);
//                     };
//                     root.clear <- function () {
//                         this.text.Set("");
//                         this.text.x = 640 - ((this.text.sx * this.text.width)/2);
//                         this.text.y = 360 - (this.text.sy * this.text.height);
//                     };
//                 }
//             );
//             root.render <- function () {
//                 local frame = "";
//                 if (this.data[0] > 0) {
//                     frame = format("startup:%2d ", this.data[0]+1);
//                 }
//                 local activeStr = "";
//                 if (this.data[1][0] != 0) {
//                     for (local i = 0; i < this.data[1].len(); ++i){
//                         if (i > 2 && i != this.data[1].len()-1){
//                             if (this.data[1][i] == this.data[1][i - 2]) activeStr += "+";
//                             continue;
//                         }
//                         activeStr += format(!(i & 1) ? "%2d" : "%2d not active",data[1][i]);
//                         activeStr += i != (this.data[1].len()-1) ? ">" : "";
//                     }
//                 }
//                 if (this.data[3][0] != 0) {
//                     activeStr += "+(";
//                     for (local i = 0; i < this.data[3].len(); ++i){
//                         if (i > 2 && i != this.data[3].len()-1){
//                             if (this.data[3][i] == this.data[3][i - 2]) activeStr += "+";
//                             continue;
//                         }
//                         activeStr += format(!(i & 1) ? "%2d" : "%2d not active",data[3][i]);
//                         activeStr += i != (this.data[3].len()-1) ? ">" : "";
//                     }
//                     activeStr += ")";
//                 }
//                 if(activeStr != "")frame += format("active:%s ", activeStr);
//                 if (this.data[2] > 0) {
//                     frame += format("recovery:%2d ", this.data[2]);
//                 }
//                 if(::battle.team[0].current.armor != 0) frame += " ["+::battle.team[0].current.armor+"A]";
//                 if (this.str != frame) {
//                     this.str = frame;
//                     if(::setting.frame_data.framebar)this.framebar.render(this.data);
//                     this.text.Set(frame);
//                     this.text.x = ::setting.frame_data.X - ((this.text.width * this.text.sx) / 2);
//                     this.text.y = ::setting.frame_data.Y - (this.text.sy * this.text.height);
//                 }
//             };
//             root.tick <- function (active) {
//                 //active bits:
//                 // 1 - same source
//                 // 2 - different source
//                 switch (active) {
//                     case 2:
//                         if (this.data[2] != 0){
//                             this.data[3].append(this.data[2]);
//                             this.data[2] = 0;
//                             this.data[3].append(0);
//                         }
//                         ++this.data[3][this.data[3].len()-1];
//                         break;
//                     case 1:
//                     case 3:
//                         if (this.data[2] != 0){
//                             this.data[1].append(this.data[2]);
//                             this.data[2] = 0;
//                             this.data[1].append(0);
//                         }
//                         ++this.data[1][this.data[1].len()-1];
//                         break;
//                     default:
//                         ++this.data[this.data[1][0] != 0 || this.data[3][0] != 0 ? 2 : 0];
//                         break;
//                 }
//             };
//             root.clear <- function (motion = 0) {
//                 this.data = [0,[0],0,[0]];
//                 this.motion = motion;
//                 this.framebar.clear();
//             };
//         }
// 	);
//     return obj;
// }



function FrameDataDisplay(_team){
    local display = {
        spawn = false
        current_data = null
        timer = 0
        full = false
        team_id = _team
        team = null

        frame_data = {
            max_w = 1010

            function Render(data) {
                local frame = "";
                local types = ["startup","active","recovery"];
                foreach(i,arr in data.frames){
                    local t = types[i] + ":";
                    if (!arr[0]) {
                        t += " - ";
                    } else {
                        t += format(" %2d ", arr[0]);
                        for (local w = 1; w < arr.len();++w){
                            if (!(w&1)) {
                                t += format("> %2d ",arr[w]);
                            }else {
                                t += format("> %2d not %s ",arr[w],t);
                            }
                        }
                    }
                    frame += t;
                }

                if(data.armor.len() && data.armor.top()[2] == data.count){
                    local armor = data.armor.top();
                    frame +=  format("[%2dA](%2dF)",armor[0],(armor[2]-armor[1]));
                }

                this.text.Set(frame);
                this.text.sx = ::math.min(1,this.max_w / this.text.width);
                this.text.x = 5;
                this.text.y = 5;
            }
        }

        metadata = {
            texts = [
                null,//damage
                null,//hitstop E/P
                null,//guardstop E/P
                null,//rate first/combo
                null,//stun
                null,//guardrealdamage
                null,//slaveblockoccult
                null,//gaugehit
                null,//comborecovertime
                null,//stopvec x/y
                null,//hitvec x/y
                null//atk type/rank
            ]
            max_w = 256
            function Render(data) {
                this.texts[0].Set(format("damage: %d",data.metadata[0]));
                this.texts[1].Set(format("hitstop(E/P): %d/%d",data.metadata[1],data.metadata[2]));
                this.texts[2].Set(format("guardstop(E/P): %d/%d",data.metadata[3],data.metadata[4]));
                this.texts[3].Set(format("rate(first/combo): %d/%d",data.metadata[5],data.metadata[6]));
                this.texts[4].Set(format("stun: %d",data.metadata[8]));
                this.texts[5].Set(format("guardrealdamage: %d",data.metadata[10]));
                this.texts[6].Set(format("slaveblockoccult: %d",data.metadata[11]));
                this.texts[7].Set(format("gaugehit: %d",data.metadata[12]));
                this.texts[8].Set(format("comborecovertime: %d",data.metadata[13]));
                this.texts[9].Set(format("stopvec(x/y): %d/%d",data.metadata[15],data.metadata[16]));
                this.texts[10].Set(format("hitvec(x/y): %d/%d",data.metadata[18],data.metadata[19]));
                this.texts[11].Set(format("atk(type/rank): %d/%d",data.metadata[21],data.metadata[22]));

                foreach(i,text in this.texts){
                    text.sx = ::math.min(1,this.max_w / text.width);
                    text.x = 1011;
                    text.y = 5 + ((text.height * text.sy) * i);
                }
            }
        }

        flag_state = {
            max_w = 1010

            function Render(data) {
                local flags = "";
                if (data.flag_state & 0x1) flags += "no input,"; // 1
                if (data.flag_state & 0x2) flags += "2,"; // 2
                if (data.flag_state & 0x4) flags += "4,"; // 4
                if (data.flag_state & 0x8) flags += "top,"; // 8
                if (data.flag_state & 0x10) flags += "can block,"; // 16
                if (data.flag_state & 0x20) flags += "special cancel,"; // 32
                if (data.flag_state & 0x40) flags += "64,"; // 64
                if (data.flag_state & 0x80) flags += "128,"; // 128
                if (data.flag_state & 0x100) flags += "can be counter hit,"; // 256
                if (data.flag_state & 0x200) flags += "can dial,"; // 512
                if (data.flag_state & 0x400) flags += "bullet cancel,"; // 1024
                if (data.flag_state & 0x800) flags += "block,"; // 2048
                if (data.flag_state & 0x1000) flags += "graze,"; // 4096
                if (data.flag_state & 0x2000) flags += "no grab,"; // 8192
                if (data.flag_state & 0x4000) flags += "dash cancel,"; // 16384
                if (data.flag_state & 0x8000) flags += "melee immune,"; // 32768
                if (data.flag_state & 0x10000) flags += "bullet immune,"; // 65536
                if (data.flag_state & 0x20000) flags += "131072,"; // 131072
                if (data.flag_state & 0x40000) flags += "262144,"; // 262144
                if (data.flag_state & 0x80000) flags += "counter on melee,"; // 524288
                if (data.flag_state & 0x100000) flags += "knock check,"; // 1048576
                if (data.flag_state & 0x200000) flags += "knock check,"; // 2097152
                if (data.flag_state & 0x400000) flags += "counter on bullet,"; // 4194304
                if (data.flag_state & 0x800000) flags += "8388608,"; // 8388608
                if (data.flag_state & 0x1000000) flags += "no landing,"; // 16777216
                if (data.flag_state & 0x2000000) flags += "33554432,"; // 33554432
                if (data.flag_state & 0x4000000) flags += "67108864,"; // 67108864
                if (data.flag_state & 0x8000000) flags += "134217728,"; // 134217728
                if (data.flag_state & 0x10000000) flags += "268435456,"; // 268435456
                if (data.flag_state & 0x20000000) flags += "536870912,"; // 536870912
                if (data.flag_state & 0x40000000) flags += "1073741824,"; // 1073741824
                if (data.flag_state & 0x80000000) flags += "invisible,"; // 2147483648
                if (flags != "") flags = flags.slice(0, -1); // Slice removes the trailing comma

                this.text.Set(format("flagState:[%s]", flags));
                this.text.sx = ::math.min(1,this.max_w / this.text.width);
                this.text.x = 5;
                this.text.y = 5 + (this.text.height * this.text.sy);
            }
        }

        flag_attack = {
            max_w = 1010

            function Render(data) {
                local flags = "";
                if (data.flag_attack & 0x1) flags += "1,"; // 1
                if (data.flag_attack & 0x2) flags += "can be blocked,"; // 2
                if (data.flag_attack & 0x4) flags += "can be blocked,"; // 4
                if (data.flag_attack & 0x8) flags += "8,"; // 8
                if (data.flag_attack & 0x10) flags += "is grab,"; // 16
                if (data.flag_attack & 0x20) flags += "32,"; // 32
                if (data.flag_attack & 0x40) flags += "forced counter,"; // 64
                if (data.flag_attack & 0x80) flags += "can counter,"; // 128
                if (data.flag_attack & 0x100) flags += "forced min rate,"; // 256
                if (data.flag_attack & 0x200) flags += "spellcard,"; // 512
                if (data.flag_attack & 0x400) flags += "1024,"; // 1024
                if (data.flag_attack & 0x800) flags += "melee?,"; // 2048
                if (data.flag_attack & 0x1000) flags += "projectile?,"; // 4096
                if (data.flag_attack & 0x2000) flags += "8192,"; // 8192
                if (data.flag_attack & 0x4000) flags += "16384,"; // 16384
                if (data.flag_attack & 0x8000) flags += "32768,"; // 32768
                if (data.flag_attack & 0x10000) flags += "ungrazeable,"; // 65536
                if (data.flag_attack & 0x20000) flags += "131072,"; // 131072
                if (data.flag_attack & 0x40000) flags += "262144,"; // 262144
                if (data.flag_attack & 0x80000) flags += "instant crush,"; // 524288
                if (data.flag_attack & 0x100000) flags += "no KO,"; // 1048576
                if (data.flag_attack & 0x200000) flags += "forced knock check/fixed juggle,"; // 2097152
                if (data.flag_attack & 0x400000) flags += "forced cross up,"; // 4194304
                if (data.flag_attack & 0x800000) flags += "8388608,"; // 8388608
                if (data.flag_attack & 0x1000000) flags += "grazeable,"; // 16777216
                if (data.flag_attack & 0x2000000) flags += "story mode flag,"; // 33554432
                if (data.flag_attack & 0x4000000) flags += "67108864,"; // 67108864
                if (data.flag_attack & 0x8000000) flags += "134217728,"; // 134217728
                if (data.flag_attack & 0x10000000) flags += "268435456,"; // 268435456
                if (data.flag_attack & 0x20000000) flags += "536870912,"; // 536870912
                if (data.flag_attack & 0x40000000) flags += "1073741824,"; // 1073741824
                if (data.flag_attack & 0x80000000) flags += "2147483648,"; // 2147483648
                if (flags != "")flags = flags.slice(0, -1); // Slice removes the trailing comma
                
                this.text.Set(format("flagAttack:[%s]", flags));
                this.text.sx = ::math.min(1,this.max_w / this.text.width);
                this.text.x = 5;
                this.text.y = 5 + (this.text.height * this.text.sy) * 2;
            }
        }

        framebar = {
            function Render(data) {

            }
        }

        function Release() {
            delete this.frame_data;
            delete this.flag_state;
            delete this.flag_attack;
            delete this.framebar;
            delete this.metadata;
        }

        function Reset() {
            local color = {
                red = ::setting.frame_data.red
                green = ::setting.frame_data.green
                blue = ::setting.frame_data.blue
                alpha =::setting.frame_data.alpha
            };
            local scale = {
                x = ::setting.frame_data.SX
                y = ::setting.frame_data.SY
            };

            foreach(k in ["frame_data","flag_state","flag_attack"]){
                local text = "text" in this[k] ? this[k].text : this[k].text <- ::font.CreateSystemString("");
                // text.sx = 0.75;
                // text.sy = 0.75;
                text.red = color.red;
                text.green = color.green;
                text.blue = color.blue;
                text.alpha = color.alpha;
                text.ConnectRenderSlot(::graphics.slot.info,1);
            }

            for (local i = 0; i < 12;++i) {
                // if (this.metadata.texts[i])this.metadata.texts[i] = ::font.CreateSystemString("");
                local text = this.metadata.texts[i] != null ? this.metadata.texts[i] : this.metadata.texts[i] = ::font.CreateSystemString("");
                // text.sx = scale.x;
                // text.sy = scale.y;
                text.red = color.red;
                text.green = color.green;
                text.blue = color.blue;
                text.alpha = color.alpha;
                text.ConnectRenderSlot(::graphics.slot.info,1);
            }
        }

        function OnSettingChange(){
            this.Reset();
        }

        function Tick(data) {
            local current = this.team.current;

            //phase handling
            local i = 0;
            local isactive = ::setting.frame_data.IsFrameActive(current);
            if (isactive || spawn){
                i = 1;
                if (data.frames[2][0]){
                    data.frames[1].append(data.frames[2][0]);
                    data.frames[2][0] = 0;
                    data.frames[1].append(0);
                }
            }
            else if (data.frames[1][0])i = 2;
            local top = data.frames[i].len() - 1;
            data.frames[i][top]++;
        
            //armor handling
            if (current.armor) {
                if (!data.armor.len() || 
                    data.armor.top()[0] != current.armor ||
                    data.armor.top()[2] != data.count - 1){
                        data.armor.append([current.armor,data.count,data.count]);
                }else {
                    data.armor.top()[2] = data.count;
                }
            }

            //metadata handling
            data.metadata = ::setting.frame_data.GetMetadata(current);

            //cancel handling
            if (data.flag_state) {
                local cancels = data.flag_state & 0x4420;
                if (!data.cancels.len() ||
                    data.cancels.top()[0] != cancels ||
                    data.cancels.top()[2] != data.count - 1){
                        data.cancels.append([cancels,data.count,data.count]);
                }else {
                    data.cancels.top()[2] = data.count;
                }
            }
        }

        function IsNewMove() {
            local current = this.team.current;
            local result =  false;
            if (!current.keyTake && !current.keyFrame){
                result = true;
            }
            return result;
        }

        function NewData() {
            return {
                count = 0
                frames = [[0],[0],[0]]
                cancels = []
                armor = []
                metadata = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                flag_state = 0
                flag_attack = 0
            };
        }

        function Update() {
            if(!this.team){
                this.team = ::battle.team[this.team_id];
                return;
            }

            local current = this.team.current;

            // if (this.timer < 0 || !this.current_data || IsNewMove()){
            //     this.current_data = {
            //         count = 0
            //         frames = [[0],[0],[0]]
            //         cancels = []
            //         armor = []
            //         flag_state = 0
            //         flag_attack = 0
            //     };
            // }

            if (this.timer < 0 || !this.current_data ){
                this.current_data = NewData();
            }

            if(::setting.frame_data.enabled){
                if (!current.IsFree() && current.IsAttack()) {
                    this.timer = ::setting.frame_data.timer;
                    if (::setting.frame_data.hasData(current)){
                        if (!current.hitStopTime){
                            ::battle.frame_lock = ::setting.frame_data.frame_stepping;

                            if (!this.current_data || IsNewMove()){
                                this.current_data = NewData();
                            }

                            this.current_data.count++;
                            this.Tick(this.current_data);
                            if(::setting.frame_data.input_flags){
                                this.current_data.flag_state = current.flagState;
                                this.current_data.flag_attack = current.flagAttack;
                            }
                        }
                    }else {::battle.frame_lock = false}
                }else {
                    this.timer--;
                }
            }

            if (::setting.frame_data.enabled) {
                this.framebar.Render(this.current_data);
                if (this.full) {
                    this.frame_data.Render(this.current_data);
                    this.flag_state.Render(this.current_data);
                    this.flag_attack.Render(this.current_data);
                    this.metadata.Render(this.current_data);
                }else {
                    this.frame_data.text.Set("");
                    this.flag_state.text.Set("");
                    this.flag_attack.text.Set("");
                }
            }else {
                this.frame_data.text.Set("");
                this.flag_state.text.Set("");
                this.flag_attack.text.Set("");
            }
            this.spawn = false;
        }
    };

    display.Reset();

    ::setting.register(display);

    // data = {
    //     count = 0;//frames
    //     frames = [[0],[0,0,0,0],[0]];//startup,active,recovery
    //     cancels = [[10,69420]...];//frame,cancel bits
    //     armor = [[-1,1,10]...];//value,start,end
    // }

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

    return display;
}
