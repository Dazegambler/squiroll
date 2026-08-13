lobby_prefix <- "th155_";
lobby_version_sig <- GetVersionSignature();
lobby_name <- "Free";

inst <- null;
inst_connect <- null;
return_code <- -1;
client_num <- 0;

is_client <- false;
is_parent_vs <- false;
is_disconnect <- false;
is_watch <- false;

allow_watch <- false;
hide_host_ip <- true;
host_ip <- "";
use_lobby <- false;
upnp_port <- 0;

local_device_id <- 0;
input_local <- null;
rand_seed <- 0;

player_name <- ["",""];
color_num <- [8,8];
icon <- [null,null];
local_icon <- "";

request <- null;//N
ready <- false;//N

function Initialize() {
    ready = false;
	inst = null;
	inst_connect = null;
	return_code = -1;
	input_local = null;
	is_client = false;
	is_parent_vs = false;
	is_watch = false;
	hide_host_ip = true;
	host_ip = "";
	allow_watch = false;
	is_disconnect = false;
	client_num = 0;
	request = null;
	icon = ["",""];
	func_get_delay <- @()0;
	
    local_icon = ::manbow.Texture().GetBase64("profile.bmp", 32, 32);
    chunked_icon <- [];
    local div = 3;
    local chunk_size = local_icon.len() / div;
    for (local i = 0; i < div; ++i) {
        chunked_icon.push(local_icon.slice(0 + (chunk_size * i), chunk_size * (i + 1)));
    }
}

function Terminate() {
    ::netplay.Terminate();
	request = null;
	if (upnp_port > 0) {
		try ::UPnP.DeletePort(upnp_port, "UDP")
		catch(_e);
		upnp_port = 0;
	}
    
	inst = null;
	inst_connect = null;
	is_disconnect = true;
}

function Disconnect( scene = true ) {
	if (is_disconnect || !IsActive())return;
	is_disconnect = true;

	if (scene) {
		::loop.Fade(function () {
			if (::network.IsActive()) {
				::network.Terminate();
				//::loop.End(::netplay);
			}
		});
	}else::network.Terminate();
}

IsActive <- @()inst != null;
IsPlaying <- @()inst && !is_watch;
IsEnableStreamingBuffer <- @()inst.StreamingPlay();
GetDelay <- @()func_get_delay();

function StartupServer(port,mode) {
	//::netplay.Server(port,mode);
}

function StartupClient(addr,port,mode) {
	//::netplay.Client(addr,port,mode);
}

function HostAFK() {
    inst.HostAFK();
}

function CancelRequest() {
    inst.CancelRequest();	
}

function AcceptMatch() {
	inst.AcceptMatch();
}

function RejectMatch() {
	inst.RejectMatch();
}

function BeginStreaming() {
	inst.BeginStreaming();
}

function EndStreaming() {
	inst.EndStreaming();
}

function BeginStreamingPlay( func_begin, func_end ) {
	inst.BeginStreamingPlay(func_begin, func_end);
}

function GetHostName( _str ) {
	local delimit_pos = _str.find(":");

    if (!delimit_pos)return _str;
	return _str.slice(0, delimit_pos);
}

function GetHostPort( _str ) {
	local delimit_pos = _str.find(":");

    if (!delimit_pos)return null;
	return _str.slice(delimit_pos+1);
}

function GetIPAddress( text ) {
	local ex = regexp("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}:\\d{1,5}");
	local ret = ex.search(text);

    if (!ret)return "";
	return text.slice(ret.begin, ret.end);
}
