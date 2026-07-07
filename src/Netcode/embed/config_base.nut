version <- GetVersion();
lang <- 0;
graphics <- {};
graphics.fullscreen <- 0;
graphics.vsync <- 1;
graphics.fps <- 1;
graphics.background <- 0;
input <- {};
input.key <- [{},{}];
input.pad <- [{},{}];

for( local i = 0; i < 2; i = ++i ) {
	local d = input.key[i];
	d.up <- 200;
	d.down <- 208;
	d.left <- 203;
	d.right <- 205;
	d.b0 <- 44;
	d.b1 <- 45;
	d.b2 <- 46;
	d.b3 <- 30;
	d.b4 <- 31;
	d.b10 <- 1;
	d.t0 <- -2;
	d.t1 <- -2;
	d.t2 <- -2;
	d = input.pad[i];
	d.up <- 516;
	d.down <- 513;
	d.left <- 515;
	d.right <- 512;
	d.b0 <- 0;
	d.b1 <- 1;
	d.b2 <- 2;
	d.b3 <- 3;
	d.b4 <- 4;
	d.b10 <- 5;
	d.t0 <- -2;
	d.t1 <- -2;
	d.t2 <- -2;
}

sound <- {};
sound.se <- 50;
sound.bgm <- 50;
network <- {};
network.hosting_port <- 10800;
network.target_host <- "127.0.0.1";
network.target_port <- 10800;
network.lobby_name <- "";
network.upnp <- false;
network.allow_watch <- true;
network.player_name <- "";
network.uuid <- "";
network.elo <- 1000;

replay <- {};
replay.version_dir <- false;
replay.daily_dir <- false;
replay.save_mode <- 1;
replay.save_mode_online <- 1;

practice <- {};
practice.position <- [0,0];
practice.life <- [5,5];
practice.regain <- [5,5];
practice.mp <- [6,6];
practice.op <- [5,5];
practice.sp <- [3,3];
practice.guard <- [6,6];
practice.master <- [{},{}];
practice.slave <- [{},{}];
practice.marisa <- [0,0];
practice.hijiri <- [0,0];
practice.futo <- [0,0];
practice.miko <- [0,0];
practice.mamizou <- [0,0];
practice.kokoro <- [0,0];
practice.udonge <- [0,0];
practice.doremy <- [0,0];
practice.player2 <- 0;
practice.difficulty <- 0;
practice.counter_mode <- 0;
practice.guard_mode <- 0;
practice.ex_guard_mode <- 0;
practice.recover_mode <- 0;
practice.slave_2p <- 0;
practice.macro_index <- 0;

difficulty <- {};
difficulty.story <- 1;
difficulty.vs <- 1;

function Initialize(){}
function Save() {
	return ::manbow.SaveTable("system.dat", this);
}

//this may be some really special squirrel jank
function Load() {
	if (::manbow.LoadTableEx("system.dat", this, false)) {
		return;
	}
	return;
}

function Apply() {
	::sound.SetVolumeSE(sound.se / 100.00000000);
	::sound.SetVolumeBGM(sound.bgm / 100.00000000);
	::SetWindowMode(0, 0, graphics.fullscreen, graphics.vsync, false);
}


if (!Load()) {
	Save();
}
