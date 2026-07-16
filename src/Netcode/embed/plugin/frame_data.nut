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
    //page.extend([
    //    ::UI.Menu.Page(
    //        ::UI.Menu.Title("Frame data display"),
    //        ::UI.Menu.Config.Boolean(0,"enabled","frame_data","general","enabled",this),
    //        ::UI.Menu.Header(1,"Binds"),
    //        ::UI.Menu.Config.Keybind(2,"toggle(keyboard)","frame_data","keyboard","b0","b0",this),
    //        ::UI.Menu.Config.Keybind(3,"toggle(controller)","frame_data","controller","b0","b0",this) 
    //    )
    //]);
});

// Patches
::plugin.Patch("data/script/actor.nut",function() {
    local createplayer = CreatePlayer;
    function CreatePlayer(...) {
    	vargv.insert(0,this);
    	local t = createplayer.acall(vargv);
    	
    	t.player_class = class extends t.player_class {
            tid = -1;
            function SetMotion(motion, take) {
    			base.SetMotion(motion,take);
                local task = ::battle.modifiers.frame_data.task;
    			if (!task || !task.data)return;

                if (tid < 0) {
                    
                }
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

local pip = class {
    main = null;
    cancel = null;
    inv = null;
    label = null;
    
    x = 0;
    y = 0;
    width = 0;
    height = 0;
    cx = 0;
    cy = 0;
   
    cancels = [
        [0,0,0,0],//0,none
        [1,0,0,0.9],//1,D
        [0,1,0,0.9],//2,C
        [1,1,0,0.9],//3,DC
        [0,0,1,0.9],//4,B
        [1,0,1,0.9],//5,DB
        [0,1,1,0.9],//6,CB
        [1,1,1,0.9]//7,DCB
    ];
    invuls = [
        [0,0,0,0],//0,none
        [0.75,0.75,0.85,0.9],//1,graze
        [1,0.85,0.3,0.9],//2,grab
        null,
        [0.5,1,0.3,0.9],//4,bullet
        null,null,null,
        [1,0.4,0.6,0.9]//8,melee
        null,null,null,null
    ]
    states = [
        [0.35,0.35,0.35,0.5],//0,empty
        [0.35,0.35,0.35,0.4],//1,padding
        [0.12,0.12,0.12,0.15],//2,timeline
        [1,1,1,0.85]//3,normal
    ];
    state = 0;
    color = null;

    constructor (tex) {
        main = ::UI.Sprite({
            texture = tex
            left = 264
            top = 360
            width = 16
            height = 16
            filter = 1
            alpha = 0
        });
        main.ConnectRenderSlot(::graphics.slot.info, 1);
        cancel = ::UI.Sprite({
            texture = tex
            left = 264
            top = 360
            width = 16
            height = 16
            filter = 1
            alpha = 0
        });
        cancel.ConnectRenderSlot(::graphics.slot.info, 1);
        inv = ::UI.Sprite({
            texture = tex
            left = 264
            top = 360
            width = 16
            height = 16
            filter = 1
            alpha = 0
        });
        inv.ConnectRenderSlot(::graphics.slot.info, 1);
        label = ::UI.Text({
            sy = 0.5
            sx = 0.5
            alpha = 0.9
        });
        label.ConnectRenderSlot(::graphics.slot.info, 2);
    }

    function SetLayout(x, y, w, h, tex_size) {
        this.x = x;
        this.y = y;
        width = w;
        height = h;
        cx = x + (w * 0.5);
        cy = y + (h * 0.5);
    
        main.x = x;
        main.y = y;
        main.sx = w / tex_size;
        main.sy = h / tex_size;

        cancel.x = x;
        cancel.y = y;
        cancel.sx = (w * 0.5) / tex_size;
        cancel.sy = (w * 0.5) / tex_size;
    
        inv.x = x + (w * 0.5);
        inv.y = y;
        inv.sx = (w * 0.5) / tex_size;
        inv.sy = (h * 0.5) / tex_size;


        label.y = cy - ((label.height * label.sy ) * 0.5);
    }

    function SetColor(color) {
        this.color = color;
        main.red = color[0];
        main.green = color[1];
        main.blue = color[2];
        main.alpha = color[3];
    }

    function SetState(state,ghost = false) {
        this.state = state;
        SetColor(states[state]);
        switch (state) {
            case 3:
                SetColor([color[0],color[1],color[2],states[state][3]]);
                break;
            default:
                SetColor(states[state]);
                break;
        }
        if (ghost) {
            SetColor([
                color[0]*0.45,
                color[1]*0.45,
                color[2]*0.45,
                0.6
            ]);
        }
    }

    function Reset() {
        SetState(0);
        SetCancel(0);
        SetInvul(0);
        label.Set("");
    }
    
    function SetCancel(cancel) {
        local col = cancels[cancel];
        cancel.red = col[0];
        cancel.green = col[1];
        cancel.blue = col[2];
        cancel.alpha = col[3];
    }

    function SetInvul(invul) {
        local col = invuls[invul] == null ? [1,1,1,0.9] : invuls[invul];
        inv.red = col[0];
        inv.green = col[1];
        inv.blue = col[2];
        inv.alpha = col[3];
    }

    function SetCount(count) {
        label.Set(count+"");
        label.x = cx - ((label.width * label.sx) * 0.5);
    }
};

local framebar_module = class extends module {
    POOL_SIZE = 60;
    PIP_W = 12;
    GAP = 1;
    TEX_SIZE = 16;
    BAR_H = 22;
    BAR_X = 280;
    BAR_Y = 555;

    pips = null;
    id = 0;

    bg_bar = null;
    constructor(idx) {
        id = idx;

        local tex = ::manbow.Texture();
        tex.Load("data/actor/status/texture/gauge.png");
       
        bg_bar = ::UI.Sprite({
            texture = tex
            left = 264
            top = 360
            width = 16
            height = 16
            filter = 1
            alpha = 0
        });
        bg_bar.ConnectRenderSlot(::graphics.slot.info, 0);
        pips = [];
        for (local i = 0; i < POOL_SIZE; ++i) {
            pips.push(framebar_pip(tex));
        }
        UpdateLayout();
    }

    function UpdateLayout() {
        local bar_y = BAR_Y + 32 + (id * 26);
        local pip_y = bar_y + 1;
        
        local pip_w = PIP_W - GAP;
        local pip_h = BAR_H - 2;

        bg_bar.x = BAR_X;
        bg_bar.y = bar_y;
        bg_bar.sx = (POOL_SIZE * PIP_W) / TEX_SIZE;
        bg_bar.sy = BAR_H / TEX_SIZE;
        bg_bar.red = bg_bar.green = bg_bar.blue = 0;
        bg_bar.alpha = 0.9;

        local x = BAR_X + (GAP * 0.5);
        foreach (i,pip in pips) {
            pip.SetLayout(x,pip_y,pip_w,pip_h,TEX_SIZE);
            x += PIP_W;
        }
    }

    function Render(data) {
        local prefix = (id+1)+"P";
        foreach (p in pips)p.Clear();

    }

    function Clear() {
        
    }
};

local framedata_module = class extends module {
    text = null;
    constructor() {
        text = ::UI.Text({
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
        text = ::UI.Text({
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
				local task = modifiers.frame_data.task;
				if (task) {
					task.full = false;
				    task.data = [null, null];
                    task.active = [false,false];
                    task.tracked_last_frame = [false,false];
				}
				practicerestart();
			};
	    }
	    return enabled;
	}
};
