#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdint.h>
#include <stdlib.h>
#include <windows.h>

#include <string>
#include <string_view>
#include <unordered_map>

#include "util.h"
#include "PatchUtils.h"
#include "file_replacement.h"

//patchhook_register_t* patchhook_register = NULL;

using namespace std::literals::string_view_literals;

#if FILE_REPLACEMENT_TYPE != FILE_REPLACEMENT_NONE

// size: 0x10014
struct FileReader {
	void* vtable; // 0x0
	HANDLE file; // 0x4
	uint8_t buffer[0x10000]; // 0x8
	size_t buffer_filled; // 0x10008
	size_t buffer_offset; // 0x1000C
	size_t last_read_size; // 0x10010
	// 0x10014
};

// size: 0x10044
struct PackageReader : FileReader {
	uint32_t __int_10014; // 0x10014
	size_t file_size; // 0x10018
	uint32_t file_name_hash; // 0x1001C
	uint32_t __file_hash; // 0x10020
	size_t offset; // 0x10024
	uint32_t key[5]; // 0x10028
	uint32_t aux; // 0x1003C
	uint32_t aux_mask; // 0x10040
	// 0x10044
};

static constexpr uint8_t network_nut[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_BASIC_THCRAP
#include "replacement_files/network_encrypted.nut.h"
#elif FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/network.nut.h"
#endif
};

static constexpr uint8_t version_nut[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/version.nut.h"
#endif
};

/*
static constexpr uint8_t menu_nut[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/menu.nut.h"
#endif
};
*/

static constexpr uint8_t title_nut[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/title.nut.h"
#endif
};

static constexpr uint8_t config_nut[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/config.nut.h"
#endif
};

static constexpr uint8_t battle_nut[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/battle.nut.h"
#endif
};

static constexpr uint8_t vs_nut[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/vs.nut.h"
#endif
};

static constexpr uint8_t item_csv[] = {
#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT
#include "replacement_files/item.csv.h"
#endif
};

static const std::unordered_map<std::string_view, const EmbedData> replacements = {
	{"data/system/network/network.nut"sv, network_nut},
	{"data/script/version.nut"sv, version_nut},
	{"data/script/battle/battle.nut"sv, battle_nut},
	{"data/system/title/title.nut"sv, title_nut},
	{"data/script/scene/vs.nut"sv, vs_nut},
	//{"data/system/config/config.nut"sv, config_nut},
	//{"data/system/config/item.csv"sv, item_csv},
	//{"data/script/menu.nut"sv, menu_nut},
};

#if FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_BASIC_THCRAP

static std::unordered_map<HANDLE, EmbedData> current_replacements;

extern "C" {
	void fastcall file_replacement_impl(PackageReader* file_reader, const char* file_name) {
		file_reader->aux_mask = (uint32_t)-1;
		auto replacement = replacements.find(file_name);
		if (replacement != replacements.end()) {
			file_reader->file_size = replacement->second.length;
			current_replacements[file_reader->file] = replacement->second;
		}
	}
}

BOOL WINAPI file_replacement_read(HANDLE handle, LPVOID buffer, DWORD buffer_size, LPDWORD bytes_read, LPOVERLAPPED overlapped) {
	auto replacement = current_replacements.find(handle);
	if (replacement != current_replacements.end()) {
		return (BOOL)memcpy(buffer, replacement->second.data, *bytes_read = replacement->second.length);
	} else {
		return ReadFile(handle, buffer, buffer_size, bytes_read, overlapped);
	}
}

BOOL WINAPI close_handle_hook(HANDLE handle) {
	current_replacements.erase(handle);
	return CloseHandle(handle);
}

#elif FILE_REPLACEMENT_TYPE == FILE_REPLACEMENT_NO_CRYPT

extern "C" {
	uint64_t fastcall file_replacement_impl(PackageReader* file_reader, const char* file_name) {
		//file_reader->buffer_filled = 0;
		auto replacement = replacements.find(file_name);
		bool replaced;
		if ((replaced = replacement != replacements.end())) {
			file_reader->buffer_offset = 0;
			file_reader->__int_10014 = 0;
			file_reader->__file_hash = 0;
			file_reader->offset = 0;
			memset(file_reader->key, 0, sizeof(file_reader->key));
			file_reader->aux = 0;
			file_reader->aux_mask = 0;
			memcpy(file_reader->buffer, replacement->second.data, file_reader->buffer_filled = file_reader->file_size = replacement->second.length);
		} else {
			file_reader->aux = file_reader->key[4] = file_reader->key[0];
			//file_reader->aux_mask = (uint32_t)-1;
		}
		return (uint64_t)file_reader->__int_10014 | ((uint64_t)replaced << bitsof(file_reader->__int_10014));
	}
}

#endif

naked void file_replacement_hook() {
#if !USE_MSVC_ASM
	__asm__(
		"movl %ESI, %ECX \n"
		"movl %EDI, %EDX \n"
		"jmp @file_replacement_impl@8 \n"
	);
#else
	__asm {
		MOV ECX, ESI
		MOV EDX, EDI
		JMP file_replacement_impl
	}
#endif
}

#endif



static constexpr uint8_t misc_nut[] = {
#include "new_files/misc_config.nut.h"
};

static constexpr uint8_t debug_nut[] = {
#include "new_files/debug.nut.h"
};

static const std::unordered_map<std::string_view, const EmbedData> new_files = {
	{"misc_config.nut"sv, misc_nut},
	{"debug.nut"sv, debug_nut},
};

EmbedData get_new_file_data(const char* name) {
	auto new_file = new_files.find(name);
	if (new_file != new_files.end()) {
		return new_file->second;
	}
	return {};
}