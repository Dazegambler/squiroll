#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <squirrel.h>

#include "util.h"
#include "log.h"

extern "C" {
    dll_export int stdcall init_instance_v2(void*) {
        log_printf("Hello from init!");
        return 1;
    }

    dll_export int stdcall release_instance() {
        log_printf("Hello from release!");
        return 1;
    }

    dll_export int stdcall update_frame() {
        log_printf("Hello from update!");
        return 1;
    }

    dll_export int stdcall render_preproc() {
        log_printf("Hello from preproc");
        return 0;
    }

    dll_export int stdcall render(int, int) {
        log_printf("Hello from render");
        return 0;
    }
}