config = {
    general = {
        enabled = false
    }
    bind_keyboard = {
        device = -1
        b0 = 41//toggle
    }
    bind_controller = {
        device = 0
        b0 = -1//toggle
    }
};

::plugin.Patch("squiroll/config/mod_config.nut",function() {
    page.extend([
        ::UI.Menu.Page(
            ::UI.Menu.Title("Frame data display"),
            ::UI.Menu.Config.Boolean(0,"enabled","frame_data","general","enabled",this),
            ::UI.Menu.Header(1,"Binds"),
            ::UI.Menu.Config.Keybind(2,"toggle(keyboard)","frame_data","keyboard","b0","b0",this),
            ::UI.Menu.Config.Keybind(3,"toggle(controller)","frame_data","controller","b0","b0",this) 
        )
    ]);
});

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
    				task.data
    			) {
    				if (task.data.motion != motion &&
    					task.data.take >= keyTake
    				) {
    				    task.IsNewMove();
    				}else task.data.motion = motion;
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
    					::plugin.cfg.frame_data.data.general.enabled &&
    					::setting.frame_data.IsFrameActive(this) &&
    					!active
    				) {
    					task.active = active = true;
    					task.data.metadata = ::setting.frame_data.GetMetadata(this);
    				}
    			}
    			return b;
    		}
    	};
    	return t;
    }
});

local module = class {
    function Render(data){}
    function Clear(){}
};

