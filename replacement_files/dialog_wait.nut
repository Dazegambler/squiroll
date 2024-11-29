function Initialize()
{
	this.Update = ::menu.network.dialog_wait.Update;
}

function InitializeWithUPnP()
{
	::menu.network.dialog_wait.Initialize.call(this);

	if (::config.network.upnp)
	{
		this.obj[1].y = -40;
		local action = ::menu.network;

		foreach( i, v in action.item_table.upnp_state )
		{
			local t = ::font.CreateSystemString(v);
			t.sx = t.sy = 0.66000003;
			t.y = 10;
			this.obj.append(t);
		}

		this.obj[2].x = -this.obj[2].width * this.obj[2].sx - 8;
		this.obj[3].green = 0;
		this.obj[3].blue = 0;
		this.obj[4].blue = 0;
		this.obj[5].red = 0;
		this.Update = ::menu.network.dialog_wait.Update2;
	}
}

function Update()
{
	if (::menu.network.display_ip_on_wait && ::punch.ip_available()) {
		this.obj[1].Set(
			::setting.misc.hide_ip ? ::menu.network.item_table.wait_incomming[0] + " " + "press C to copy the ip" :
			::menu.network.item_table.wait_incomming[0] + " " + ::punch.get_ip());
		this.obj[1].x = 20 + -this.obj[1].width / 2;
	}
	::menu.cursor.SetTarget(this.obj[1].x - 20 + ::graphics.width / 2, this.obj[1].y + 24 + ::graphics.height / 2, 0.69999999);
	::menu.network.update();
}

function Update2()
{
	local upnp_state = ::UPnP.GetAsyncState();

	switch(::UPnP.GetAsyncState())
	{
	case 0:
		this.obj[3].visible = true;
		this.obj[4].visible = false;
		this.obj[5].visible = false;
		break;

	case 1:
		this.obj[3].visible = false;
		this.obj[4].visible = true;
		this.obj[5].visible = false;
		break;

	case 2:
		if (::UPnP.GetExternalIP() == "")
		{
			this.obj[3].visible = true;
			this.obj[4].visible = false;
			this.obj[5].visible = false;
		}
		else
		{
			this.obj[3].visible = false;
			this.obj[4].visible = false;
			this.obj[5].visible = true;
		}

		break;

	case 3:
		this.obj[3].visible = false;
		this.obj[4].visible = true;
		this.obj[5].visible = false;
		break;
	}

	::menu.network.dialog_wait.Update.call(this);
}
