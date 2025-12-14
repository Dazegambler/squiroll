#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <string.h>
#include <limits.h>
#include <string>
#include <vector>
#include <cwchar>

#include <shared.h>

typedef bool thisfastcall parse_archive_t(
	void* self,
	thisfastcall_edx(int dummy_edx),
	const char* filename,
	void* idk
);

static uint8_t* rsa_cache = nullptr;
static uint8_t* rsa_cache_cur = nullptr;
static uint8_t* rsa_cache_end = nullptr;
static char cache_path[MAX_PATH];
