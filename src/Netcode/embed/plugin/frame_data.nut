config = {
    enabled = false
    x = 270
    y = 530
    sx = 0.75
    sy = 0.75
    width = 720
    timer = 240
    frame_step = false
};

// Patches
::plugin.Patch("data/script/actor.nut",function() {
    local createplayer = CreatePlayer;
    function CreatePlayer(...) {
    	vargv.insert(0,this);
    	local t = createplayer.acall(vargv);
    	
    	t.player_class = class extends t.player_class {
    		function SetMotion(motion, take) {
    			base.SetMotion(motion,take);
    			local task = ::battle.modifiers.frame_data.task;
    			if (task &&
    				task.team == team &&
    				task.current_data
    			) {
    				if (task.current_data.motion != motion &&
    					task.current_data.take >= keyTake
    				) {
    					if (motion >= 1000) {
    						task.IsNewMove();
    					}else {
    						task.current_data.motion = motion;
    					}
    				}
    			}
    		}
    	};
    
    	t.shot_class = class extends t.shot_class {
    		active = false;
    	
    		function Shot_CommonUpdate() {
    			local b = base.Shot_CommonUpdate();
    			if (b) {
    				local task = ::battle.modifiers.frame_data.task;
    				if (task &&
    					::plugin.cfg.frame_data.data.enabled &&
    					::setting.frame_data.IsFrameActive(this) &&
    					!active
    				) {
    					task.active = active = true;
    					task.current_data.metadata = ::setting.frame_data.GetMetadata(this);
    				}
    			}
    			return b;
    		}
    	};
    	return t;
    }
});

// Main Class
class display_module {
    text = null;
    max_w = null;
    constructor() {
        max_w = 1010;
        text = ::UI.Core.Text("");
        text.sy = 0.75;
        text.red = text.green = text.blue = text.alpha = 1;
        text.ConnectRenderSlot(::graphics.slot.info,1);
    }
    function Render(data) {}
    function Clear() {text.Set("");}
}

