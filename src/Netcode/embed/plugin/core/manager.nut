::manbow.CompileFile("squiroll/plugin/core/cfg.nut",this);
Input <- {};
::manbow.CompileFile("squiroll/plugin/core/input.nut",Input);
cfg <- {};
list <- {};
patches <- {};
patches_csv <- {};
active_modifiers <- {};

class Modifier {
	task = null;
	enabled = null;
	async = null;
	base_class = null;
	constructor(_base) {
		base_class = _base;
		async = _base.async;
		enabled = _base.Enabled;
	}
}

function LoadCFG(label,Default) {
	cfg[label] <- CFG(label+".ini",Default);
    return cfg[label];
}

function Patch(file,patch) {
	if (file in patches) {
		local prev = patches[file];
		local new = function() {
			prev();
			patch();
		}
		patches[file] = new;
	}else patches[file] <- patch;
}

function PatchCSV(csv,patch) {
	if (csv in patches_csv) {
		local prev = patches_csv[csv];
		local new = function(table) {
			prev(table);
			patch(table);
		};
		patches_csv[csv] = new;
	}else patches_csv[csv] <- patch;
}

function AddModifier(base_class,label) {
    Patch("data/script/battle/battle.nut",function() {
		modifiers[label] <- ::plugin.Modifier(base_class);
	});
}

function NewPlugin(label) {
    local plugin = list[label] <- {
        config = {}
        modifier = class {
            async = false;
            function Enabled(param){return false};
            function PreFrame(){return true};
            function Begin(){};
            function Update(){};
            function Release(){};
            function PostFrame(){};
        }
    };
    return plugin;
}

function LoadNativePlugin(path,label) {
    local table = NewPlugin(label);	
    ::manbow.CompileFile(path,table);
    LoadCFG(label,table.config);
    AddModifier(table.modifier,label);
}

function LoadPlugin(path,label) {
    local table = NewPlugin(label);	
    ::loadfile("plugin/"+path,true).call(table);
    LoadCFG(label,table.config);
    AddModifier(table.modifier,label);
}

Patch("data/system/component/menu_common.nut",function() {
	local prev = LoadItemTextArray;
	function LoadItemTextArray(filename) {
		local table = prev(filename);
		if (filename in ::plugin.patches_csv) {
			local patch = ::plugin.patches_csv[filename];
			patch(table);
		};
		return table;
	}
});

// Built-in plugins, feel free to comment out if not wanted
LoadNativePlugin("squiroll/plugin/frame_data.nut","frame_data");
LoadNativePlugin("squiroll/plugin/input_display.nut","input_display");
LoadNativePlugin("squiroll/plugin/framerate_control.nut","framerate_control");
LoadNativePlugin("squiroll/plugin/ping_display.nut","ping_display");

::mkdir("plugin");
::mkdir("plugin/config");
foreach(file in ::listfiles("plugin")) {
	if (!file.find(".nut"))continue;
	local label = ::strip(file.slice(0,file.len()-4));
	LoadPlugin(file,label);
}