local framedata_module = class extends module {
    text = null;
    constructor() {
        text = ::UI.Core.Text({
            max_length = 990
            sy = 0.75
            x = 5
            y = 5
        });
        text.ConnectRenderSlot(::graphics.slot.info,1);
    }

    function Render(data) {
        //phase
        local frames = "";
        local types = ["startup","active","recovery"];
        foreach (i,arr in data.frames) {
            frames += types[i]+":";
            if (!arr[0])frames += " - ";
            else {
                frames += ::format(" %2d ",arr[0]);
                foreach (w,v in arr.slice(1)) {
                    if (!(w&1))frames += ::format("> %2d ",v);
                    else frames += ::format("> %2d not %s ",v,types[i]);
                }
            }
        }
        if (data.armor.len() &&  data.armor.top()[2] == data.frame_count) {
            local armor = data.armor.top();
            frames += ::format("[%2dA](%2dF)",armor[0],(armor[2]-armor[1]));
        }
        frames += "\\n";
        //framestate
        frames += "flagState:[";
        if (data.flagState & 0x1) frames += "no input,"; // 1
        if (data.flagState & 0x2) frames += "2,"; // 2
        if (data.flagState & 0x4) frames += "4,"; // 4
        if (data.flagState & 0x8) frames += "top,"; // 8
        if (data.flagState & 0x10) frames += "can block,"; // 16
        if (data.flagState & 0x20) frames += "special cancel,"; // 32
        if (data.flagState & 0x40) frames += "64,"; // 64
        if (data.flagState & 0x80) frames += "128,"; // 128
        if (data.flagState & 0x100) frames += "can be counter hit,"; // 256
        if (data.flagState & 0x200) frames += "can dial,"; // 512
        if (data.flagState & 0x400) frames += "bullet cancel,"; // 1024
        if (data.flagState & 0x800) frames += "block,"; // 2048
        if (data.flagState & 0x1000) frames += "graze,"; // 4096
        if (data.flagState & 0x2000) frames += "no grab,"; // 8192
        if (data.flagState & 0x4000) frames += "dash cancel,"; // 16384
        if (data.flagState & 0x8000) frames += "melee immune,"; // 32768
        if (data.flagState & 0x10000) frames += "bullet immune,"; // 65536
        if (data.flagState & 0x20000) frames += "131072,"; // 131072
        if (data.flagState & 0x40000) frames += "262144,"; // 262144
        if (data.flagState & 0x80000) frames += "counter on melee,"; // 524288
        if (data.flagState & 0x100000) frames += "knock check,"; // 1048576
        if (data.flagState & 0x200000) frames += "knock check,"; // 2097152
        if (data.flagState & 0x400000) frames += "counter on bullet,"; // 4194304
        if (data.flagState & 0x800000) frames += "8388608,"; // 8388608
        if (data.flagState & 0x1000000) frames += "no landing,"; // 16777216
        if (data.flagState & 0x2000000) frames += "33554432,"; // 33554432
        if (data.flagState & 0x4000000) frames += "67108864,"; // 67108864
        if (data.flagState & 0x8000000) frames += "134217728,"; // 134217728
        if (data.flagState & 0x10000000) frames += "268435456,"; // 268435456
        if (data.flagState & 0x20000000) frames += "536870912,"; // 536870912
        if (data.flagState & 0x40000000) frames += "1073741824,"; // 1073741824
        if (data.flagState & 0x80000000) frames += "invisible,"; // 2147483648
        frames += "]\\n";
        //flagattack
        frames += "flagAttack:[";
        if (data.flagAttack & 0x1) frames += "1,"; // 1
        if (data.flagAttack & 0x2) frames += "can be blocked,"; // 2
        if (data.flagAttack & 0x4) frames += "can be blocked,"; // 4
        if (data.flagAttack & 0x8) frames += "8,"; // 8
        if (data.flagAttack & 0x10) frames += "is grab,"; // 16
        if (data.flagAttack & 0x20) frames += "32,"; // 32
        if (data.flagAttack & 0x40) frames += "forced counter,"; // 64
        if (data.flagAttack & 0x80) frames += "can counter,"; // 128
        if (data.flagAttack & 0x100) frames += "forced min rate,"; // 256
        if (data.flagAttack & 0x200) frames += "spellcard,"; // 512
        if (data.flagAttack & 0x400) frames += "1024,"; // 1024
        if (data.flagAttack & 0x800) frames += "melee?,"; // 2048
        if (data.flagAttack & 0x1000) frames += "projectile?,"; // 4096
        if (data.flagAttack & 0x2000) frames += "8192,"; // 8192
        if (data.flagAttack & 0x4000) frames += "16384,"; // 16384
        if (data.flagAttack & 0x8000) frames += "32768,"; // 32768
        if (data.flagAttack & 0x10000) frames += "ungrazeable,"; // 65536
        if (data.flagAttack & 0x20000) frames += "131072,"; // 131072
        if (data.flagAttack & 0x40000) frames += "262144,"; // 262144
        if (data.flagAttack & 0x80000) frames += "instant crush,"; // 524288
        if (data.flagAttack & 0x100000) frames += "no KO,"; // 1048576
        if (data.flagAttack & 0x200000) frames += "forced knock check/fixed juggle,"; // 2097152
        if (data.flagAttack & 0x400000) frames += "forced cross up,"; // 4194304
        if (data.flagAttack & 0x800000) frames += "8388608,"; // 8388608
        if (data.flagAttack & 0x1000000) frames += "grazeable,"; // 16777216
        if (data.flagAttack & 0x2000000) frames += "story mode flag,"; // 33554432
        if (data.flagAttack & 0x4000000) frames += "67108864,"; // 67108864
        if (data.flagAttack & 0x8000000) frames += "134217728,"; // 134217728
        if (data.flagAttack & 0x10000000) frames += "268435456,"; // 268435456
        if (data.flagAttack & 0x20000000) frames += "536870912,"; // 536870912
        if (data.flagAttack & 0x40000000) frames += "1073741824,"; // 1073741824
        if (data.flagAttack & 0x80000000) frames += "2147483648,"; // 2147483648
        frames += "]\\n";
        
        text.Set(frames);
        text.sx = ::math.fmax(text.sx,0.1);
    }

    function Clear(){text.Set("");}
};

