// this.actors <- [];

// function Tick(p1,p2){
//     actors.append(p1);
//     actors.append(p2);
//     ::rollback.TickA(this.actors);
//     this.actors = [];
// }

// //[{table_ref={};table_ref={};},{}...]
// this.data <- [];
// // this.actors <- {};
// this.bullets <- {};
// this.index <- 0;

// function _merge(lhs,rhs){
//     foreach(i,v in rhs){
//         local type = typeof(v);
//         if (type == "table"    ||
//             type == "class"    ||
//             type == "instance" ){
//             this._merge(lhs[i],v);
//             continue;
//         }
//         lhs[i] = v;
//     }
// };

// function merge(lhs,rhs) {
//     return this._merge(lhs,rhs);
// }

// function store_team(team) {
//     return {
//         current = team.current
//         diff = {
//             op_stop = team.op_stop
//             op_stop_max = team.op_stop_max
//             combo_count = team.combo_count
//             combo_damage = team.combo_damage
//             damage_scale = team.damage_scale
//             combo_stun = team.combo_stun
//             life = team.life
//             damage_life = team.damage_life
//             current = {
//                 // command = {
//                 //     rsv_k3_r = team.current.command.rsv_k3_r
//                 //     ban_b = team.current.command.ban_b
//                 //     reserve_count = team.current.command.reserve_count
//                 //     rsv_k12 = team.current.command.rsv_k12
//                 //     rsv_k3 = team.current.command.rsv_k3
//                 //     rsv_k2 = team.current.command.rsv_k2
//                 //     rsv_k1 = team.current.command.rsv_k1
//                 //     ban_slide = team.current.command.ban_slide
//                 //     rsv_k0 = team.current.command.rsv_k0
//                 //     rsv_k5 = team.current.command.rsv_k5
//                 //     rsv_k4 = team.current.command.rsv_k4
//                 //     rsv_y = team.current.command.rsv_y
//                 //     rsv_x = team.current.command.rsv_x
//                 //     rsv_k01 = team.current.command.rsv_k01
//                 //     rsv_k23 = team.current.command.rsv_k23
//                 // }
//                 x = team.current.x
//                 y = team.current.y
//                 z = team.current.z
//                 vx = team.current.vx
//                 vy = team.current.vy
//                 direction = team.current.direction
//             }
//         }
//         calls = [
//             [team.current.SetMotion,[team.current,team.current.motion,team.current.keyTake]]
//         ]
//     };
// }

// function store_bullet(bullet){
//     return {
//         x = bullet.x
//         y = bullet.y
//         z = bullet.z
//         vx = bullet.vx
//         vy = bullet.vy
//         direction = bullet.direction
//         count = bullet.count
//         rz = bullet.rz
//         hitCount = bullet.hitCount
//         // flag1 = bullet.flag1
//         // flag2 = bullet.flag2
//         // flag3 = bullet.flag3
//         // flag4 = bullet.flag4
//         // flag5 = bullet.flag5
//     };
// }

// function undo_players(new_data){
//     foreach(i,t in ::battle.team){
//         local diff = new_data[t];

//         local char = t.current;

//         if(t.current != diff.current)char.Team_Change_Slave(null);
//         merge(t,diff.diff);
//         foreach(func in diff.calls)func[0].acall(func[1]);
//         // foreach(k,v in data){
//         //     if(k == "current")continue;
//         //     if(typeof(v) == "array"){
//         //         v[0].acall(v[1]);
//         //         continue;
//         //     }
//         //     char[k] = v;
//         // }
//     }
// }

// function undo_bullets(new_data){
//     // foreach(k,v in new_data)k
// }

// function neverHappened(frames){
//     while (this.index){
//         this.index--;
//         if(!--frames)break;
//     }
//     local archive = this.data[index];
//     this.undo_players(archive[0]);
//     // foreach(k,v in archive[1]){
//     //     this.undo(k,v);
//     // }
// }


// function internetArchive(){
//     if(this.data.len() > ++this.index){
//         this.data[this.index] = [];
//     }else{
//         this.data.append([]);
//     }
//     local diff = this.data.top();

//     diff.append({});
//     local players = diff.top();
//     foreach(t in ::battle.team)players[t] <- this.store_team(t);

//     // diff.append({});
//     // local bullets = diff.top();
//     // foreach(k,v in this.bullets)bullets[k] <- this.store_bullet(v);

//     // this.bullets = {};
// }
this.timeline <- [];
this.rollback_frames <- 4;

function InternetArchive() {
    local t0 = ::battle.team[0];
    local t1 = ::battle.team[1];
    if (::input_all.b7) {
        if (this.timeline.len()) {
            local prev = this.timeline.pop();

            // ::battle.team[0] = prev.team0;
            // t0.current.x = prev.current_x;
            // t0.current.y = prev.current_y;
        }
    }else {
        this.timeline.append({
            // current_x = t0.current.x
            // current_y = t0.current.y
            team0 = ::deepcopy(t0)
            // team1 = ::deepcopy(::battle.team[1])
        });
    }
}

function IsStored(actor) {
    for (local i = 0;i < this.timeline.len();++i) {
        if (actor in this.timeline[i])return true;
    }
    return false;
}

function ResetTimeline() {
    delete this.timeline;
    this.timeline <- [{}];
}

function NeverHappened(frames) {
    local top = this.timeline.len() - 1;
    local new_timeline = ::math.clamp(top - frames,0,top);
    foreach(k,v in this.timeline[new_timeline])k = v;//k.RestoreState(v);
    while ((this.timeline.len() - 1) > new_timeline)this.timeline.pop();
}
