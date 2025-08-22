function FrameDataDisplay(_team){
    local display = {
        current_data = null
        timer = 0
        full = false
        active = false
        team_id = _team
        team = null

        frame_data = {
            max_w = 1010

            function Render(Data) {
                local data = clone Data;
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
                                t += format("> %2d not %s ",arr[w],types[i]);
                            }
                        }
                    }
                    frame += t;
                }

                if(data.armor.len() && data.armor.top()[2] == data.frame_count){
                    local armor = data.armor.top();
                    frame +=  format("[%2dA](%2dF)",armor[0],(armor[2]-armor[1]));
                }

                this.text.Set(frame);
                this.text.sx = ::math.clamp(this.max_w / this.text.width,0.1,0.75);
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
                this.texts[1].Set(format("hitStop(src/dealt): %d/%d",data.metadata[1],data.metadata[2]));
                this.texts[2].Set(format("blockStun(src/dealt): %d/%d",data.metadata[3],data.metadata[4]));
                this.texts[3].Set(format("rate(first/combo): %d/%d",data.metadata[5],data.metadata[6]));
                this.texts[4].Set(format("stun: %d",data.metadata[8]));
                this.texts[5].Set(format("chipDamage: %d",data.metadata[10]));
                this.texts[6].Set(format("occult Drain: %d",data.metadata[11]));
                this.texts[7].Set(format("SP Gain: %d",data.metadata[12]));
                this.texts[8].Set(format("recover: %d",data.metadata[13]));
                this.texts[9].Set(format("stopvec(x/y): %d/%d",data.metadata[15],data.metadata[16]));
                this.texts[10].Set(format("hitvec(x/y): %d/%d",data.metadata[18],data.metadata[19]));
                this.texts[11].Set(format("atk(type/rank): %d/%d",data.metadata[21],data.metadata[22]));

                foreach(i,text in this.texts){
                    text.sx = ::math.clamp(this.max_w / text.width,0.1,0.75);
                    text.x = 1011;
                    text.y = 5 + ((text.height * text.sy) * i);
                }
            }

            function Clear() {
                foreach (text in this.texts)text.Set("");
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
                this.text.sx = ::math.clamp(this.max_w / this.text.width,0.1,0.75);
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
                this.text.sx = ::math.clamp(this.max_w / this.text.width,0.1,0.75);
                this.text.x = 5;
                this.text.y = 5 + (this.text.height * this.text.sy) * 2;
            }
        }

        framebar = {
            max_w = ::setting.frame_data.width
            cancel = []
            bar = [] //0:startup,1:active,2:recovery,3:misc
            function Render(data) {
                local y = ::setting.frame_data.y;
                local max_sx = ::setting.frame_data.sx;
                local x = ::setting.frame_data.x;

                //cancel bar
                local cancels = [" "," "," "," "," "," "," "];
                foreach (i,cancel in data.cancels) {
                    local toadd = ["　 ","　 ","　 ","　 ","　 ","　 ","　 "];
                    local flag = cancel[0];
                    if (flag) {
                        local text = 0;
                        if (flag & 0x20)text += 1;//special
                        if (flag & 0x400)text += 2;//bullet
                        if ((flag & 0x4420) > 0x4000)text += 3;//dash
                        toadd[text] = "□";
                    }
                    local duration = cancel[2] - cancel[1];
                    for (local id = 0; id < 7; ++id) {
                        for(local t = 0; t <= duration;++t)cancels[id] += toadd[id];
                    }
                }

                foreach (i,text in this.cancel) {
                    text.Set(cancels[i]);
                    text.sx = ::math.clamp(this.max_w / text.width,0.1,max_sx);
                    text.sy = ::setting.frame_data.sy;
                    text.x = x;
                    text.y = y;
                }

                y += this.cancel[0].height;

                // main bar
                local bar = [" ", " ", " ", " "];

                foreach(i, arr in data.frames) {
                    foreach(w,data in arr) {
                        local add = ["　 ", "　 ", "　 ", "　 "];
                        for(local t = 0; t < data;++t) {
                            add[(w&1) ? 3 : i] = "■";
                            foreach(z,val in add)bar[z] += val;
                        }
                    }
                }

                foreach(i,text in this.bar) {
                    text.Set(bar[i]);
                    text.sx = ::math.clamp(this.max_w / text.width,0.1,max_sx);
                    text.sy = ::setting.frame_data.sy;
                    text.x = x;
                    text.y = y;
                }
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
            foreach(k in ["frame_data","flag_state","flag_attack"]){
                local text = this[k].text <- ::font.CreateSystemString("");
                text.sy = 0.75;
                text.red = text.green = text.blue = text.alpha = 1;
                text.ConnectRenderSlot(::graphics.slot.info,1);
            }

            //metadata display
            for (local i = 0; i < 12;++i) {
                local text = this.metadata.texts[i] = ::font.CreateSystemString("");
                text.sy = 0.75;
                text.red = text.green = text.blue = text.alpha = 1;
                text.ConnectRenderSlot(::graphics.slot.info,1);
            }

            //framebar
            local colors = [
                [
                    [1.0,0.0,0.0],
                    [0.0,1.0,0.0],
                    [0.0,0.0,1.0]
                ],
                [
                    [1.0,1.0,0.0],
                    [1.0,0.0,1.0],
                    [0.0,1.0,1.0]
                ],
                [
                    [1.0,1.0,1.0]
                ]
            ];
            for (local a = 0; a < 7; ++a) {
                local color = colors[a / 3][a % 3];
                local text = ::font.CreateSystemString("");
                text.red = color[0];
                text.green = color[1];
                text.blue = color[2];
                text.alpha = 1.0;
                text.ConnectRenderSlot(::graphics.slot.info,1);
                this.framebar.cancel.append(text);
            }

            for (local i = 0; i < 4; ++i) {
                local color = [0.0,0.0,0.0];
                if (i < color.len())color[i] = 1.0;
                else color = [0.5,0.5,0.5];
                local text = ::font.CreateSystemString("");
                text.red = color[1];
                text.green = color[0];
                text.blue = color[2];
                text.alpha = 1.0;
                text.ConnectRenderSlot(::graphics.slot.info,1);
                this.framebar.bar.append(text);
            }
        }

        function OnSettingChange(){
        }

        function Tick(data) {
            local current = this.team.current;

            data.frame_count++;
            data.flag_state = current.flagState;
            data.flag_attack = current.flagAttack;
            if(::setting.frame_data.GetMetadata(current)[0])data.metadata = ::setting.frame_data.GetMetadata(current);

            //phase handling
            local i = 0;
            if (!this.active)this.active = ::setting.frame_data.IsFrameActive(current);
            if (this.active){
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
                    data.armor.top()[2] != data.frame_count - 1
                ){
                    data.armor.append([current.armor,data.frame_count,data.frame_count]);
                }else {
                    data.armor.top()[2] = data.frame_count;
                }
            }

            //cancel handling
            if (data.flag_state) {
                local cancels = data.flag_state & 0x4420;
                if (!data.cancels.len() ||
                    data.cancels.top()[0] != cancels ||
                    data.cancels.top()[2] != data.frame_count - 1
                ){
                    data.cancels.append([cancels,data.frame_count,data.frame_count]);
                }else {
                    data.cancels.top()[2] = data.frame_count;
                }
            }
        }

        function IsNewMove() {
            this.current_data = this.NewData();
            this.Tick(this.current_data);
            ::battle.frame_lock = ::setting.frame_data.frame_stepping;
        }

        function IsPaused(data) {
            local current = this.team.current;
            local result = false;
            if (data.keytake == current.keyTake &&
                data.keyframe == current.keyFrame &&
                data.frame <= current.frame
            ) {
                result = true;
            }
            return result;
        }

        function NewData() {
            return {
                motion = this.team.current.motion
                take = this.team.current.keyTake
                frame_count = 0
                frames = [[0],[0],[0]]
                cancels = []
                armor = []
                metadata = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
                flag_state = 0
                flag_attack = 0
            };
        }

        function ClearAll() {
            this.frame_data.text.Set("");
            this.flag_state.text.Set("");
            this.flag_attack.text.Set("");
            this.metadata.Clear();
        }

        function Update() {
            if (!::battle.team || !"current" in ::battle.team[this.team_id])return;
            if (!this.team){
                this.team = ::battle.team[this.team_id];
                return;
            }
            local current = this.team.current;

            if (this.timer < 0 || !this.current_data){
                this.current_data = NewData();
            }

            if(::setting.frame_data.enabled){
                if (current.motion >= 1000) {
                    this.timer = ::setting.frame_data.timer;
                    if (::setting.frame_data.hasData(current)){
                        if (!current.hitStopTime && !team.time_stop_count){
                            ::battle.frame_lock = ::setting.frame_data.frame_stepping;
                            this.Tick(this.current_data);
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
                    this.ClearAll();
                }
            }else {
                this.ClearAll();
                this.current_data = this.NewData();
            }
            this.active = false;
        }
    };
    display.Reset();
    return display;
}
