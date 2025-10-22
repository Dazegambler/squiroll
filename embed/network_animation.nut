anime_set <- ::actor.LoadAnimationData("data/system/network/network.pat");
function Initialize()
{
	action <- ::menu.network.weakref();
	x <- 0;
	y <- 0;
	visible <- true;
	item <- [];
	active <- false;
	texture <- ::manbow.Texture();
	texture.Load("data/system/network/network_font.png");
	local res;
	res = anime_set.title;
	title <- ::manbow.Sprite();
	title.Initialize(texture, res.left, res.top, res.width, res.height);
	item.push(title);
	local item_table = action.item_table;
	::menu.common.InitializeLayout.call(this, null, item_table);
	local item_width = 548;
	local left = ::menu.common.item_x - item_width / 2 - 36;
	local text_table = {};

	foreach( i, v in action.item )
	{
		if (v == null)
		{
			continue;
		}

		local t = text[i];
		t.x = left;
		text_table[v] <- t;
	}

	cursor_x <- left - 20;
	local item_left = 340;
	select_obj <- [];
	player_name <- ::font.CreateSystemString(::config.network.player_name);
	player_name.x = text_table.player_name.x + item_left;
	player_name.y = text_table.player_name.y;
	player_name.blue = 0;
	item.push(player_name);
	port <- ::font.CreateSystemString(::config.network.hosting_port.tostring());
	port.x = text_table.port.x + item_left;
	port.y = text_table.port.y;
	port.blue = 0;
	item.push(port);
	local select_x = left + item_left + 40;
	local _width = item_width - item_left;
	local t = [
		"upnp",
		"allow_watch"
	];

	foreach( v in t )
	{
		if (!("cursor_" + v in action))
		{
			continue;
		}

		select_obj.append(UIItemSelectorSingle(item_table[v].slice(1), text_table[v].x + item_left, text_table[v].y, mat_world, action["cursor_" + v]));
		select_obj.top().SetColor(1, 1, 0);
	}

	select_obj.append(UIItemSelectorSingle(action.room_title, text_table.lobby_select.x + item_left, text_table.lobby_select.y, mat_world, action.cursor_lobby));
	select_obj.top().SetColor(1, 1, 0);
	local a = item_table.lobby_state;
	local t = ::font.CreateSystemString(a[0]);
	t.x = text_table.lobby_incomming.x + item_left;
	t.y = text_table.lobby_incomming.y;
	item.push(t);
	lobby_state <- [];

	for( local i = 1; i < 4; i = ++i )
	{
		local t = ::font.CreateSystemString(a[i]);
		t.x = text_table.lobby_incomming.x + item_left + 200;
		t.y = text_table.lobby_incomming.y;
		item.push(t);
		lobby_state.push(t);
	}

	lobby_state[0].green = 0;
	lobby_state[0].blue = 0;
	lobby_state[1].blue = 0;
	lobby_state[2].red = 0;

	lobby_user_str <- ::font.CreateSystemString("Users: ");
	lobby_user_str.x = 670;
	lobby_user_str.y = 222;
	lobby_user_str.visible = false;
	item.push(lobby_user_str);

	foreach( v in item )
	{
		v.ConnectRenderSlot(::graphics.slot.overlay, 0);
	}

	state <- 0;
	::loop.AddTask(this);
}

function Terminate()
{
	::menu.common.TerminateLayout.call(this);
	title = null;
	item = null;
	lobby_state = null;
	port = null;
	player_name = null;
	select_obj = null;
	texture = null;
	lobby_user_str = null;
	::loop.DeleteTask(this);
}

function Update()
{
	::menu.common.UpdateLayout.call(this, this);
	local state = ::LOBBY.GetNetworkState();

	if (state != ::LOBBY.CLOSED) {
		lobby_user_str.Set("Users: " + ::lobby.user_count());
		lobby_user_str.visible = true;
	} else {
		lobby_user_str.visible = false;
	}

	foreach( v in lobby_state )
	{
		v.visible = false;
	}

	switch(state)
	{
	case 0:
	case 1:
	case 2:
		lobby_state[state].visible = true;
		break;

	default:
		lobby_state[0].visible = true;
		break;
	}

	player_name.Set(::config.network.player_name);
	port.Set(::config.network.hosting_port.tostring());

	foreach( v in select_obj )
	{
		v.Update();
	}

	foreach( v in item )
	{
		v.SetWorldTransform(mat_world);
	}
}
