common <- {};
::manbow.CompileFile("data/system/component/menu_common.nut", common);
::UI <- {};
::manbow.CompileFile("UI.nut", ::UI);
local scene = [];
cursor <- {};
::manbow.CompileFile("data/system/cursor/cursor.nut", cursor);
scene.append(cursor);
title <- {};
::manbow.CompileFile("data/system/title/title.nut", title);
story_select <- {};
::manbow.CompileFile("data/system/select/script/story_select_action.nut", story_select);
character_select <- {};
::manbow.CompileFile("data/system/select/script/character_select_action.nut", character_select);
back <- {};
::manbow.CompileFile("data/system/back/back.nut", back);
network <- {};
::manbow.CompileFile("data/system/network/network.nut", network);
scene.append(network);
watch <- {};
::manbow.CompileFile("data/system/watch/watch.nut", watch);
scene.append(watch);
music_room <- {};
::manbow.CompileFile("data/system/music_room/music_room.nut", music_room);
scene.append(music_room);
replay_select <- {};
::manbow.CompileFile("data/system/replay_select/replay_select.nut", replay_select);
scene.append(replay_select);
pause <- {};
::manbow.CompileFile("data/system/pause/pause.nut", pause);
scene.append(pause);
tutorial <- {};
::manbow.CompileFile("data/system/tutorial/tutorial.nut", tutorial);
scene.append(tutorial);
practice <- {};
::manbow.CompileFile("data/system/practice/practice.nut", practice);
scene.append(practice);
config <- {};
::manbow.CompileFile("data/system/config/config.nut", config);
scene.append(config);
key_config <- {};
::manbow.CompileFile("data/system/key_config/key_config.nut", key_config);
scene.append(key_config);
help <- {};
::manbow.CompileFile("data/system/help/help.nut", help);
scene.append(help);
mod_config <- {};
::manbow.CompileFile("mod_config.nut", mod_config);
scene.append(mod_config);
network_config <- {};
::manbow.CompileFile("network_config.nut", network_config);
scene.append(network_config);


pause_hack <- false;
PauseInitializeOrig <- pause.Initialize;
pause.Initialize = function(_mode) {
	::menu.pause_hack = true;
	::overlay.clear();
	::menu.PauseInitializeOrig.call(this, _mode);
}
PracticeInitializeOrig <- practice.Initialize;
practice.Initialize = function() {
	::menu.pause_hack = true;
	::overlay.clear();
	::menu.PracticeInitializeOrig.call(this);
}

foreach (key,str in {
	["copy_host"]="copy IP/port to clipboard",
	["copy_watch"]="copy watch IP/port to clipboard"
}) {
	help.src[0][key] <- help.func_init_text(str);
	help.src[1][key] <- help.func_init_text(str);
}
function BeginAct()
{
	act.pl.BeginStage(0);
	::loop.DeleteTask(_act_task);
}

function EndAct()
{
	act.pl.EndStage();

	if ("Terminate" in act.global)
	{
		act.global.Terminate();
	}

	::loop.DeleteTask(_act_task);
}

function EndActDelayed( delay = 30 )
{
	_act_task.count = delay;
	::loop.AddTask(_act_task);
}

class EndActDelayedTask
{
	act = null;
	count = 0;
	function Update()
	{
		if (count-- == 0)
		{
			act.pl.EndStage();

			if ("Terminate" in act.global)
			{
				act.global.Terminate();
			}

			::loop.DeleteTask(this);
		}
	}

}

function BeginAnime()
{
	::loop.DeleteTask(_anime_task);
	anime.Initialize();
}

function EndAnime()
{
	::loop.DeleteTask(_anime_task);

	if ("Terminate" in anime)
	{
		anime.Terminate();
	}
}

function EndAnimeDelayed( delay = 30 )
{
	_anime_task.count = delay;
	::loop.AddTask(_anime_task);
}

class EndAnimeDelayedTask
{
	anime = null;
	count = 0;
	function Update()
	{
		if (count-- == 0)
		{
			anime.Terminate();
			::loop.DeleteTask(this);
		}
	}

}


foreach( v in scene )
{
	if ("act" in v)
	{
		v._act_task <- EndActDelayedTask();
		v._act_task.act = v.act.weakref();
		v.BeginAct <- BeginAct;
		v.EndAct <- EndAct;
		v.EndActDelayed <- EndActDelayed;
	}

	if ("anime" in v)
	{
		v._anime_task <- EndAnimeDelayedTask();
		v._anime_task.anime = v.anime.weakref();
		v.BeginAnime <- BeginAnime;
		v.EndAnime <- EndAnime;
		v.EndAnimeDelayed <- EndAnimeDelayed;
	}
}
