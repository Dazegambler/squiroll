
function copy(lhs,rhs){
	foreach(i,v in typeof lhs == "instance" ? lhs.getclass() : lhs){
		switch (typeof v) {
			case "table":
			case "class":
			case "instance":
				this.copy(rhs[i] <- {},v);
				break;
			case "float":
			case "integer":
			case "string":
			case "bool":
			case "array":
				rhs[i] <- v;
				break;
		}
	}
};

function StoreState() {
	local data = {};
	this.copy(this,data);
	return data;
}

function merge(lhs,rhs){
	foreach(i,v in typeof lhs == "instance" ? lhs.getclass() : lhs){
		::print("typeof "+i+"="+typeof v+"\n");
		switch (typeof v) {
			case "table":
			case "class":
			case "instance":
				::print("on "+i+"\n");
				this.merge(rhs[i],v);
				break;
			case "float":
			case "integer":
			case "string":
			case "bool":
			case "array":
				rhs[i] = v;
				break;
		}
	}
};

function RestoreState(state) {
	this.merge(state,this);
}

local update = this.Update;
this.Update <- function () {
	update();
	::battle.rollback.timeline.top()[this] <- this.StoreState();
}