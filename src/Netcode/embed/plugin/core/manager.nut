::manbow.CompileFile("squiroll/plugin/core/cfg.nut",this);
cfg <- {};
list <- {};
patches <- {};
patches_csv <- {};

//class CFG {
//	filepath = null;
//	default_cfg = null;
//	data = null;
//	UI = {
//		function Page(section,_table,...) {
//			return function () {
//				this.anime.data.push([]);
//				this.proc.push([]);
//				foreach (elem in vargv) {
//					this.anime.data.top().push(elem[0]);
//					this.proc.top().push(elem[1]);
//				}
//				local title = ::UI.Title(section);
//				this.anime.data.top().push(title[0]);
//				this.proc.top().push(title[1]);
//			};
//		}
//
//		function BoolSelect(label,sqkey,section = null) {
//			local table = section ? data[section] : data;
//			local set = function(val, key, section) {
//			    Set(val, key, section);
//			};
//			return ::UI.Enum(label,[table,sqkey],function(item) {
//				::menu.help.Set(help_item);
//				Update = UpdateCommonItem;
//				anime.highlight.Set(item[1].left, item[1].top, item[1].right, item[1].bottom);
//				common_cursor = item[1].cursor;
//				common_callback_ok = function() {
//					local ret = (common_cursor.val != 0);
//					item[1].value.set(ret);
//					set(ret, sqkey, section);
//					item = null;
//					anime.highlight.Reset();
//				};
//				common_callback_cancel = function() {
//					item = null;
//					anime.highlight.Reset();
//				};
//			});
//		}
//
//		function ValueField(label,sqkey,section = null) {
//			local table = section ? data[section] : data;
//			local set = function(val,key, section = null) {
//				Set(val, key, section);
//			};
//			return ::UI.ValueField(label,[table,sqkey],function(item){
//				local item_x = anime.item_x;
//				::Dialog(2, cfg_str, function (ret) {
//					if (ret) {
//						try{ret["to"+typeof table[sqkey]]();}
//						catch (e){return;}
//						local str = ret+"";
//						local val = ret["to" + typeof table[sqkey]]();
//						item[1].Set(val);
//						set(val,sqkey,section);
//						item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
//					}
//				}, "");
//			});
//		}
//
//		function EnumField(label,options,sqkey,section = null) {
//			local table = section ? data[section] : data;
//			local set = function(val, key, section) {
//				Set(val, key, section);
//			}
//			return ::UI.Enum(label,[table,sqkey],function(item) {
//				::menu.help.Set(help_item);
//				Update = UpdateCommonItem;
//				anime.highlight.Set(item[1].left, item[1].top, item[1].right, item[1].bottom);
//				common_cursor = item[1].cursor;
//				common_callback_ok = function() {
//					local ret = common_cursor.val;
//					item[1].value.set(ret);
//					set(ret, sqkey, section);
//					item = null;
//					anime.highlight.Reset();
//				};
//				common_callback_cancel = function() {
//					item = null;
//					anime.highlight.Reset();
//				};
//			},options);
//		}
//	}
//	constructor(path,_default){
//		default_cfg = _default;
//		filepath = "plugin/config/"+path;
//		try{
//			local f = ::file(filepath,"rb");
//			data = {};
//			f.close();
//			Read();
//			CheckIntegrity();
//		}catch(e) {
//			data = default_cfg;
//			Write();
//		}
//	}
//
//	function CheckIntegrity() {
//		foreach(k, v in data) {
//			if (typeof v == "table"){
//				foreach(_k,_v in v) {
//					if (!(_k in data[k])) Set(_v, _k, k);
//				}
//			}else {
//				if (!(k in data)) Set(v, k);
//			}
//		}
//	}
//
//	function Read() {
//		local function parse(str) {
//			local val = null;
//			try {val = str.tointeger();}catch(e){}
//			if(val&&val.tostring()==str)return val;
//			try {val = str.tofloat();}catch(e){}
//			if(val&&val.tostring()==str)return val;
//			local _str = str.tolower();
//			if(_str == "true")return true;
//			if(_str == "false")return false;
//			return str;
//		}
//
//		local content = ::readfile(filepath);
//		local lines = ::split(content, "\n");
//		local section = null;
//
//		foreach(line in lines) {
//			line = ::strip(line);
//			if (line.len() == 0 || line[0] == ';' || line[0] == '#') continue;
//
//			if (line[0] == '[' && line[line.len()-1] == ']') {
//				section = ::strip(line.slice(1, line.len()-1));
//				if (!(section in data)) data[section] <- {};
//			} else {
//				local eq = line.find("=");
//				if (eq != null) {
//					local key = ::strip(line.slice(0, eq));
//					local str = ::strip(line.slice(eq+1));
//					local value = parse(str);
//					if (section == null) {
//						data[key] <- value;
//					}else {
//						data[section][key] <- value;
//					}
//				}
//			}
//		}
//	}
//
//	function Write() {
//		local buffer = "";
//		foreach(k,v in data) {
//			if (typeof v != "function") {
//				if (typeof v != "table")buffer += format("%s=%s\n",k,v.tostring());
//				else {
//					buffer += format("[%s]\n",k);
//					foreach(key,val in v) {
//						switch (typeof val) {
//							case "float":
//							case "integer":
//							case "bool":
//							case "string":
//								buffer += format("%s=%s\n",key,val.tostring());
//								break;
//						}
//					}
//				}
//			}
//		}
//		local file = ::writefile(filepath,buffer);
//	}
//
//	function Set(value,key,section = null) {
//		if (!section) {
//			data[key] <- value;
//		}else {
//			data[section][key] <- value;
//		}
//		Write();
//	}
//
//	function Remove(key,section = null) {
//		if (!section) {
//			delete data[key];
//		}else {
//			delete data[section][key];
//		}
//		Write();
//	}
//
//	function CreateConfigPage() {
//	}
//}

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

function LoadCFG(label,_default) {
	cfg[label] <- CFG(label+".ini",_default);
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

function LoadNativePlugin(path,label) {
	local table = list[label] <- {
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
    ::manbow.CompileFile(path,table);
    LoadCFG(label,table.config);
    AddModifier(table.modifier,label);
}

function LoadPlugin(path,label) {
	local table = list[label] <- {
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
LoadNativePlugin("squiroll/plugin/misc_input.nut","misc_input");
LoadNativePlugin("squiroll/plugin/ping_display.nut","ping_display");

::mkdir("plugin");
::mkdir("plugin/config");
foreach(file in ::listfiles("plugin")) {
	if (!file.find(".nut"))continue;
	local label = ::strip(file.slice(0,file.len()-4));
	LoadPlugin(file,label);
}
