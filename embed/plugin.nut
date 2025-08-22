this.cfg <- {};
this.list <- {};

class CFG {
	filepath = ""
	data = {}
	constructor(path,_default){
		filepath = "plugin/config/"+path;
		try{
			local f = file(this.filepath,"rb");
			f.close();
			this.Read();
		}catch(e) {
			this.data = _default;
			this.Write();
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

		local content = ::readfile(this.filepath);
		local lines = ::split(content, "\n");
		local section = null;

		foreach(line in lines) {
			line = ::strip(line);
			if (line.len() == 0 || line[0] == ';' || line[0] == '#') continue;

			if (line[0] == '[' && line[line.len()-1] == ']') {
				section = ::strip(line.slice(1, line.len()-1));
				if (!(section in this.data)) this.data[section] <- {};
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
		foreach(k,v in this.data) {
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
		local file = ::writefile(this.filepath,buffer);
	}

	function Set(value,key,section = null) {
		if (!section) {
			this.data[key] <- value;
		}else {
			this.data[section][key] <- value;
		}
		this.Write();
	}

	function Remove(key,section = null) {
		if (!section) {
			delete this.data[key];
		}else {
			delete this.data[section][key];
		}
		this.Write();
	}
}

function LoadFile(path,table) {
	::loadfile("plugin/"+path,true).call(table);
}

function LoadCFG(path,label,_default) {
	this.cfg[label] <- CFG(path,_default);
	return this.cfg[label];
}

function Patch(file,patch) {
	if (file in this.patches) {
		local prev = this.patches[file];
		local new = function() {
			prev();
			patch();
		}
		this.patches[file] = new;
	}else this.patches[file] <- patch;
}

// function WriteCFG(path,table) {
// 	local buffer = "";
// 	foreach(k,v in table) {
// 		if (typeof v != "function") {
// 			if (typeof v != "table")buffer += format("%s=%s\n",k,v.tostring());
// 			else {
// 				buffer += format("[%s]\n",k);
// 				foreach(key,val in v){
// 					switch (typeof val) {
// 						case "float":
// 						case "integer":
// 						case "bool":
// 						case "string":
// 							buffer += format("%s=%s\n",key,val.tostring());
// 							break;
// 					}
// 				}
// 			}
// 		}
// 	}
// 	local file = ::writefile("plugin/config/"+path,buffer);
// }

::mkdir("plugin");
::mkdir("plugin/config");
foreach(file in ::listfiles("plugin")) {
	local label = ::strip(file.slice(0,file.len()-4));
	this.list[label] <- {};
	local table = this.list[label];
	this.LoadFile(file,table);
}
