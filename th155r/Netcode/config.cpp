#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <limits>
#include <charconv>
#include <system_error>

#include <windows.h>

#include "util.h"
#include "config.h"
#include "log.h"
#include "shared.h"

static bool use_config = false;
static char CONFIG_FILE_PATH[MAX_PATH];

static constexpr char CONFIG_FILE_NAME[] = "netcode.ini";
static constexpr char TASOFRO_CONFIG_FILE_NAME[] = "config.ini";

#define LOBBY_SECTION_NAME "lobby"
#define LOBBY_HOST_KEY "lobby_server"
#if !USE_DEV_SERVER
#define LOBBY_HOST_DEFAULT "squiroll.justapenguin.ca"
#define LOBBY_HOST_DEFAULT_STR LOBBY_HOST_DEFAULT
#define LOBBY_PORT_KEY "lobby_port"
#define LOBBY_PORT_DEFAULT "5001"
#define LOBBY_PORT_DEFAULT_STR LOBBY_PORT_DEFAULT
#else
#define LOBBY_HOST_DEFAULT "waluigistacostand.ddns.net"
#define LOBBY_HOST_DEFAULT_STR LOBBY_HOST_DEFAULT
#define LOBBY_PORT_KEY "lobby_port"
#define LOBBY_PORT_DEFAULT "1550"
#define LOBBY_PORT_DEFAULT_STR LOBBY_PORT_DEFAULT
#endif
#define LOBBY_PASS_KEY "lobby_password"
#define LOBBY_PASS_DEFAULT "kzxmckfqbpqieh8rw<rczuturKfnsjxhauhybttboiuuzmWdmnt5mnlczpythaxf"
#define LOBBY_PASS_DEFAULT_STR LOBBY_PASS_DEFAULT

#define PING_SECTION_NAME "ping"
#define PING_ENABLED_KEY "enabled"
#define PING_ENABLED_DEFAULT true
#define PING_ENABLED_DEFAULT_STR MACRO_STR(PING_ENABLED_DEFAULT)
#define PING_X_KEY "x"
#define PING_X_DEFAULT 640
#define PING_X_DEFAULT_STR MACRO_STR(PING_X_DEFAULT)
#define PING_Y_KEY "y"
#define PING_Y_DEFAULT 705
#define PING_Y_DEFAULT_STR MACRO_STR(PING_Y_DEFAULT)
#define PING_SCALE_X_KEY "scale_x"
#define PING_SCALE_X_DEFAULT 1.0
#define PING_SCALE_X_DEFAULT_STR MACRO_STR(PING_SCALE_X_DEFAULT)
#define PING_SCALE_Y_KEY "scale_y"
#define PING_SCALE_Y_DEFAULT 1.0
#define PING_SCALE_Y_DEFAULT_STR MACRO_STR(PING_SCALE_Y_DEFAULT)
#define PING_COLOR_KEY "color"
#define PING_COLOR_DEFAULT FFFFFFFF
#define PING_COLOR_DEFAULT_STR MACRO_STR(PING_COLOR_DEFAULT)
#define PING_FRAMES_KEY "frames"
#define PING_FRAMES_DEFAULT true
#define PING_FRAMES_DEFAULT_STR MACRO_STR(PING_FRAMES_DEFAULT)

