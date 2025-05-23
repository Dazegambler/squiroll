//[{table_ref={};table_ref={};},{}...]
this.data <- [];
// this.actors <- {};
this.bullets <- {};
this.index <- 0;

function _merge(lhs,rhs){
    foreach(i,v in rhs){
        local type = typeof(v);
        if (type == "table"    ||
            type == "class"    ||
            type == "instance" ){
            this._merge(lhs[i],v);
            continue;
        }
        lhs[i] = v;
    }
};

function merge(lhs,rhs) {
    return this._merge(lhs,rhs);
}

function store_team(team) {
    return {
        current = team.current
        diff = {
            combo_count = team.combo_count
            combo_damage = team.combo_damage
            damage_scale = team.damage_scale
            combo_stun = team.combo_stun
            life = team.life
            damage_life = team.damage_life
            current = {
                x = team.current.x
                y = team.current.y
                z = team.current.z
                vx = team.current.vx
                vy = team.current.vy
                direction = team.current.direction
                // hit_state = team.current.hit_state
            }
        }
        calls = [
            [team.current.SetMotion,[team.current,team.current.motion,team.current.keyTake]]
        ]
    };
}

function store_bullet(bullet){
    return {
        x = bullet.x
        y = bullet.y
        z = bullet.z
        vx = bullet.vx
        vy = bullet.vy
        direction = bullet.direction
        count = bullet.count
        rz = bullet.rz
        hitCount = bullet.hitCount
        // flag1 = bullet.flag1
        // flag2 = bullet.flag2
        // flag3 = bullet.flag3
        // flag4 = bullet.flag4
        // flag5 = bullet.flag5
    };
}

function undo_players(new_data){
    foreach(t in ::battle.team){
        local diff = new_data[t];

        local char = t.current;

        if(char != diff.current)char.Team_Change_Slave(null);

        merge(t,diff.diff);
        foreach(func in diff.calls)func[0].acall(func[1]);
        // foreach(k,v in data){
        //     if(k == "current")continue;
        //     if(typeof(v) == "array"){
        //         v[0].acall(v[1]);
        //         continue;
        //     }
        //     char[k] = v;
        // }
    }
}

function undo_bullets(new_data){
    // foreach(k,v in new_data)k
}

function neverHappened(frames){
    while (this.index){
        this.index--;
        if(!--frames)break;
    }
    local archive = this.data[index];
    if(archive[0].len()){
        this.undo_players(archive[0]);
        // foreach(k,v in archive[1]){
        //     this.undo(k,v);
        // }
    }
}

function internetArchive(){
    if(this.data.len() > ++this.index){
        this.data[this.index] = [];
    }else{
        this.data.append([]);
    }
    local diff = this.data.top();

    diff.append({});
    local players = diff.top();
    foreach(t in ::battle.team)players[t] <- this.store_team(t);

    // diff.append({});
    // local bullets = diff.top();
    // foreach(k,v in this.bullets)bullets[k] <- this.store_bullet(v);

    // this.bullets = {};
}