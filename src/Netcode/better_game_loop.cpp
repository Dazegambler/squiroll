#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <windows.h>
#include <dxgi.h>
#include <float.h>

#include "log.h"
#include "patch_utils.h"
#include "util.h"
#include "config.h"

// Superluminal markers for debugging frametime spikes
#define PROFILING 0

typedef void stdcall window_update_frame_t();
typedef bool stdcall window_render_t();
typedef void fastcall run_update_list_t(void*);

#define game_loop_call_addr (0x1A22D_R)
#define wndproc_param_addr (0x23944_R)
#define set_window_mode_param_addr (0xEAB6_R)
#define no_gdi_compat_patch_addr (0xD687_R)
#define no_input_thread_patch_addr (0x3175C_R)

#define main_hwnd (*(HWND*)0x4DAD0C_R)
#define window_vsync ((bool*)0x49AF01_R)
#define window_present_interval ((bool*)0x4DAD2D_R)
#define dxgi_swapchain_desc ((DXGI_SWAP_CHAIN_DESC*)0x4DAE4C_R)
#define dxgi_swapchain ((IDXGISwapChain**)0x4DAEA0_R)
#define input_update_list ((void**)0x49AF8C_R)

#define window_update_frame ((window_update_frame_t*)0xE1A0_R)
#define window_render ((window_render_t*)0xE330_R)
#define WndProc_orig ((WNDPROC)0x23A70_R)
#define run_update_list ((run_update_list_t*)0x2FAD0_R)

#if PROFILING
typedef struct {
	int64_t SuppressTailCall[3];
} PerformanceAPI_SuppressTailCallOptimization;
typedef void (PerformanceAPI_BeginEvent_Func)(const char* inID, const char* inData, uint32_t inColor);
typedef PerformanceAPI_SuppressTailCallOptimization (PerformanceAPI_EndEvent_Func)();
typedef struct {
    uintptr_t pad0[2];
    PerformanceAPI_BeginEvent_Func* BeginEvent;
    uintptr_t padC[3];
    PerformanceAPI_EndEvent_Func* EndEvent;
    uintptr_t pad1C[4];
} PerformanceAPI_Functions;
typedef int (*PerformanceAPI_GetAPI_Func)(int inVersion, PerformanceAPI_Functions* outFunctions);
#endif

static void set_fullscreen(BOOL fullscreen) {
    if (dxgi_swapchain_desc->Windowed == fullscreen) {
        dxgi_swapchain_desc->Windowed = !fullscreen;
        HRESULT res = (*dxgi_swapchain)->SetFullscreenState(fullscreen, nullptr);
        if (FAILED(res)) {
            log_printf("SetFullscreenState failed: 0x%X\n", res);
        }

        SetForegroundWindow(main_hwnd);
    }
}

static void cdecl set_window_mode_custom(int, int, bool fullscreen, bool vsync) {
    set_fullscreen(fullscreen);
    *window_vsync = vsync;
    *window_present_interval = vsync;
}

static bool fullscreen_queued = false;
static bool exit_requested = false;
static uint32_t current_fps = 0;

void stdcall better_game_loop() {
    // Disable DXGI's Alt+Enter handler because it's unreliable sometimes (handled in custom WndProc instead)
    size_t enter_held_frames = 0;
    IDXGIFactory* dxgi_factory = nullptr;
    (*dxgi_swapchain)->GetParent(__uuidof(IDXGIFactory), (void**)&dxgi_factory);
    dxgi_factory->MakeWindowAssociation(main_hwnd, DXGI_MWA_NO_ALT_ENTER);

    // Make the scheduler friendlier
    SetThreadPriority(CurrentThreadPseudoHandle(), THREAD_PRIORITY_HIGHEST);
    timeBeginPeriod(1);

    // The vanilla game loop does this for some reason, so this needs to do the same to not desync replays
    unsigned int fpu_state = 0;
    _clearfp();
    _controlfp_s(&fpu_state, _RC_NEAR | _PC_64, _MCW_RC | _MCW_PC);

#if PROFILING
    PerformanceAPI_Functions perf_api;
    HMODULE perf_dll = LoadLibraryW(L"C:\\Program Files\\Superluminal\\Performance\\API\\dll\\x86\\PerformanceAPI.dll");
    ((PerformanceAPI_GetAPI_Func)GetProcAddress(perf_dll, "PerformanceAPI_GetAPI"))(0x30000, &perf_api);
#endif

    // TODO: Investigate how precise this is without CREATE_WAITABLE_TIMER_HIGH_RESOLUTION
    WaitableTimer timer;
    timer.initialize();
    uint64_t qpc_next_fps_update = current_qpc() + qpc_second_frequency;
    uint32_t frames_this_sec = 0;
    int64_t leniency = get_timer_leniency() * 10000;

    while (expect(!exit_requested, true)) {
#if PROFILING
        perf_api.BeginEvent("Frame", nullptr, 0xFFFFFFFF);
#endif

        uint64_t qpc_target = current_qpc() + qpc_frame_frequency;
        timer.set(166667 - leniency);

        run_update_list(*input_update_list);
        window_update_frame();
        // NOTE: Not handling "SkipRender" because that doesn't seem to be used in AoCF
        frames_this_sec += window_render();

#if PROFILING
        perf_api.EndEvent();
#endif

        uint64_t now = current_qpc();
        if (now < qpc_target) {
            timer.wait();
            now = current_qpc();
            if (now > qpc_target) {
                log_printf("Scheduler overshot frame deadline by %llu " SYNC_UNIT_STR "\n", qpc_to_sync_time(now - qpc_target));
            }
            else {
                while (now < qpc_target) {
                    _mm_pause();
                    now = current_qpc();
                }
            }
        }

        if (expect_chance(now >= qpc_next_fps_update, true, FRAC_SECONDS_PER_FRAME)) {
            qpc_next_fps_update = now + qpc_second_frequency;
            current_fps = frames_this_sec;
            frames_this_sec = 0;
        }

        if (expect(fullscreen_queued, false)) {
            fullscreen_queued = false;
            set_fullscreen(dxgi_swapchain_desc->Windowed);
        }
    }

    _controlfp_s(&fpu_state, _CW_DEFAULT, 0xFFFFFFFF);
    timeEndPeriod(1);
    SendMessageA(main_hwnd, WM_DESTROY, 0, 0);
}

LRESULT stdcall WndProc_custom(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    if (Msg == WM_SYSKEYDOWN && (HIWORD(lParam) & KF_ALTDOWN) && wParam == VK_RETURN) {
        fullscreen_queued = true;
        return 0;
    }
    return WndProc_orig(hWnd, Msg, wParam, lParam);
}

void init_better_game_loop() {
    hotpatch_rel32(game_loop_call_addr, better_game_loop);

    mem_write(0xEA21_R, &current_fps);
    mem_write(0xE0A7_R, &exit_requested);
    mem_write(0xE192_R, &exit_requested);

    mem_write(wndproc_param_addr, &WndProc_custom);
    mem_write(set_window_mode_param_addr, &set_window_mode_custom);
    mem_write(no_gdi_compat_patch_addr, PATCH_BYTES<0x00>); // Not used at all and it's probably better to turn it off
    mem_write(no_input_thread_patch_addr, NOP_BYTES(5));
}