#define INPUT1_SECTION_NAME "input_display_p1"
#define INPUT1_ENABLED_KEY "enabled"
#define INPUT1_ENABLED_DEFAULT false
#define INPUT1_ENABLED_DEFAULT_STR MACRO_STR(INPUT1_ENABLED_DEFAULT)
#define INPUT1_X_KEY "x"
#define INPUT1_X_DEFAULT 10
#define INPUT1_X_DEFAULT_STR MACRO_STR(INPUT1_X_DEFAULT)
#define INPUT1_Y_KEY "y"
#define INPUT1_Y_DEFAULT 515
#define INPUT1_Y_DEFAULT_STR MACRO_STR(INPUT1_Y_DEFAULT)
#define INPUT1_SCALE_X_KEY "scale_x"
#define INPUT1_SCALE_X_DEFAULT 1.0
#define INPUT1_SCALE_X_DEFAULT_STR MACRO_STR(INPUT1_SCALE_X_DEFAULT)
#define INPUT1_SCALE_Y_KEY "scale_y"
#define INPUT1_SCALE_Y_DEFAULT 1.0
#define INPUT1_SCALE_Y_DEFAULT_STR MACRO_STR(INPUT1_SCALE_Y_DEFAULT)
#define INPUT1_OFFSET_KEY "offset"
#define INPUT1_OFFSET_DEFAULT 30
#define INPUT1_OFFSET_DEFAULT_STR MACRO_STR(INPUT1_OFFSET_DEFAULT)
#define INPUT1_COUNT_KEY "count"
#define INPUT1_COUNT_DEFAULT 12
#define INPUT1_COUNT_DEFAULT_STR MACRO_STR(INPUT1_COUNT_DEFAULT)
#define INPUT1_COLOR_KEY "color"
#define INPUT1_COLOR_DEFAULT FF00FF00
#define INPUT1_COLOR_DEFAULT_STR MACRO_STR(INPUT1_COLOR_DEFAULT)
#define INPUT1_SPACING_KEY "spacing"
#define INPUT1_SPACING_DEFAULT false
#define INPUT1_SPACING_DEFAULT_STR MACRO_STR(INPUT1_SPACING_DEFAULT)
#define INPUT1_TIMER_KEY "timer"
#define INPUT1_TIMER_DEFAULT 200
#define INPUT1_TIMER_DEFAULT_STR MACRO_STR(INPUT1_TIMER_DEFAULT)
#define INPUT1_RAW_INPUT_KEY "raw_input"
#define INPUT1_RAW_INPUT_DEFAULT false
#define INPUT1_RAW_INPUT_DEFAULT_STR MACRO_STR(INPUT1_RAW_INPUT_DEFAULT)

#define MISC_SECTION_NAME "misc"
#define MISC_HIDE_WIP_KEY "hide_wip"
#define MISC_HIDE_WIP_DEFAULT true
#define MISC_HIDE_WIP_DEFAULT_STR MACRO_STR(MISC_HIDE_WIP_DEFAULT)
#define MISC_SKIP_INTRO_KEY "skip_intro"
#define MISC_SKIP_INTRO_DEFAULT true
#define MISC_SKIP_INTRO_DEFAULT_STR MACRO_STR(MISC_SKIP_INTRO_DEFAULT)
#define MISC_CACHE_RSA_KEY "cache_rsa"
#define MISC_CACHE_RSA_DEFAULT true
#define MISC_CACHE_RSA_DEFAULT_STR MACRO_STR(MISC_CACHE_RSA_DEFAULT)
#define MISC_BETTER_GAME_LOOP_KEY "better_game_loop"
#define MISC_BETTER_GAME_LOOP_DEFAULT true
#define MISC_BETTER_GAME_LOOP_DEFAULT_STR MACRO_STR(MISC_BETTER_GAME_LOOP_DEFAULT)

