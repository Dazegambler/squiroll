#include <Windows.h>
#include <dxgi.h>
#include "log.h"
#include "patch_utils.h"
#include "util.h"

// Superluminal markers for debugging frametime spikes
#define PROFILING 0

typedef void stdcall window_update_frame_t();
typedef bool stdcall window_render_t();

#define game_loop_call_addr (0x1A22C_R)
#define wndproc_param_addr (0x23944_R)
#define set_window_mode_param_addr (0xEAB6_R)
#define no_gdi_compat_patch_addr (0xD687_R)

#define main_hwnd (*(HWND*)0x4DAD0C_R)
#define exit_requested (*(bool*)0x4DAD02_R)
#define cur_fps ((uint32_t*)0x4DACF8_R)
#define window_vsync ((bool*)0x49AF01_R)
#define window_present_interval ((bool*)0x4DAD2D_R)
#define dxgi_swapchain_desc ((DXGI_SWAP_CHAIN_DESC*)0x4DAE4C_R)
#define dxgi_swapchain ((IDXGISwapChain**)0x4DAEA0_R)
#define d3d11_dev ((ID3D11Device**)0x4DAE9C_R)

#define window_update_frame ((window_update_frame_t*)0xE1A0_R)
#define window_render ((window_render_t*)0xE330_R)
#define WndProc_orig ((WNDPROC)0x23A70_R)

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

static void cdecl set_window_mode_custom(int, int, bool fullscreen, bool vsync) {
    if (dxgi_swapchain_desc->Windowed == fullscreen) {
        dxgi_swapchain_desc->Windowed = !fullscreen;
        HRESULT res = (*dxgi_swapchain)->SetFullscreenState(fullscreen, nullptr);
        if (FAILED(res))
            log_printf("SetFullscreenState failed: 0x%X\n", res);

        SetForegroundWindow(main_hwnd);
    }
    *window_vsync = vsync;
    *window_present_interval = vsync;
}

static bool fullscreen_queued = false;
void stdcall better_game_loop() {
    // Disable DXGI's Alt+Enter handler because it's unreliable sometimes (handled in custom WndProc instead)
    size_t enter_held_frames = 0;
    IDXGIFactory* dxgi_factory = nullptr;
    (*dxgi_swapchain)->GetParent(__uuidof(IDXGIFactory), (void**)&dxgi_factory);
    dxgi_factory->MakeWindowAssociation(main_hwnd, DXGI_MWA_NO_ALT_ENTER);

    // Make the scheduler friendlier
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
    timeBeginPeriod(1);

    // The vanilla game loop does this for some reason, so this needs to do the same to not desync replays
    unsigned int fpu_state = 0;
    _clearfp();
    _controlfp_s(&fpu_state, _RC_NEAR, _MCW_RC);
    _controlfp_s(&fpu_state, _PC_64, _MCW_PC);

#if PROFILING
    PerformanceAPI_Functions perf_api;
    HMODULE perf_dll = LoadLibraryW(L"C:\\Program Files\\Superluminal\\Performance\\API\\dll\\x86\\PerformanceAPI.dll");
    ((PerformanceAPI_GetAPI_Func)GetProcAddress(perf_dll, "PerformanceAPI_GetAPI"))(0x30000, &perf_api);
#endif

    // TODO: Investigate how precise this is without CREATE_WAITABLE_TIMER_HIGH_RESOLUTION
    WaitableTimer timer;
    timer.initialize();
    uint64_t qpc_next_fps_update = query_performance_counter() + qpc_raw_frequency;
    uint32_t frames_this_sec = 0;
    while (!exit_requested) {
#if PROFILING
        perf_api.BeginEvent("Frame", nullptr, 0xFFFFFFFF);
#endif

        uint64_t qpc_target = query_performance_counter() + qpc_frame_frequency;
        timer.set(166667 - 30000); // 3ms of leniency

        window_update_frame();

        // NOTE: Not handling "SkipRender" because that doesn't seem to be used in AoCF
        if (window_render())
            frames_this_sec++;

#if PROFILING
        perf_api.EndEvent();
#endif

        if (query_performance_counter() < qpc_target) {
            timer.wait();
            if (query_performance_counter() > qpc_target) {
                uint64_t overshoot = (query_performance_counter() - qpc_target) / qpc_timer_frequency;
#if SYNC_TYPE == SYNC_USE_MILLISECONDS
                log_printf("Scheduler overshot frame deadline by %llu ms\n", overshoot);
#elif SYNC_TYPE == SYNC_USE_MICROSECONDS
                log_printf("Scheduler overshot frame deadline by %llu us\n", overshoot);
#endif
            }
        }
        while (query_performance_counter() < qpc_target)
            _mm_pause();

        if (query_performance_counter() >= qpc_next_fps_update) {
            qpc_next_fps_update = query_performance_counter() + qpc_raw_frequency;
            *cur_fps = frames_this_sec;
            frames_this_sec = 0;
        }

        if (fullscreen_queued) {
            set_window_mode_custom(0, 0, dxgi_swapchain_desc->Windowed, *window_vsync);
            fullscreen_queued = false;
        }
    }

    _controlfp_s(&fpu_state, _CW_DEFAULT, 0xFFFFFFFF);
    timeEndPeriod(1);
    SendMessageA(main_hwnd, WM_DESTROY, 0, 0);
}

LRESULT __stdcall WndProc_custom(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam) {
    if (Msg == WM_SYSKEYDOWN && (HIWORD(lParam) & KF_ALTDOWN) && wParam == VK_RETURN) {
        fullscreen_queued = true;
        return 0;
    }
    return WndProc_orig(hWnd, Msg, wParam, lParam);
}

void init_better_game_loop() {
    hotpatch_call(game_loop_call_addr, better_game_loop);
    mem_write(wndproc_param_addr, (void*)WndProc_custom);
    mem_write(set_window_mode_param_addr, (void*)set_window_mode_custom);
    mem_write(no_gdi_compat_patch_addr, PATCH_BYTES<0x00>); // Not used at all and it's probably better to turn it off
}
