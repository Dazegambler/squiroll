//.pat files are cursed so we're just hardcoding what
//they're translated to directly in squirrel
//blame tasofro
this.anime_set <- {
    title = {
        name = "title";
        texture_name = "";
        width = 192;
        height = 64;
        left = 0;
        top = 448;
        offset_y = 0;
        offset_x = 0;
        scale_x = 1.0;
        scale_y = 1.0;
        point = [];
    }
};

// this.raw_table <- {
// 	//network
// 	"network.hide_opponent_name" = ["対戦相手の名前を隠す","hide oppponent name","無効","disable","有効","enable"];
// 	"network.hide_ip" = ["アドレスを隠す","hide ip","無効","disable","有効","enable"];
// 	"network.share_watch_ip" = ["シェアマッチアドレス","share watch ip","無効","disable","有効","enable"];
// 	"network.hide_profile_pictures" = ["無効","disable","有効","enable"];
// 	"network.auto_lobby_state_switch" = ["無効","disable","有効","enable"];
// 	//ping display
// 	"ping.enabled" = ["使用可能","enabled","無効","disable","有効","enable"];
// 	"ping.X" = ["X","X"];
// 	"ping.Y" = ["Y","Y"];
// 	"ping.SY" = ["スケールX","scale X"];
// 	"ping.SY" = ["スケールY","scale Y"];
// 	"ping.red" = ["カラーレッド","red"];
// 	"ping.green" = ["カラーグリーン","green"];
// 	"ping.blue" = ["カラーブルー","blue"];
// 	"ping.alpha" = ["カラーアルファ","alpha"];
// 	"ping.input_delay" = ["ショー入力遅延","show input delay","無効","disable","有効","enable"];
// 	//frame data
// 	"frame_data.enabled" = ["使用可能","enabled","無効","disable","有効","enable"];
// 	"frame_data.input_flags" = ["無効","disable","有効","enable"];
// 	"frame_data.frame_stepping" = ["無効","disable","有効","enable"];
// 	"frame_data.X" = ["X","X"];
// 	"frame_data.Y" = ["Y","Y"];
// 	"frame_data.SY" = ["スケールX","scale X"];
// 	"frame_data.SY" = ["スケールY","scale Y"];
// 	"frame_data.red" = ["カラーレッド","red"];
// 	"frame_data.green" = ["カラーグリーン","green"];
// 	"frame_data.blue" = ["カラーブルー","blue"];
// 	"frame_data.alpha" = ["カラーアルファ","alpha"];
// 	"frame_data.timer" = ["表示タイマー","display timer"];
// 	//input display 1
// 	"input_display.p1.enabled" = ["使用可能","enabled","無効","disable","有効","enable"];
// 	"input_display.p1.X" = ["X","X"];
// 	"input_display.p1.Y" = ["Y","Y"];
// 	"input_display.p1.SY" = ["スケールX","scale X"];
// 	"input_display.p1.SY" = ["スケールY","scale Y"];
// 	"input_display.p1.offset" = ["表示項目オフセット","offset"];
// 	"input_display.p1.list_max" = ["最大カウント表示","display max"];
// 	"input_display.p1.red" = ["カラーレッド","red"];
// 	"input_display.p1.green" = ["カラーグリーン","green"];
// 	"input_display.p1.blue" = ["カラーブルー","blue"];
// 	"input_display.p1.alpha" = ["カラーアルファ","alpha"];
// 	"input_display.p1.timer" = ["表示タイマー","display timer"];
// 	"input_display.p1.notation" = ["表記","notation"];
// 	//input_display 2
// 	"input_display.p2.enabled" = ["使用可能","enabled","無効","disable","有効","enable"];
// 	"input_display.p2.X" = ["X","X"];
// 	"input_display.p2.Y" = ["Y","Y"];
// 	"input_display.p2.SY" = ["スケールX","scale X"];
// 	"input_display.p2.SY" = ["スケールY","scale Y"];
// 	"input_display.p2.offset" = ["表示項目オフセット","offset"];
// 	"input_display.p2.list_max" = ["最大カウント表示","display max"];
// 	"input_display.p2.red" = ["カラーレッド","red"];
// 	"input_display.p2.green" = ["カラーグリーン","green"];
// 	"input_display.p2.blue" = ["カラーブルー","blue"];
// 	"input_display.p2.alpha" = ["カラーアルファ","alpha"];
// 	"input_display.p2.timer" = ["表示タイマー","display timer"];
// 	"input_display.p2.notation" = ["表記","notation"];
// };