#define INPUT2_SECTION_NAME "input_display_p2"
#define INPUT2_ENABLED_KEY "enabled"
#define INPUT2_ENABLED_DEFAULT false
#define INPUT2_ENABLED_DEFAULT_STR MACRO_STR(INPUT2_ENABLED_DEFAULT)
#define INPUT2_X_KEY "x"
#define INPUT2_X_DEFAULT 1210
#define INPUT2_X_DEFAULT_STR MACRO_STR(INPUT2_X_DEFAULT)
#define INPUT2_Y_KEY "y"
#define INPUT2_Y_DEFAULT 515
#define INPUT2_Y_DEFAULT_STR MACRO_STR(INPUT2_Y_DEFAULT)
#define INPUT2_SCALE_X_KEY "scale_x"
#define INPUT2_SCALE_X_DEFAULT 1.0
#define INPUT2_SCALE_X_DEFAULT_STR MACRO_STR(INPUT2_SCALE_X_DEFAULT)
#define INPUT2_SCALE_Y_KEY "scale_y"
#define INPUT2_SCALE_Y_DEFAULT 1.0
#define INPUT2_SCALE_Y_DEFAULT_STR MACRO_STR(INPUT2_SCALE_Y_DEFAULT)
#define INPUT2_OFFSET_KEY "offset"
#define INPUT2_OFFSET_DEFAULT 30
#define INPUT2_OFFSET_DEFAULT_STR MACRO_STR(INPUT2_OFFSET_DEFAULT)
#define INPUT2_COUNT_KEY "count"
#define INPUT2_COUNT_DEFAULT 12
#define INPUT2_COUNT_DEFAULT_STR MACRO_STR(INPUT2_COUNT_DEFAULT)
#define INPUT2_COLOR_KEY "color"
#define INPUT2_COLOR_DEFAULT FF00FF00
#define INPUT2_COLOR_DEFAULT_STR MACRO_STR(INPUT2_COLOR_DEFAULT)
#define INPUT2_SPACING_KEY "spacing"
#define INPUT2_SPACING_DEFAULT false
#define INPUT2_SPACING_DEFAULT_STR MACRO_STR(INPUT2_SPACING_DEFAULT)
#define INPUT2_TIMER_KEY "timer"
#define INPUT2_TIMER_DEFAULT 200
#define INPUT2_TIMER_DEFAULT_STR MACRO_STR(INPUT2_TIMER_DEFAULT)
#define INPUT2_RAW_INPUT_KEY "raw_input"
#define INPUT2_RAW_INPUT_DEFAULT false
#define INPUT2_RAW_INPUT_DEFAULT_STR MACRO_STR(INPUT2_RAW_INPUT_DEFAULT)

#define NETWORK_SECTION_NAME "network"
#define NETWORK_IPV6_KEY "enable_ipv6"
#define NETWORK_IPV6_DEFAULT "maybe"
#define NETWORK_IPV6_DEFAULT_STR NETWORK_IPV6_DEFAULT
#define NETWORK_NETPLAY_KEY "netplay"
#define NETWORK_NETPLAY_DEFAULT true
#define NETWORK_NETPLAY_DEFAULT_STR MACRO_STR(NETWORK_NETPLAY_DEFAULT)
#define NETWORK_HIDE_IP_KEY "hide_ip"
#define NETWORK_HIDE_IP_DEFAULT false
#define NETWORK_HIDE_IP_DEFAULT_STR MACRO_STR(NETWORK_HIDE_IP_DEFAULT)
#define NETWORK_HIDE_NAME_KEY "hide_name"
#define NETWORK_HIDE_NAME_DEFAULT false
#define NETWORK_HIDE_NAME_DEFAULT_STR MACRO_STR(NETWORK_HIDE_NAME_DEFAULT)

static inline bool create_dummy_file(const char* path) {
	HANDLE handle = CreateFileA(
		path, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
		NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
	);
	if (handle != INVALID_HANDLE_VALUE) {
		CloseHandle(handle);
		return true;
	}
	return false;
}

static inline void set_config_string(const char* section, const char* key, const char* value) {
	WritePrivateProfileStringA(section, key, value, CONFIG_FILE_PATH);
}

enum ConfigTruncType {
	TruncationIsFail,
	AllowTruncation
};

template <ConfigTruncType trunc = TruncationIsFail, size_t N = 0>
static inline size_t get_config_string(const char* section, const char* key, char(&value_buffer)[N]) {
	size_t written = GetPrivateProfileStringA(section, key, NULL, value_buffer, N, CONFIG_FILE_PATH);
	if constexpr (trunc != AllowTruncation) {
		if (expect(written == N - 1, false)) {
			written = 0;
		}
	}
	return written;
}

