#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <string.h>
#include <limits.h>
#include <string>
#include <vector>
#include <cwchar>

#include "util.h"
#include "log.h"
#include "patch_utils.h"

#include <shared.h>

#define load_th155_pak_call_addr (0x1DE1E_R)
#define load_th155b_pak_call_addr (0x1DE79_R)
#define parse_archive_addr (0x25420_R)
#define rsa_decrypt_addr (0x26940_R)

typedef bool thisfastcall parse_archive_t(
   void* self,
   thisfastcall_edx(int dummy_edx, )
   const char* filename,
   void* idk
);

static uint8_t* rsa_cache = nullptr;
static uint8_t* rsa_cache_cur = nullptr;
static uint8_t* rsa_cache_end = nullptr;
static char cache_path[MAX_PATH];
static FILE* cache_write_file = nullptr;

[[noreturn]] static void cache_corrupt() {
   DeleteFileW(L"th155.pak.cache");
   DeleteFileW(L"th155b.pak.cache");
   MessageBoxA(NULL, "The RSA cache seems to be corrupt or outdated.\nPlease restart your game.", "squiroll", MB_ICONERROR);
   ExitProcess(1);
}

static bool thisfastcall parse_archive_hook(void* self, thisfastcall_edx(int dummy_edx,) const char* filename, void* idk) {
   snprintf(cache_path, sizeof(cache_path), "%s.cache", filename);
   FILE* cache_file = fopen(cache_path, "rb");
   if (expect(cache_file != NULL, true)) {
       fseek(cache_file, 0, SEEK_END);
       size_t rsa_cache_len = ftell(cache_file);
       rewind(cache_file);
       rsa_cache_cur = rsa_cache = (uint8_t*)malloc(rsa_cache_len);
       rsa_cache_end = rsa_cache + rsa_cache_len;
       fread(rsa_cache, 1, rsa_cache_len, cache_file);
       fclose(cache_file);
       cache_file = NULL;
   } else {
       cache_write_file = cache_file = fopen(cache_path, "wb");
   }

   bool ret = ((parse_archive_t*)parse_archive_addr)(self, thisfastcall_edx(dummy_edx,) filename, idk);

   if (expect(!cache_file, true)) {
       if (expect(rsa_cache_cur != rsa_cache_end, false)) {
           log_printf("%s didn't use the whole cache! 0x%zX vs 0x%zX\n", filename, (size_t)(rsa_cache_cur - rsa_cache), (size_t)(rsa_cache_end - rsa_cache));
           cache_corrupt();
       }
       free(rsa_cache);
       rsa_cache = nullptr;
       rsa_cache_cur = nullptr;
       rsa_cache_end = nullptr;
   } else {
       fclose(cache_file);
       cache_write_file = nullptr;
   }
   return ret;
}

typedef int thisfastcall rsa_decrypt_t(
   void* self,
   thisfastcall_edx(int dummy_edx, )
   void* src,
   void* dst
);

static int thisfastcall rsa_decrypt_hook(void* self, thisfastcall_edx(int dummy_edx,) void* src, void* dst) {
   FILE* cache_file = cache_write_file;
   if (expect(!cache_file, true)) {
       if (expect(rsa_cache_cur + 0x40 > rsa_cache_end, false)) {
           log_printf("%s is truncated!\n", cache_path);
           cache_corrupt();
       }
       memcpy(dst, rsa_cache_cur, 0x40);
       rsa_cache_cur += 0x40;
   } else {
       memset(dst, 0, 0x40); // rsa_decrypt doesn't always fill the whole buffer because src is padded
       if (((rsa_decrypt_t*)rsa_decrypt_addr)(self, thisfastcall_edx(dummy_edx, ) src, dst) == -1) {
           return -1;
       }
       fwrite(dst, 0x40, 1, cache_file);
   }
   return 0;
}

void patch_archive_parsing() {
   hotpatch_rel32(load_th155_pak_call_addr, parse_archive_hook);
   hotpatch_rel32(load_th155b_pak_call_addr, parse_archive_hook);

   static constexpr uintptr_t rsa_decrypt_calls[] = { 0x25874, 0x258F7, 0x25954, 0x259EC, 0x25DCE, 0x25E49, 0x25E81, 0x25EB0 };

   uintptr_t base = base_address;
   nounroll for (size_t i = 0; i < countof(rsa_decrypt_calls); ++i) {
       hotpatch_rel32(based_pointer(base, rsa_decrypt_calls[i]), rsa_decrypt_hook);
   }
}
