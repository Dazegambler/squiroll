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

static bool use_config = false;
static char CONFIG_FILE_PATH[MAX_PATH];

static constexpr char CONFIG_FILE_NAME[] = "\\netcode.ini";

#define LOBBY_SECTION_NAME "lobby"
#define LOBBY_HOST_KEY "lobby_server"
#define LOBBY_HOST_DEFAULT "waluigistacostand.ddns.net"
#define LOBBY_PORT_KEY "lobby_port"
#define LOBBY_PORT_DEFAULT "1550"
#define LOBBY_PASS_KEY "lobby_password"
#define LOBBY_PASS_DEFAULT "kzxmckfqbpqieh8rw<rczuturKfnsjxhauhybttboiuuzmWdmnt5mnlczpythaxf"

#define PING_SECTION_NAME "ping"
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

#define NETWORK_SECTION_NAME "network"
#define NETWORK_IPV6_KEY "enable_ipv6"
#define NETWORK_IPV6_DEFAULT "maybe"

/*
static constexpr char DEFAULT_CONFIG[] =
"[" LOBBY_SECTION_NAME "]\n"
LOBBY_HOST_KEY "=" LOBBY_HOST_DEFAULT "\n"
LOBBY_PORT_KEY "=" LOBBY_PORT_DEFAULT "\n"
LOBBY_PASS_KEY "=" LOBBY_PASS_DEFAULT "\n"
"[" PING_SECTION_NAME "]\n"
PING_X_KEY "=" PING_X_DEFAULT_STR "\n"
PING_Y_KEY "=" PING_Y_DEFAULT_STR "\n"
PING_SCALE_X_KEY "=" PING_SCALE_X_DEFAULT_STR "\n"
PING_SCALE_Y_KEY "=" PING_SCALE_Y_DEFAULT_STR "\n"
;
*/

/*
static inline bool create_default_file(const char* path) {
	HANDLE handle = CreateFileA(
		path, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE,
		NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL
	);
	if (handle != INVALID_HANDLE_VALUE) {
		DWORD idc;
		bool ret = WriteFile(handle, (LPCVOID)DEFAULT_CONFIG, sizeof(DEFAULT_CONFIG) - sizeof(DEFAULT_CONFIG[0]), &idc, NULL) != FALSE;
		CloseHandle(handle);
		return ret;
	}
	return false;
}
*/

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

static char PING_X_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_ping_x() {
	size_t length;
	int32_t ret = PING_X_DEFAULT;
	if (
		use_config &&
		(length = get_config_string(PING_SECTION_NAME, PING_X_KEY, PING_X_BUFFER))
	) {
		std::from_chars(PING_X_BUFFER, &PING_X_BUFFER[length], ret, 10);
	}
	return ret;
}

static char PING_Y_BUFFER[INTEGER_BUFFER_SIZE<int32_t>]{ '\0' };
int32_t get_ping_y() {
	size_t length;
	int32_t ret = PING_Y_DEFAULT;
	if (
		use_config &&
		(length = get_config_string(PING_SECTION_NAME, PING_Y_KEY, PING_Y_BUFFER))
	) {
		std::from_chars(PING_Y_BUFFER, &PING_Y_BUFFER[length], ret, 10);
	}
	return ret;
}

static char PING_SCALE_X_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_ping_scale_x() {
	size_t length;
	float ret = MACRO_CAT(PING_SCALE_X_DEFAULT, f);
	if (
		use_config &&
		(length = get_config_string<AllowTruncation>(PING_SECTION_NAME, PING_SCALE_X_KEY, PING_SCALE_X_BUFFER))
	) {
		std::from_chars(PING_SCALE_X_BUFFER, &PING_SCALE_X_BUFFER[length], ret);
	}
	return ret;
}

static char PING_SCALE_Y_BUFFER[FLOAT_BUFFER_SIZE<float>]{ '\0' };
float get_ping_scale_y() {
	size_t length;
	float ret = MACRO_CAT(PING_SCALE_Y_DEFAULT, f);
	if (
		use_config &&
		(length = get_config_string<AllowTruncation>(PING_SECTION_NAME, PING_SCALE_Y_KEY, PING_SCALE_Y_BUFFER))
	) {
		std::from_chars(PING_SCALE_Y_BUFFER, &PING_SCALE_Y_BUFFER[length], ret);
	}
	return ret;
}

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

void set_ipv6_state(bool state) {
	set_config_string(NETWORK_SECTION_NAME, NETWORK_IPV6_KEY, bool_str(state));
}

void init_config_file() {
	size_t directory_length = GetCurrentDirectoryA(countof(CONFIG_FILE_PATH), CONFIG_FILE_PATH);
	if (
		directory_length != 0 &&
		directory_length <= countof(CONFIG_FILE_PATH) - countof(CONFIG_FILE_NAME)
	) {
		memcpy(&CONFIG_FILE_PATH[directory_length], CONFIG_FILE_NAME, sizeof(CONFIG_FILE_NAME));

		/*
		if (
			file_exists(CONFIG_FILE_PATH) || create_default_file(CONFIG_FILE_PATH)
		) {
			use_config = true;
		}
		*/
		if (
			file_exists(CONFIG_FILE_PATH) || create_dummy_file(CONFIG_FILE_PATH)
		) {
			use_config = true;

			fill_default_config_string(LOBBY_SECTION_NAME, LOBBY_HOST_KEY, LOBBY_HOST_DEFAULT);
			fill_default_config_string(LOBBY_SECTION_NAME, LOBBY_PORT_KEY, LOBBY_PORT_DEFAULT);
			fill_default_config_string(LOBBY_SECTION_NAME, LOBBY_PASS_KEY, LOBBY_PASS_DEFAULT);
			fill_default_config_string(PING_SECTION_NAME, PING_X_KEY, PING_X_DEFAULT_STR);
			fill_default_config_string(PING_SECTION_NAME, PING_Y_KEY, PING_Y_DEFAULT_STR);
			fill_default_config_string(PING_SECTION_NAME, PING_SCALE_X_KEY, PING_SCALE_X_DEFAULT_STR);
			fill_default_config_string(PING_SECTION_NAME, PING_SCALE_Y_KEY, PING_SCALE_Y_DEFAULT_STR);
			fill_default_config_string(NETWORK_SECTION_NAME, NETWORK_IPV6_KEY, NETWORK_IPV6_DEFAULT);
		}
	}
}