this.item_table <- {};
this.item_table["/network"] <- {
	hide_opponent_name = {
		text = ["対戦相手の名前を隠す","hide oppponent name"];
		values = ["無効","disable","有効","enable"];
	};
	hide_ip = {
		text = ["アドレスを隠す","hide ip"];
		values = ["無効","disable","有効","enable"];
	};
	share_watch_ip = {
		text = ["シェアマッチアドレス","share watch ip"];
		values = ["無効","disable","有効","enable"];
	};
	hide_profile_pictures = {
		text = ["プロフィール写真を隠す","hide profile pictures"];
		values = ["無効","disable","有効","enable"];
	};
	auto_lobby_state_switch = {
		text = ["オートホスト/オートサーチ","auto host/auto search"];
		values = ["無効","disable","有効","enable"];
	};
};
this.item_table["/ping"] <- {
	enabled = {
		text = ["使用可能","enabled"];
		values = ["無効","disable","有効","enable"];
	};
	X = {
		text = ["X","X"];
	};
	Y = {
		text = ["Y","Y"];
	};
	SX = {
		text = ["スケールX","scale X"];
	};
	SY = {
		text = ["スケールY","scale Y"];
	};
	red = {
		text = ["カラーレッド","red"];
	};
	green = {
		text = ["カラーグリーン","green"];
	};
	blue = {
		text = ["カラーブルー","blue"];
	};
	alpha = {
		text = ["カラーアルファ","alpha"];
	};
	input_delay = {
		text = ["ショー入力遅延","show input delay"];
		values = ["無効","disable","有効","enable"];
	};
};
this.item_table["/frame_data"] <- {
	enabled = {
		text = ["使用可能","enabled"];
		values = ["無効","disable","有効","enable"];
	};
	input_flags = {
		text = ["追加情報を表示する","show flags"];
		values = ["無効","disable","有効","enable"];
	};
	frame_stepping = {
		text = ["手動フレームステップ","manual frame stepping"];
		values = ["無効","disable","有効","enable"];
	};
	X = {
		text = ["X","X"];
	};
	Y = {
		text = ["Y","Y"];
	};
	SX = {
		text = ["スケールX","scale X"];
	};
	SY = {
		text = ["スケールY","scale Y"];
	};
	red = {
		text = ["カラーレッド","red"];
	};
	green = {
		text = ["カラーグリーン","green"];
	};
	blue = {
		text = ["カラーブルー","blue"];
	};
	alpha = {
		text = ["カラーアルファ","alpha"];
	};
	timer = {
		text = ["存続期間","timer"];
	};
};
this.item_table["/input_display/p1"] <- {
	enabled = {
		text = ["使用可能","enabled"];
		values = ["無効","disable","有効","enable"];
	};
	input_flags = {
		text = ["追加情報を表示する","show flags"];
		values = ["無効","disable","有効","enable"];
	};
	offset = {
		text = ["表示項目オフセット","offset"];
	};
	list_max = {
		text = ["最大カウント表示","display max"];
	};
	notation = {
		text = ["表記","notation"];
	};
	X = {
		text = ["X","X"];
	};
	Y = {
		text = ["Y","Y"];
	};
	SX = {
		text = ["スケールX","scale X"];
	};
	SY = {
		text = ["スケールY","scale Y"];
	};
	red = {
		text = ["カラーレッド","red"];
	};
	green = {
		text = ["カラーグリーン","green"];
	};
	blue = {
		text = ["カラーブルー","blue"];
	};
	alpha = {
		text = ["カラーアルファ","alpha"];
	};
	timer = {
		text = ["存続期間","timer"];
	};
};
this.item_table["/input_display/p2"] <- {
	enabled = {
		text = ["使用可能","enabled"];
		values = ["無効","disable","有効","enable"];
	};
	input_flags = {
		text = ["追加情報を表示する","show flags"];
		values = ["無効","disable","有効","enable"];
	};
	offset = {
		text = ["表示項目オフセット","offset"];
	};
	list_max = {
		text = ["最大カウント表示","display max"];
	};
	notation = {
		text = ["表記","notation"];
	};
	X = {
		text = ["X","X"];
	};
	Y = {
		text = ["Y","Y"];
	};
	SX = {
		text = ["スケールX","scale X"];
	};
	SY = {
		text = ["スケールY","scale Y"];
	};
	red = {
		text = ["カラーレッド","red"];
	};
	green = {
		text = ["カラーグリーン","green"];
	};
	blue = {
		text = ["カラーブルー","blue"];
	};
	alpha = {
		text = ["カラーアルファ","alpha"];
	};
	timer = {
		text = ["存続期間","timer"];
	};
};