class modifier extends modifier {
    frame_data = class extends display_module {
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

            text.Set(frame);
            text.sx = ::math.fclamp(max_w / text.width,0.1,0.75);
            text.x = 5;
            text.y = 5;
        }
    }

    flag_state = class extends display_module {
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

            text.Set(format("flagState:[%s]", flags));
            text.sx = ::math.fclamp(max_w / text.width,0.1,0.75);
            text.x = 5;
            text.y = 5 + (text.height * text.sy);
        }
    }

    flag_attack = class extends display_module {
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

            text.Set(format("flagAttack:[%s]", flags));
            text.sx = ::math.fclamp(max_w / text.width,0.1,0.75);
            text.x = 5;
            text.y = 5 + (text.height * text.sy) * 2;
        }
    }

    metadata = class extends display_module {
        constructor() {
            text = [
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
            ];
            max_w = 256;
            foreach (i,_ in text) {
                text[i] = ::UI.Core.Text("");
                text[i].sy = 0.75;
                text[i].red = text[i].green = text[i].blue = text[i].alpha = 1;
                text[i].ConnectRenderSlot(::graphics.slot.info,1);
            }
        }

        function Render(data) {
            text[0].Set(format("damage: %d",data.metadata[0]));
            text[1].Set(format("hitStop(src/dealt): %d/%d",data.metadata[1],data.metadata[2]));
            text[2].Set(format("blockStun(src/dealt): %d/%d",data.metadata[3],data.metadata[4]));
            text[3].Set(format("rate(first/combo): %d/%d",data.metadata[5],data.metadata[6]));
            text[4].Set(format("stun: %d",data.metadata[8]));
            text[5].Set(format("chipDamage: %d",data.metadata[10]));
            text[6].Set(format("occult Drain: %d",data.metadata[11]));
            text[7].Set(format("SP Gain: %d",data.metadata[12]));
            text[8].Set(format("recover: %d",data.metadata[13]));
            text[9].Set(format("stopvec(x/y): %d/%d",data.metadata[15],data.metadata[16]));
            text[10].Set(format("hitvec(x/y): %d/%d",data.metadata[18],data.metadata[19]));
            text[11].Set(format("atk(type/rank): %d/%d",data.metadata[21],data.metadata[22]));

            foreach(i,txt in text){
                txt.sx = ::math.fclamp(max_w / txt.width,0.1,0.75);
                txt.x = 1011;
                txt.y = 5 + ((txt.height * txt.sy) * i);
            }
        }

        function Clear() {foreach (txt in text)txt.Set("");}
    }

    framebar = class extends display_module {
        empty_str = null;
        hit_str = null;
        constructor() {
            text = [
                [
                    null,//startup
                    null,//active
                    null,//recovery
                    null//in-between
                ],
                [
                    null,//dash
                    null,//special
                    null,//bullet
                    null,//dash+special
                    null,//dash+bullet
                    null,//special+bullet
                    null//all
                ]
            ];
            max_w = ::plugin.cfg.frame_data.data.width;
            empty_str = "@ ";
            hit_str = "¡";

            local colors = [
                [1.0,0.0,0.0],
                [0.0,1.0,0.0],
                [0.0,0.0,1.0],
                [0.5,0.5,0.5],
                [1.0,0.0,1.0],
                [0.0,1.0,1.0],
                [1.0,1.0,1.0]
            ];
            foreach(i,texts in text) {
                foreach(w,_ in texts) {
                    local color = colors[w];
                    texts[w] = ::UI.Core.Text("");
                    texts[w].red = color[1 - i];
                    texts[w].green = color[0 + i];
                    texts[w].blue = color[2];
                    texts[w].alpha = 1.0;
                    texts[w].ConnectRenderSlot(::graphics.slot.info,i);
                    if (w / 3)colors[w] = [1.0,1.0,0.0];
                }
            }
        }

        function Render(data) {
            max_w = ::plugin.cfg.frame_data.data.width;
            local max_sx = ::plugin.cfg.frame_data.data.sx;

            local txt = [[" "," "," "," "],[" "," "," "," "," "," "," "]];

            //cancel bar
            foreach (i,cancel in data.cancels) {
                local flag = cancel[0];
                local str = ["",""];
                local d = cancel[2] - cancel[1];
                while (d-- >= 0) {
                    str[0] += empty_str;
                    str[1] += hit_str;
                }
                local type = -1;
                if (flag) {
                    type = 0;
                    if (flag & 0x20)type += 1;//special
                    if (flag & 0x400)type += 2;//bullet
                    if ((flag & 0x4420) > 0x4000)type += 3;//dash
                }
                foreach(w,_ in txt[1]) {
                    txt[1][w] += type == w ? str[1] : str[0];
                }
            }

            // main bar
            foreach(i, arr in data.frames) {
                foreach(w,count in arr) {
                    local str = ["",""];
                    local c = count;
                    while(c-- > 0) {
                        str[1] += hit_str;
                        str[0] += empty_str;
                    }
                    foreach(z,_ in txt[0]) {
                        local tgt = (w&1) ? 3 : i;
                        txt[0][z] += tgt != z ? str[0] : str[1];
                    }
                }
            }

            foreach(i,arr in text) {
                foreach(w,_text in arr) {
                    _text.Set(txt[i][w]);
                    _text.sx = ::math.fclamp(max_w / _text.width,0.1,max_sx);
                    _text.sy = ::plugin.cfg.frame_data.data.sy - ((::plugin.cfg.frame_data.data.sy / 2) * i)
                    _text.y = ::plugin.cfg.frame_data.data.y;
                    _text.x = ::plugin.cfg.frame_data.data.x;
                }
            }
        }

        function Clear() {
            foreach(arr in text)foreach(text in arr)text.Set("");
        }
    }

    current_data = null;
    timer = null;
    full = null;
    active = null;
    team_id = null;
    team = null;
    parts = null;

    constructor(_team_id = 0) {
        team_id = _team_id;
        full = false;
        active = false;
        timer = ::plugin.cfg.frame_data.data.timer;

        parts = {};
        parts.frame_data <- frame_data();
        parts.flag_state <- flag_state();
        parts.flag_attack <- flag_attack();
        parts.metadata <- metadata();
        parts.framebar <- framebar();
    }

    function Release() {foreach(key,_ in parts)delete parts[key];}

    function Tick(data) {
        local current = team.current;

        data.frame_count++;
        data.flag_state = current.flagState;
        data.flag_attack = current.flagAttack;
        if(::setting.frame_data.GetMetadata(current)[0])data.metadata = ::setting.frame_data.GetMetadata(current);

        //phase handling
        local i = 0;
        if (!active)active = ::setting.frame_data.IsFrameActive(current);
        if (active){
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
        current_data = NewData();
        Tick(current_data);
        ::battle.modifiers.misc_inputs.task.frame_lock = ::plugin.cfg.frame_data.data.frame_stepping;
    }

    function IsPaused(data) {
        local current = team.current;
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
            motion = team.current.motion
            take = team.current.keyTake
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
        foreach(part in parts)part.Clear();
    }

    function ClearPartial() {
        parts.frame_data.Clear();
        parts.flag_state.Clear();
        parts.flag_attack.Clear();
        parts.metadata.Clear();
    }

    function Update() {
        if (!::battle.team || !"current" in ::battle.team[team_id])return;
        if (!team){
            team = ::battle.team[team_id];
            return;
        }
        local current = team.current;

        if (timer < 0 || !current_data){
            current_data = NewData();
        }

        if(::plugin.cfg.frame_data.data.enabled){
            if (current.motion >= 1000) {
                timer = ::plugin.cfg.frame_data.data.timer;
                if (::setting.frame_data.hasData(current)){
                    if (!current.hitStopTime && !team.time_stop_count){
                        Tick(current_data);
                    }
                }
            }else {
                timer--;
            }
        }

        if (::plugin.cfg.frame_data.data.enabled) {
            parts.framebar.Render(current_data);
            if (full) {
                foreach(module in parts)module.Render(current_data);
            }else {
                ClearPartial();
            }
        }else {
            ClearAll();
            current_data = NewData();
        }
        active = false;
    }
	
	function Enabled(param) {
	    local enabled = (param.game_mode == 40);
	    if (enabled) {
	        local practicerestart = PracticeRestart;
			function PracticeRestart() {
				local frame_task = modifiers.frame_data.task;
				if (frame_task) {
					frame_task.full = false;
					frame_task.ClearAll();
					frame_task.current_data = frame_task.NewData();
				}
				practicerestart();
			};
	    }
	    return enabled;
	}
};