static inline void fill_default_config_string(const char* section, const char* key, const char* default_value) {
	static char DUMMY[2]{ '\0' };
	if (!GetPrivateProfileStringA(section, key, NULL, DUMMY, 2, CONFIG_FILE_PATH)) {
		WritePrivateProfileStringA(section, key, default_value, CONFIG_FILE_PATH);
	}
}

// ===================
// TEMPLATES
// ===================
template <bool needs_config_enabled = true, size_t N>
static bool get_bool_setting(const char* section, const char* key, char(&buffer)[N], bool default_val) {
	size_t length;
	bool ret = default_val;
	if (
		(!needs_config_enabled || use_config) &&
		(length = get_config_string(section, key, buffer))
	) {
		if (!stricmp(buffer, "true")) {
			ret = true;
		}
		else if (!stricmp(buffer, "false")) {
			ret = false;
		}
	}
	return ret;
}

template <bool needs_config_enabled = true, size_t N>
static int32_t get_int_setting(const char* section, const char* key, char(&buffer)[N], int32_t default_val) {
	size_t length;
	int32_t ret = default_val;
	if (
		(!needs_config_enabled || use_config) &&
		(length = get_config_string(section, key, buffer))
	) {
		std::from_chars(buffer, &buffer[length], ret, 10);
	}
	return ret;
}

template <bool needs_config_enabled = true, size_t N>
static uint32_t get_hex_setting(const char* section, const char* key, char(&buffer)[N], uint32_t default_val) {
	size_t length;
	uint32_t ret = default_val;
	if (
		(!needs_config_enabled || use_config) &&
		(length = get_config_string(section, key, buffer))
	) {
		std::from_chars(buffer, &buffer[length], ret, 16);
	}
	return ret;
}

template <bool needs_config_enabled = true, size_t N>
static float get_float_setting(const char* section, const char* key, char(&buffer)[N], float default_val) {
	size_t length;
	float ret = default_val;
	if (
		(!needs_config_enabled || use_config) &&
		(length = get_config_string<AllowTruncation>(section, key, buffer))
	) {
		std::from_chars(buffer, &buffer[length], ret);
	}
	return ret;
}

#define GET_BOOL_CONFIG(SECTION, KEY) get_bool_setting(MACRO_CAT(SECTION,_SECTION_NAME), MACRO_CAT4(SECTION,_,KEY,_KEY), MACRO_CAT4(SECTION,_,KEY,_BUFFER), MACRO_CAT4(SECTION,_,KEY,_DEFAULT))
#define GET_INT_CONFIG(SECTION, KEY) get_int_setting(MACRO_CAT(SECTION,_SECTION_NAME), MACRO_CAT4(SECTION,_,KEY,_KEY), MACRO_CAT4(SECTION,_,KEY,_BUFFER), MACRO_CAT4(SECTION,_,KEY,_DEFAULT))
#define GET_HEX_CONFIG(SECTION, KEY) get_hex_setting(MACRO_CAT(SECTION,_SECTION_NAME), MACRO_CAT4(SECTION,_,KEY,_KEY), MACRO_CAT4(SECTION,_,KEY,_BUFFER), MACRO_CAT(0x,MACRO_CAT4(SECTION,_,KEY,_DEFAULT)))
#define GET_FLOAT_CONFIG(SECTION, KEY) get_float_setting(MACRO_CAT(SECTION,_SECTION_NAME), MACRO_CAT4(SECTION,_,KEY,_KEY), MACRO_CAT4(SECTION,_,KEY,_BUFFER), MACRO_CAT(MACRO_CAT4(SECTION,_,KEY,_DEFAULT),f))

// ====================
// LOBBY
// ====================

static char LOBBY_HOST_BUFFER[1024]{ '\0' };
const char* get_lobby_host(const char* host) {
	if (
		use_config &&
		get_config_string(LOBBY_SECTION_NAME, LOBBY_HOST_KEY, LOBBY_HOST_BUFFER)
	) {
		host = LOBBY_HOST_BUFFER;
	}
	return host;
}

