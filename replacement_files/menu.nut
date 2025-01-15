this.common <- {};
::manbow.CompileFile("data/system/component/menu_common.nut", this.common);
local scene = [];
this.cursor <- {};
::manbow.CompileFile("data/system/cursor/cursor.nut", this.cursor);
scene.append(this.cursor);
this.title <- {};
::manbow.CompileFile("data/system/title/title.nut", this.title);
this.story_select <- {};
::manbow.CompileFile("data/system/select/script/story_select_action.nut", this.story_select);
this.character_select <- {};
::manbow.CompileFile("data/system/select/script/character_select_action.nut", this.character_select);
this.back <- {};
::manbow.CompileFile("data/system/back/back.nut", this.back);
this.network <- {};
::manbow.CompileFile("data/system/network/network.nut", this.network);
scene.append(this.network);
this.watch <- {};
::manbow.CompileFile("data/system/watch/watch.nut", this.watch);
scene.append(this.watch);
this.music_room <- {};
::manbow.CompileFile("data/system/music_room/music_room.nut", this.music_room);
scene.append(this.music_room);
this.replay_select <- {};
::manbow.CompileFile("data/system/replay_select/replay_select.nut", this.replay_select);
scene.append(this.replay_select);
this.pause <- {};
::manbow.CompileFile("data/system/pause/pause.nut", this.pause);
scene.append(this.pause);
this.tutorial <- {};
::manbow.CompileFile("data/system/tutorial/tutorial.nut", this.tutorial);
scene.append(this.tutorial);
this.practice <- {};
::manbow.CompileFile("data/system/practice/practice.nut", this.practice);
scene.append(this.practice);
this.config <- {};
::manbow.CompileFile("data/system/config/config.nut", this.config);
scene.append(this.config);
this.key_config <- {};
::manbow.CompileFile("data/system/key_config/key_config.nut", this.key_config);
scene.append(this.key_config);
this.help <- {};
::manbow.CompileFile("data/system/help/help.nut", this.help);
scene.append(this.help);

this.pause_hack <- false;
this.PauseInitializeOrig <- this.pause.Initialize;
this.pause.Initialize = function(_mode) {
	::menu.pause_hack = true;
	::overlay.clear();
	::menu.PauseInitializeOrig.call(this, _mode);
}
this.PracticeInitializeOrig <- this.practice.Initialize;
this.practice.Initialize = function() {
	::menu.pause_hack = true;
	::overlay.clear();
	::menu.PracticeInitializeOrig.call(this);
}

foreach (key,str in {
	["copy_host"]="copy IP/port to clipboard",
	["copy_watch"]="copy watch IP/port to clipboard"
}) {
	this.help.src[0][key] <- this.help.func_init_text(str);
	this.help.src[1][key] <- this.help.func_init_text(str);
}
//this.mod_config <- {};
//::manbow.compilebuffer("mod_config.nut", this.mod_config);
function BeginAct()
{
	this.act.pl.BeginStage(0);
	::loop.DeleteTask(this._act_task);
}

function EndAct()
{
	this.act.pl.EndStage();

	if ("Terminate" in this.act.global)
	{
		this.act.global.Terminate();
	}

	::loop.DeleteTask(this._act_task);
}

function EndActDelayed( delay = 30 )
{
	this._act_task.count = delay;
	::loop.AddTask(this._act_task);
}

class this.EndActDelayedTask
{
	act = null;
	count = 0;
	function Update()
	{
		if (this.count-- == 0)
		{
			this.act.pl.EndStage();

			if ("Terminate" in this.act.global)
			{
				this.act.global.Terminate();
			}

			::loop.DeleteTask(this);
		}
	}

}

function BeginAnime()
{
	::loop.DeleteTask(this._anime_task);
	this.anime.Initialize();
}

function EndAnime()
{
	::loop.DeleteTask(this._anime_task);

	if ("Terminate" in this.anime)
	{
		this.anime.Terminate();
	}
}

function EndAnimeDelayed( delay = 30 )
{
	this._anime_task.count = delay;
	::loop.AddTask(this._anime_task);
}

class this.EndAnimeDelayedTask
{
	anime = null;
	count = 0;
	function Update()
	{
		if (this.count-- == 0)
		{
			this.anime.Terminate();
			::loop.DeleteTask(this);
		}
	}

}


foreach( v in scene )
{
	if ("act" in v)
	{
		v._act_task <- this.EndActDelayedTask();
		v._act_task.act = v.act.weakref();
		v.BeginAct <- this.BeginAct;
		v.EndAct <- this.EndAct;
		v.EndActDelayed <- this.EndActDelayed;
	}

	if ("anime" in v)
	{
		v._anime_task <- this.EndAnimeDelayedTask();
		v._anime_task.anime = v.anime.weakref();
		v.BeginAnime <- this.BeginAnime;
		v.EndAnime <- this.EndAnime;
		v.EndAnimeDelayed <- this.EndAnimeDelayed;
	}
}
