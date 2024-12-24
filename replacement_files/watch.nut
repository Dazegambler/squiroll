function Initialize()
{
	this.Begin();
	::loop.Begin(this);
	local texture = ::manbow.Texture();
	texture.Load("data/system/watch/back.png");
	this.sprite <- ::manbow.Sprite();
	this.sprite.Initialize(texture, 0, 0, texture.width, texture.height);
	this.sprite.ConnectRenderSlot(::graphics.slot.ui, 0);
	this.text <- ::font.CreateSystemString(::menu.common.GetMessageText("ready"));
	this.text.x = ::graphics.width - this.text.width - 16;
	this.text.y = ::graphics.height - this.text.height - 16;
	this.text.ConnectRenderSlot(::graphics.slot.ui, 0);
	this.count <- 0;
}

function Terminate()
{
	::network.Disconnect();
	this.sprite = null;
	this.text = null;
}

function Suspend()
{
	this.sprite.DisconnectRenderSlot();
	this.text.DisconnectRenderSlot();
}

function Resume()
{
	this.count = 0;
	this.Begin();
	this.sprite.ConnectRenderSlot(::graphics.slot.ui, 0);
	this.text.ConnectRenderSlot(::graphics.slot.ui, 0);
}

function Update()
{
	this.count++;
	this.text.alpha = this.fabs(this.sin(3.1415 * 2 * this.count / 240));

	if (::input_all.b1 == 1)
	{
		::loop.EndWithFade();
	}
}

function Begin()
{
	::discord.rpc_set_small_img_key("");
	::discord.rpc_set_small_img_text("");
	::discord.rpc_set_large_img_key("mainicon");
    ::discord.rpc_commit_details_and_state("Spectating", "Waiting for match");

	::network.BeginStreamingPlay(function ()
	{
		::replay.Watch();
		local param = this.vs.InitializeParam();
		::replay.GetUserData(param, param.param_list);
		::sound.StopBGM(500);
		::loop.Fade(function ()
		{
			::menu.watch.Suspend();
			::watch.Initialize(param);
		});
	}, function ()
	{
		if (::config.replay.save_mode_online == 0)
		{
			::replay.Save();
		}
		else
		{
		}

		::replay.Reset();
		::loop.EndWithFade();
	});
}