static char LOBBY_PORT_BUFFER[256]{ '\0' };
const char* get_lobby_port(const char* port) {
	if (
		use_config &&
		get_config_string(LOBBY_SECTION_NAME, LOBBY_PORT_KEY, LOBBY_PORT_BUFFER)
	) {
		port = LOBBY_PORT_BUFFER;
	}
	return port;
}

static char LOBBY_PASS_BUFFER[1024]{ '\0' };
const char* get_lobby_pass(const char* pass) {
	if (
		use_config &&
		get_config_string(LOBBY_SECTION_NAME, LOBBY_PASS_KEY, LOBBY_PASS_BUFFER)
	) {
		pass = LOBBY_PASS_BUFFER;
	}
	return pass;
}

// ====================
// PING
// ====================

static char PING_ENABLED_BUFFER[8]{ '\0' };
bool get_ping_enabled() {
	return GET_BOOL_CONFIG(PING, ENABLED);
}

static char PING_X_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_ping_x() {
	return GET_INT_CONFIG(PING, X);
}

static char PING_Y_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_ping_y() {
	return GET_INT_CONFIG(PING, Y);
}

static char PING_SCALE_X_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_ping_scale_x() {
	return GET_FLOAT_CONFIG(PING, SCALE_X);
}

static char PING_SCALE_Y_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_ping_scale_y() {
	return GET_FLOAT_CONFIG(PING, SCALE_Y);
}

static char PING_COLOR_BUFFER[INTEGER_BUFFER_SIZE<uint32_t>]{ '\0' };
uint32_t get_ping_color() {
	return GET_HEX_CONFIG(PING, COLOR);
}

static char PING_FRAMES_BUFFER[8]{ '\0' };
bool get_ping_frames() {
	return GET_BOOL_CONFIG(PING, FRAMES);
}

// ====================
// INPUT P1
// ====================

static char INPUT1_ENABLED_BUFFER[8]{ '\0' };
bool get_inputp1_enabled() {
	return GET_BOOL_CONFIG(INPUT1, ENABLED);
}

static char INPUT1_X_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp1_x() {
	return GET_INT_CONFIG(INPUT1, X);
}

static char INPUT1_Y_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp1_y() {
	return GET_INT_CONFIG(INPUT1, Y);
}

static char INPUT1_SCALE_X_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_inputp1_scale_x() {
	return GET_FLOAT_CONFIG(INPUT1, SCALE_X);
}

static char INPUT1_SCALE_Y_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_inputp1_scale_y() {
	return GET_FLOAT_CONFIG(INPUT1, SCALE_Y);
}

static char INPUT1_OFFSET_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp1_offset() {
	return GET_INT_CONFIG(INPUT1, OFFSET);
}

static char INPUT1_COUNT_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp1_count() {
	return GET_INT_CONFIG(INPUT1, COUNT);
}

static char INPUT1_COLOR_BUFFER[INTEGER_BUFFER_SIZE<uint32_t>]{ '\0' };
uint32_t get_inputp1_color() {
	return GET_HEX_CONFIG(INPUT1, COLOR);
}

static char INPUT1_SPACING_BUFFER[8]{ '\0' };
bool get_inputp1_spacing() {
	return GET_BOOL_CONFIG(INPUT1, SPACING);
}

static char INPUT1_TIMER_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp1_timer() {
	return GET_INT_CONFIG(INPUT1, TIMER);
}

static char INPUT1_RAW_INPUT_BUFFER[8]{'\0'};
bool get_inputp1_raw_input() {
	return GET_BOOL_CONFIG(INPUT1, RAW_INPUT);
}

// ====================
// INPUT P2
// ====================


static char INPUT2_ENABLED_BUFFER[8]{ '\0' };
bool get_inputp2_enabled() {
	return GET_BOOL_CONFIG(INPUT2, ENABLED);
}

static char INPUT2_X_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp2_x() {
	return GET_INT_CONFIG(INPUT2, X);
}

static char INPUT2_Y_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp2_y() {
	return GET_INT_CONFIG(INPUT2, Y);
}

static char INPUT2_SCALE_X_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_inputp2_scale_x() {
	return GET_FLOAT_CONFIG(INPUT2, SCALE_X);
}

