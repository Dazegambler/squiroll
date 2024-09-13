#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <windows.h>

#include "util.h"


static bool use_config = false;
static char CONFIG_FILE_PATH[MAX_PATH];

static constexpr char CONFIG_FILE_NAME[] = "\\netcode.ini";

#define SECTION_NAME "netcode"
#define LOBBY_HOST_KEY "lobby_server"
#define LOBBY_PORT_KEY "lobby_port"
#define LOBBY_PASS_KEY "lobby_password"

static constexpr char DEFAULT_CONFIG[] =
"[" SECTION_NAME "]\n"
LOBBY_HOST_KEY "=waluigistacostand.ddns.net\n"
LOBBY_PORT_KEY "=1550\n"
LOBBY_PASS_KEY "=kzxmckfqbpqieh8rw<rczuturKfnsjxhauhybttboiuuzmWdmnt5mnlczpythaxf\n"
;

static inline bool file_exists(const char* path) {
	DWORD attr = GetFileAttributesA(path);
	return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

static inline bool create_default_file(const char* path) {
	HANDLE handle = CreateFile(
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

void init_config_file() {
	size_t directory_length = GetCurrentDirectoryA(countof(CONFIG_FILE_PATH), CONFIG_FILE_PATH);
	if (
		directory_length != 0 &&
		directory_length <= countof(CONFIG_FILE_PATH) - countof(CONFIG_FILE_NAME)
	) {
		memcpy(&CONFIG_FILE_PATH[directory_length], CONFIG_FILE_NAME, sizeof(CONFIG_FILE_NAME));

		if (
			file_exists(CONFIG_FILE_PATH) || create_default_file(CONFIG_FILE_PATH)
		) {
			use_config = true;
		}
	}
}


static char LOBBY_HOST_BUFFER[1024]{ '\0' };
const char* get_lobby_host(const char* host) {
	if (use_config) {
		size_t written = GetPrivateProfileStringA(SECTION_NAME, LOBBY_HOST_KEY, NULL, LOBBY_HOST_BUFFER, countof(LOBBY_HOST_BUFFER), CONFIG_FILE_PATH);
		if (written && written != countof(LOBBY_HOST_BUFFER) - 1) {
			host = LOBBY_HOST_BUFFER;
		}
	}
	return host;
}

static char LOBBY_PORT_BUFFER[256]{ '\0' };
const char* get_lobby_port(const char* port) {
	if (use_config) {
		size_t written = GetPrivateProfileStringA(SECTION_NAME, LOBBY_PORT_KEY, NULL, LOBBY_PORT_BUFFER, countof(LOBBY_PORT_BUFFER), CONFIG_FILE_PATH);
		if (written && written != countof(LOBBY_PORT_BUFFER) - 1) {
			port = LOBBY_PORT_BUFFER;
		}
	}
	return port;
}

static char LOBBY_PASS_BUFFER[1024]{ '\0' };
const char* get_lobby_pass(const char* pass) {
	if (use_config) {
		size_t written = GetPrivateProfileStringA(SECTION_NAME, LOBBY_PASS_KEY, NULL, LOBBY_PASS_BUFFER, countof(LOBBY_PASS_BUFFER), CONFIG_FILE_PATH);
		if (written && written != countof(LOBBY_PASS_BUFFER) - 1) {
			pass = LOBBY_PASS_BUFFER;
		}
	}
	return pass;
}