
#undef _HAS_CXX20
#define _HAS_CXX20 0

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

struct DecryptData {
	uint32_t Key[5];
	uint32_t Aux;
	uint32_t unknown3;
};

struct FileReader {
	void* vtable;
	HANDLE file_handle;
	uint8_t buffer[0x10000];
	uint32_t LastReadFileSize;
	uint32_t Offset;
	uint32_t LastReadSize;
	uint32_t unknown1;
	uint32_t FileSize;
	uint32_t FileNameHash;
	uint32_t unknown2;
	uint32_t XorOffset;
	DecryptData decrypt;
};

struct ReplacementData {
	const uint8_t* data;
	size_t length;
};

static constexpr uint8_t network_nut[] = {
#include "replacement_files/network.nut.h"
};

static std::unordered_map<std::string_view, ReplacementData> replacements = {
	{ "data/system/network/network.nut"sv, { network_nut, sizeof(network_nut) } }
};

static std::unordered_map<HANDLE, ReplacementData> current_replacements;

extern "C" {
	void fastcall file_replacement_impl(FileReader* file_reader, const char* file_name) {
		file_reader->decrypt.unknown3 = (uint32_t)-1;
		auto replacement = replacements.find(file_name);
		if (replacement != replacements.end()) {
			file_reader->FileSize = replacement->second.length;
			current_replacements[file_reader->file_handle] = replacement->second;
		}
	}
}

naked void file_replacement_hook() {
#if !USE_MSVC_ASM
	__asm__(
		"movl %ESI, %ECX \n"
		"movl 8(%EBP), %EDX \n"
		"jmp @file_replacement_impl@8 \n"
	);
#else
	__asm {
		MOV ECX, ESI
		MOV EDX, DWORD PTR [EBP+8]
		JMP file_replacement_impl
	}
#endif
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