static char INPUT2_SCALE_Y_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_inputp2_scale_y() {
	return GET_FLOAT_CONFIG(INPUT2, SCALE_Y);
}

static char INPUT2_OFFSET_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp2_offset() {
	return GET_INT_CONFIG(INPUT2, OFFSET);
}

static char INPUT2_COUNT_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp2_count() {
	return GET_INT_CONFIG(INPUT2, COUNT);
}

static char INPUT2_COLOR_BUFFER[INTEGER_BUFFER_SIZE<uint32_t>]{ '\0' };
uint32_t get_inputp2_color() {
	return GET_HEX_CONFIG(INPUT2, COLOR);
}

static char INPUT2_SPACING_BUFFER[8]{ '\0' };
bool get_inputp2_spacing() {
	return GET_BOOL_CONFIG(INPUT2, SPACING);
}

static char INPUT2_TIMER_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_inputp2_timer()
{
	return GET_INT_CONFIG(INPUT2, TIMER);
}

static char INPUT2_RAW_INPUT_BUFFER[8]{ '\0' };
bool get_inputp2_raw_input()
{
	return GET_BOOL_CONFIG(INPUT2, RAW_INPUT);
}

// ====================
// NETWORK
// ====================

static char NETWORK_IPV6_BUFFER[8]{ '\0' };
IPv6State get_ipv6_state() {
	size_t length;
	IPv6State ret = IPv6NeedsTest;
	if (
		use_config &&
		(length = get_config_string(NETWORK_SECTION_NAME, NETWORK_IPV6_KEY, NETWORK_IPV6_BUFFER))
	) {
		if (!stricmp(NETWORK_IPV6_BUFFER, "true")) {
			ret = IPv6Enabled;
		}
		else if (!stricmp(NETWORK_IPV6_BUFFER, "false")) {
			ret = IPv6Disabled;
		}
	}
	return ret;
}

static char NETWORK_NETPLAY_BUFFER[8]{ '\0' };
bool get_netplay_state() {
	return GET_BOOL_CONFIG(NETWORK, NETPLAY);
}

static char NETWORK_HIDE_IP_BUFFER[8]{ '\0' };
bool get_hide_ip_enabled() {
	return GET_BOOL_CONFIG(NETWORK, HIDE_IP);
}

static char NETWORK_HIDE_NAME_BUFFER[8]{ '\0' };
bool get_hide_name_enabled() {
	return GET_BOOL_CONFIG(NETWORK, HIDE_NAME);
}

void set_ipv6_state(bool state) {
	set_config_string(NETWORK_SECTION_NAME, NETWORK_IPV6_KEY, bool_str(state));
}

//====================
//MISC
//====================

static char MISC_HIDE_WIP_BUFFER[8]{ '\0' };
bool get_hide_wip_enabled() {
	return GET_BOOL_CONFIG(MISC, HIDE_WIP);
}

static char MISC_SKIP_INTRO_BUFFER[8]{ '\0' };
bool get_skip_intro_enabled() {
	return GET_BOOL_CONFIG(MISC, SKIP_INTRO);
}

static char MISC_CACHE_RSA_BUFFER[8]{ '\0' };
bool get_cache_rsa_enabled() {
	return GET_BOOL_CONFIG(MISC, CACHE_RSA);
}

static char MISC_BETTER_GAME_LOOP_BUFFER[8]{ '\0' };
bool get_better_game_loop_enabled() {
	return GET_BOOL_CONFIG(MISC, BETTER_GAME_LOOP);
}

#define CONFIG_DEFAULT(SECTION, KEY) { MACRO_CAT(SECTION,_SECTION_NAME), MACRO_CAT4(SECTION,_,KEY,_KEY), MACRO_CAT4(SECTION,_,KEY,_DEFAULT_STR) }

static char TASOFRO_GAME_VERSION_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t GAME_VERSION = 1211;

