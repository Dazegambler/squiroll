this.task <- {};

function register(src){
    if ("OnSettingChange" in src){
        this.task[src] <- src.OnSettingChange;
    }
}

function unregister(src){
    delete this.task[src];
}

function OnChange() {
    foreach(src,onchange in task) {
        if(src == null){
            this.unregister(src);
            continue;
        }
        onchange.call(src);
    }
}