local metadata_module = class extends module {
    text = null;
    constructor() {
        text = ::UI.Core.Text({
            max_length = 256
            x = 1011
            y = 5
        });
        text.ConnectRenderSlot(::graphics.slot.info,1);
    }

    function Render(data) {
        local meta = "";
        local d = data.metadata;
        meta += ::format("damage:%d\\n",d[0]);
        meta += ::format("hitStop(src,dealt):%d/%d\\n",d[1],d[2]);
        meta += ::format("blockStun(src,dealt):%d/%d\\n",d[3],d[4]);
        meta += ::format("rate(first/combo):%d/%d\\n",d[5],d[6]);
        meta += ::format("stun:%d\\n",d[8]);
        meta += ::format("chipDamage:%d\\n",d[10]);
        meta += ::format("occult Drain:%d\\n",d[11]);
        meta += ::format("SP Gain:%d\\n",d[12]);
        meta += ::format("recovery:%d\\n",d[13]);
        meta += ::format("stopVec(x/y):%d/%d\\n",d[15],d[16]);
        meta += ::format("hitVec(x/y):%d/%d\\n",d[18],d[19]);
        meta += ::format("atk(type/rank):%d/%d\\n",d[21],d[22]);

        text.Set(meta);
        text.sx = ::math.fmax(text.sx,0.1);
    }

    function Clear(){text.Set("");}
};

local graphics = class {
    elem = null;
    constructor(...) {
        elem = [];
        foreach (module in vargv)elem.append(module());
    }

    function Render(data) {
        foreach (module in elem)module.Render(data);
    }
    function Clear() {
        foreach (module in elem)module.Clear();
    }
};

class modifier extends modifier {
    data = null;
    timer = null;
    full = null;
    active = null;
    team_id = null;
    team = null;

    gui = null;

    input = null;

    cfg = null;

    constructor(_team_id = 0) {
        cfg = ::plugin.cfg.frame_data;
        team_id = _team_id;
        full = false;
        active = false;
        timer = 240;

        gui = graphics(
            framedata_module,
            metadata_module
        );
        
        input = ::plugin.Input.InputManager({
            keyboard = ::plugin.Input.InputDevice(cfg.data.bind_keyboard)
            controller = ::plugin.Input.InputDevice(cfg.data.bind_controller)
        });
    }

    function Tick(data) {
        local current = team.current;
        //local framedata = current.GetKeyFrameData();

        data.frame_count++;
        data.metadata = ::setting.frame_data.GetMetadata(current);
        data.flagState = current.flagState;
        data.flagAttack = current.flagAttack;
        //phase handling
        local i = 0;
        if (!active)active = ::setting.frame_data.IsFrameActive(current);
        
        if (active) {
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
        if (data.flagState) {
            local cancels = data.flagState & 0x4420;
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
        data = NewData();
        Tick(data);
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
            metadata = team.current.GetKeyFrameData()
            flagState = 0
            flagAttack = 0
        };
    }
    
    function PreFrame() {
        if (input.b0 == 1) {
            if ((full = !full))::battle.gauge.Hide();
            else ::battle.gauge.Show(0);
        }
        return true;
    }

    function Update() {
        if (!::battle.team || !"current" in ::battle.team[team_id])return;
        if (!team){
            team = ::battle.team[team_id];
            return;
        }
        local current = team.current;

        if (timer < 0 || !data)data = NewData();

        if(cfg.data.general.enabled){
            if (::setting.frame_data.hasData(current)){
                timer = 240;
                if (!current.hitStopTime && !team.time_stop_count){
                    Tick(data);
                }
            }else {
                timer--;
            }
            if (full)gui.Render(data);
            else gui.Clear();
        }else {
            gui.Clear();
        }

        active = false;
    }

    function Release() {
        gui = null;
        input.Release();
    }

	function Enabled(param) {
	    local enabled = (param.game_mode == 40);
	    if (enabled) {
	        local practicerestart = PracticeRestart;
			function PracticeRestart() {
				local frame_task = modifiers.frame_data.task;
				if (frame_task) {
					frame_task.full = false;
					frame_task.data = frame_task.NewData();
				}
				practicerestart();
			};
	    }
	    return enabled;
	}
};
