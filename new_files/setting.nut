this.task <- {};

function register(src,callback){
    this.task[src] <- callback;
}

function unregister(src){
    delete this.task[src];
}

function OnChange() {
    foreach(src,t in task) {
        if(src == null){
            this.unregister(src);
            continue;
        }
        t.call(src);
    }
}