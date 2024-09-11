#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <squirrel.h>

#include "util.h"
#include "AllocMan.h"
#include "log.h"

extern "C" {
    dll_export int stdcall init_instance_v2(void*) {
        return 1;
    }

    dll_export int stdcall release_instance() {
        return 1;
    }

    dll_export int stdcall update_frame() {
        return 1;
    }

    dll_export int stdcall render_preproc() {
        return 0;
    }

    dll_export int stdcall render(int, int) {
        return 0;
    }
}