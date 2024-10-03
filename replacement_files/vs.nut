class this.InitializeParam
{
	game_mode = 1;
	difficulty = 0;
	device_id = [];
	mode = [];
	master_name = [];
	slave_name = [];
	master_color = [];
	slave_color = [];
	spell = [];
	background_id = 26;
	bgm_id = 1;
	seed = 0;
	param_list = [
		"difficulty",
		"mode",
		"master_name",
		"master_color",
		"slave_name",
		"slave_color",
		"spell",
		"background_id",
		"bgm_id",
		"seed"
	];
	constructor()
	{
		this.device_id = [
			-2,
			-2
		];
		this.mode = [
			0,
			0
		];
		this.master_name = [
			null,
			null
		];
		this.slave_name = [
			null,
			null
		];
		this.master_color = [
			0,
			0
		];
		this.slave_color = [
			0,
			0
		];
		this.spell = [
			0,
			0
		];
	}

}

function Initialize( param )
{
	if (::network.IsPlaying())
	{
		::network.input_local = ::input.CreatePlayerInputDeviceLocal(0, ::network.local_device_id);
		::network.inst.BeginSyncInput(::network.input_local, 2, false);
	}

	if (::replay.GetState() == ::replay.NONE)
	{
		::replay.Create(param.game_mode);
		::replay.SetUserData(param, param.param_list);
	}

	local battle_param = ::battle.InitializeParam();
	battle_param.game_mode = param.game_mode;
	battle_param.seed = param.seed;

	if (::network.IsPlaying())
	{
		::network.BeginStreaming();
	}

	for( local i = 0; i < 2; i = ++i )
	{
		battle_param.team[i].master = ::actor.CreatePlayer("master" + i, param.master_name[i], param.master_color[i], param.mode[i], param.difficulty);
		battle_param.team[i].slave = ::actor.CreatePlayer("slave" + i, param.slave_name[i], param.slave_color[i] + 100, param.mode[i], param.difficulty);
		battle_param.team[i].master_spell = param.spell[i];
		battle_param.team[i].device_id = param.device_id[i];
	}

	::stage.Load(param.background_id);
	::sound.PreLoadBGM(param.bgm_id);
	::battle.Create(battle_param);
	::battle.Begin();
	::loop.Begin(this);
	displayAllElements(battle_param.team[0],"");
}

function displayAllElements(obj,indent) {
	indent += " ";
    ::rollback.fprint("output.txt",indent+"----"+obj+"----\n");

    foreach (key, value in obj) {
        ::rollback.fprint("output.txt",indent+key + " : " + typeof(value) + "\n");

        if (typeof(value) == "table" || typeof(value) == "class") {
            displayAllElements(value,indent);
        }
    }
	::rollback.fprint("output.txt",indent+"---------------\n")
}

function Terminate()
{
	if (::network.IsPlaying())
	{
		::network.EndStreaming();
	}

	::battle.Release();
	::stage.Clear();
	::actor.Clear();
	::replay.Reset();
}

function Update()
{
	::battle.Update();
}

