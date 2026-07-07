function CheckDirectoryExisted( _st_dirname )
{
	local attr = ::libact.GetFileAttributes(_st_dirname);

	if (attr == -1 || (attr & 16) == 0)
	{
		if (attr == -1)
		{
			::manbow.CreateDirectory(_st_dirname);
			local attr = ::libact.GetFileAttributes(_st_dirname);

			if (attr == -1 || (attr & 16) == 0)
			{
				::libact.MessageBox("\x2514s‚\x2554•K—v‚\x255aƒfƒBƒŒƒNƒgƒŠ‚\x2560\x221e¬‚\x2554\x2555”s‚\x2561‚\x2584‚\x2561‚\x255c");
				this.ExitGame();
				return false;
			}
		}
		else
		{
			::libact.MessageBox("\x2514s‚\x2554•K—v‚\x255aƒfƒBƒŒƒNƒgƒŠ‚\x2560\x221e¬‚\x2554\x2555”s‚\x2561‚\x2584‚\x2561‚\x255c");
			this.ExitGame();
			return false;
		}
	}

	return true;
}


if (!this.CheckDirectoryExisted("ss"))
{
	::libact.CloseMainWindow();
	return;
}

if (!this.CheckDirectoryExisted("replay"))
{
	::libact.CloseMainWindow();
	return;
}

if (!this.CheckDirectoryExisted("macro"))
{
	::libact.CloseMainWindow();
	return;
}

::manbow.CompileFile("data/script/const.nut", this.getroottable());
::manbow.CompileFile("data/script/const_key.nut", this.getroottable());
::manbow.CompileFile("data/script/version.nut", this.getroottable());
::loop <- {};
::manbow.CompileFile("data/script/loop.nut", ::loop);
::manbow.CompileFile("data/script/name.nut", this.getroottable());
::manbow.CompileFile("data/script/component.nut", this.getroottable());
::config <- {};
::manbow.CompileFile("data/script/config.nut", ::config);
::savedata <- {};
::manbow.CompileFile("data/script/savedata.nut", ::savedata);
::input <- {};
::manbow.CompileFile("data/script/input.nut", ::input);
::sound <- {};
::manbow.CompileFile("data/script/sound.nut", ::sound);
::graphics <- {};
::manbow.CompileFile("data/script/graphics.nut", ::graphics);
::network <- {};
::manbow.CompileFile("data/system/component/network.nut", ::network);
::netplay <- {};
::manbow.CompileFile("squiroll/network/netplay.nut",::netplay);
::font <- {};
::manbow.CompileFile("data/script/font.nut", this.font);
::effect <- {};
::manbow.CompileFile("data/script/effect.nut", this.effect);
::boot <- {};
::manbow.CompileFile("data/system/boot/boot.nut", ::boot);
::config.Apply();
::Vector3 <- ::manbow.Vector3;
::Matrix <- ::manbow.Matrix;
