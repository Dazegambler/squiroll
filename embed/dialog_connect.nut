function Initialize()
{
	Update = ::menu.network.dialog_connect.Update;
}

function Update()
{
	if (::network.IsPlaying()) {
		obj[1].Set("Request Sent,Awaiting approval...");
		obj[1].x = 20 + -obj[1].width / 2;
	}
	::menu.cursor.SetTarget(obj[1].x - 20 + ::graphics.width / 2, obj[1].y + 24 + ::graphics.height / 2, 0.69999999);
	::menu.network.UpdateWaitClient();
}