void init_config_file() {
	
	for (
		size_t filename_length = GetModuleFileNameA(NULL, CONFIG_FILE_PATH, countof(CONFIG_FILE_PATH));
		filename_length;
		--filename_length
	) {
		switch (CONFIG_FILE_PATH[filename_length]) {
			case '\\': case '/':
				if (filename_length < countof(CONFIG_FILE_PATH) - countof(TASOFRO_CONFIG_FILE_NAME)) {
					memcpy(&CONFIG_FILE_PATH[filename_length + 1], TASOFRO_CONFIG_FILE_NAME, sizeof(TASOFRO_CONFIG_FILE_NAME));

					if (file_exists(CONFIG_FILE_PATH)) {
						GAME_VERSION = get_int_setting<false>("updater", "version", TASOFRO_GAME_VERSION_BUFFER, 0);
					}
				}
				if (filename_length < countof(CONFIG_FILE_PATH) - countof(CONFIG_FILE_NAME)) {

					memcpy(&CONFIG_FILE_PATH[filename_length + 1], CONFIG_FILE_NAME, sizeof(CONFIG_FILE_NAME));

					if (
						file_exists(CONFIG_FILE_PATH) || create_dummy_file(CONFIG_FILE_PATH)
					) {
						use_config = true;

						constexpr const char* default_configs[][3] = {
							CONFIG_DEFAULT(LOBBY, HOST),
							CONFIG_DEFAULT(LOBBY, PORT),
							CONFIG_DEFAULT(LOBBY, PASS),

							CONFIG_DEFAULT(MISC, HIDE_WIP),
							CONFIG_DEFAULT(MISC, SKIP_INTRO),

							CONFIG_DEFAULT(PING, ENABLED),
							CONFIG_DEFAULT(PING, X),
							CONFIG_DEFAULT(PING, Y),
							CONFIG_DEFAULT(PING, SCALE_X),
							CONFIG_DEFAULT(PING, SCALE_Y),
							CONFIG_DEFAULT(PING, COLOR),
							CONFIG_DEFAULT(PING, FRAMES),

							CONFIG_DEFAULT(INPUT1, ENABLED),
							CONFIG_DEFAULT(INPUT1, X),
							CONFIG_DEFAULT(INPUT1, Y),
							CONFIG_DEFAULT(INPUT1, SCALE_X),
							CONFIG_DEFAULT(INPUT1, SCALE_Y),
							CONFIG_DEFAULT(INPUT1, OFFSET),
							CONFIG_DEFAULT(INPUT1, COUNT),
							CONFIG_DEFAULT(INPUT1, COLOR),
							CONFIG_DEFAULT(INPUT1, SPACING),
							CONFIG_DEFAULT(INPUT1, TIMER),
							CONFIG_DEFAULT(INPUT1, RAW_INPUT),

							CONFIG_DEFAULT(INPUT2, ENABLED),
							CONFIG_DEFAULT(INPUT2, X),
							CONFIG_DEFAULT(INPUT2, Y),
							CONFIG_DEFAULT(INPUT2, SCALE_X),
							CONFIG_DEFAULT(INPUT2, SCALE_Y),
							CONFIG_DEFAULT(INPUT2, OFFSET),
							CONFIG_DEFAULT(INPUT2, COUNT),
							CONFIG_DEFAULT(INPUT2, COLOR),
							CONFIG_DEFAULT(INPUT2, SPACING),
							CONFIG_DEFAULT(INPUT2, TIMER),
							CONFIG_DEFAULT(INPUT2, RAW_INPUT),

							CONFIG_DEFAULT(NETWORK, IPV6),
							CONFIG_DEFAULT(NETWORK, NETPLAY),
							CONFIG_DEFAULT(NETWORK, HIDE_IP),
							CONFIG_DEFAULT(NETWORK, HIDE_NAME),
						};

						nounroll for (size_t i = 0; i < countof(default_configs); ++i) {
							fill_default_config_string(default_configs[i][0], default_configs[i][1], default_configs[i][2]);
						}
					}
				}
				return;
		}
	}
}