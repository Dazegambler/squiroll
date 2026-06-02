class CFG {
	filepath = null;
	data = null;

	constructor (path,cfg) {
		filepath = "plugin/config/"+path;
		data = cfg;
		Read();
		Write();
	}

    function tovalue(str,type) {
        switch(type) {
            case "float":
            case "integer":
            case "string":
                return str["to"+type]();
            case "bool":
                return str.tolower() == "true";
        }
    }

	function Read() {
		local content = "";
        try{content = ::readfile(filepath);}catch(e){return};
		local lines = ::split(content,"\n");
		local table = data;
		foreach (line in lines) {
			try {
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
			  local type = typeof table[key];
              table[key] = tovalue(str,type);
            }catch(e) {
                ::print(::format("Config Read Error @%s:%s\n->%s\n",filepath,line,e));
            }
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
