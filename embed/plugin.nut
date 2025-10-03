cfg <- {};
list <- {};

class CFG {
	filepath = null;
	default_cfg = null;
	data = null;
	UI = {
		function Page(section,_table,...) {
			return function () {
				this.anime.data.push([]);
				this.proc.push([]);
				foreach (elem in vargv) {
					this.anime.data.top().push(elem[0]);
					this.proc.top().push(elem[1]);
				}
				local title = ::UI.Title(section);
				this.anime.data.top().push(title[0]);
				this.proc.top().push(title[1]);
			};
		}

		function BoolSelect(label,sqkey,section = null) {
			local table = section ? data[section] : data;
			local set = function(val, key, section = null) {
			    Set(val, key, section);
			};
			return ::UI.Enum(label,[table,sqkey],function(item) {
				::menu.help.Set(help_item);
				Update = UpdateCommonItem;
				anime.highlight.Set(item[1].left, item[1].top, item[1].right, item[1].bottom);
				common_cursor = item[1].cursor;
				common_callback_ok = function() {
					local ret = (common_cursor.val != 0);
					item[1].value.set(ret);
					set(ret, sqkey, section);
					item = null;
					anime.highlight.Reset();
				}
			});
		}

		function ValueField(label,sqkey,section = null) {
			local table = section ? data[section] : data;
			local set = function(val,key, section = null) {
				Set(val, key, section);
			};
			return ::UI.ValueField(label,[table,sqkey],function(item){
				local item_x = anime.item_x;
				::Dialog(2, cfg_str, function (ret) {
					if (ret) {
						try{ret["to"+typeof table[sqkey]]();}
						catch (e){return;}
						local str = ret+"";
						local val = ret["to" + typeof table[sqkey]]();
						item[1].Set(val);
						set(val,sqkey,section);
						item[1].x = ::graphics.width - item_x - (item[1].width * item[1].sx);
					}
				}, "");
			});
		}
	}
	constructor(path,_default){
		default_cfg = _default;
		filepath = "plugin/config/"+path;
		try{
			local f = file(filepath,"rb");
			data = {};
			f.close();
			Read();
			CheckIntegrity();
		}catch(e) {
			data = default_cfg;
			Write();
		}
	}

	function CheckIntegrity(section = null) {
		foreach(k,v in data) {
			if (typeof v == "table"){
				CheckIntegrity(k);
				continue;
			}
			if (!(k in cfg.data)) cfg.Set(v, k, section);
		}
	}

	function Read() {
		local function parse(str) {
			local val = null;
			try {val = str.tointeger();}catch(e){}
			if(val&&val.tostring()==str)return val;
			try {val = str.tofloat();}catch(e){}
			if(val&&val.tostring()==str)return val;
			local _str = str.tolower();
			if(_str == "true")return true;
			if(_str == "false")return false;
			return str;
		}

		local content = ::readfile(filepath);
		local lines = ::split(content, "\n");
		local section = null;

		foreach(line in lines) {
			line = ::strip(line);
			if (line.len() == 0 || line[0] == ';' || line[0] == '#') continue;

			if (line[0] == '[' && line[line.len()-1] == ']') {
				section = ::strip(line.slice(1, line.len()-1));
				if (!(section in data)) data[section] <- {};
			} else {
				local eq = line.find("=");
				if (eq != null) {
					local key = ::strip(line.slice(0, eq));
					local str = ::strip(line.slice(eq+1));
					local value = parse(str);
					if (section == null) {
						data[key] <- value;
					}else {
						data[section][key] <- value;
					}
				}
			}
		}
	}

	function Write() {
		local buffer = "";
		foreach(k,v in data) {
			if (typeof v != "function") {
				if (typeof v != "table")buffer += format("%s=%s\n",k,v.tostring());
				else {
					buffer += format("[%s]\n",k);
					foreach(key,val in v) {
						switch (typeof val) {
							case "float":
							case "integer":
							case "bool":
							case "string":
								buffer += format("%s=%s\n",key,val.tostring());
								break;
						}
					}
				}
			}
		}
		local file = ::writefile(filepath,buffer);
	}

	function Set(value,key,section = null) {
		if (!section) {
			data[key] <- value;
		}else {
			data[section][key] <- value;
		}
		Write();
	}

	function Remove(key,section = null) {
		if (!section) {
			delete data[key];
		}else {
			delete data[section][key];
		}
		Write();
	}

	function CreateConfigPage() {

	}
}

function LoadFile(path,table) {
	::loadfile("plugin/"+path,true).call(table);
}

function LoadCFG(path,label,_default) {
	cfg[label] <- CFG(path,_default);
	return cfg[label];
}

// CALL WITHIN PLUGIN
function CFGInit(plugin_name,default_cfg) {
	cfg <- ::plugin.LoadCFG(plugin_name + ".ini", plugin_name, default_cfg);
	function CheckIntegrity(table,section = null) {
		foreach(k,v in table) {
			if (typeof v == "table"){
				CheckIntegrity(v,k);
				continue;
			}
			if (!(k in cfg.data)) cfg.Set(v, k, section);
		}
	}
	CheckIntegrity(default_cfg);
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


::mkdir("plugin");
::mkdir("plugin/config");
foreach(file in ::listfiles("plugin")) {
	if (!file.find(".nut"))continue;
	local label = ::strip(file.slice(0,file.len()-4));
	list[label] <- {};
	local table = list[label];
	LoadFile(file,table);
}
