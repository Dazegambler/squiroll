class CFG {
	filepath = null;
	data = null;

	constructor (path,cfg) {
		filepath = "plugin/config/"+path;
		data = cfg;
		try {Read();}catch (e){}
		Write();
	}

	function Read() {
		local function parse(str) {
			local val = null;
			try{val = str.tofloat();}catch(e){}
			if (val&&val.tostring == str)return val;
			try{val = str.tointeger();}catch(e){}
			if (val&&val.tostring() == str)return val;
			local lower = str.tolower();
			if (lower == "true")return true;
			if (lower == "false")return false;
			return str;
		}

		local content = ::readfile(filepath);
		local lines = ::split(content,"\n");
		local table = data;

		foreach (line in lines) {
			line = ::strip(line);
			if (line.len() == 0 || line[0] == ';' || line[0] == "#") continue;

			if (line[0] == '[' && line[line.len() - 1] == ']') {
				table = data[(::strip(line.slice(1,line.len()-1)))];
				continue;
			}

			local eq = line.find("=");
			if (!eq)continue;
			local key = ::strip(line.slice(0,eq));
			local str = ::strip(line.slice(eq+1));
			local value = parse(str);
			table[key] = value;
		}
	}

	function Write() {
		local buffer = "";
	
		foreach (k,v in data) {
			if (typeof v == "table") {
				buffer += ::format("[%s]\n",k);
				foreach (k,v in v) {
					switch (typeof v) {
						case "float":
						case "integer":
						case "bool":
						case "string":
							buffer += ::format("%s=%s\n",k,v.tostring());
							break;
					}
				}
				continue;
			}
			buffer += ::format("%s=%s\n",k,v.tostring());
		}

		::writefile(filepath,buffer);
	}

	function Set(val,key,sec = null) {
		if (!sec) data[key] = val;
		else data[sec][key] = val;
		Write();
	}
};
