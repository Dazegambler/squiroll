#include <winsock2.h>
#include <windows.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <time.h>
#include <ws2tcpip.h>


//Straight from the decompiler
void __fastcall fcn.004e3340(int32_t *param_1)
{
    code **ppcVar1;
    bool bVar2;
    int32_t arg_4h;
    uint32_t uVar3;
    int32_t iVar4;
    LARGE_INTEGER *arg_8h;
    undefined4 extraout_EDX;
    uint32_t extraout_EDX_00;
    LARGE_INTEGER *pLVar5;
    LARGE_INTEGER *pLVar6;
    int32_t *piVar7;
    undefined8 uVar8;
    undefined8 uVar9;
    int64_t iVar10;
    uint32_t arg_8h_00;
    int32_t var_6ch;
    int32_t var_68h;
    LARGE_INTEGER *pLVar11;
    int32_t var_50h;
    int32_t var_48h;
    int32_t var_40h;
    int32_t var_3ch;
    int32_t var_34h;
    int32_t var_30h;
    int32_t var_2ch;
    int32_t var_20h;
    uint32_t var_1ch;
    int32_t var_18h;
    int32_t var_14h;
    int32_t var_10h;
    int32_t var_ch;
    int32_t var_8h;
    
    if (*param_1 == 0) {
        return;
    }
    iVar4 = param_1[0xf] - param_1[0xe] >> 0x1f;
    if ((param_1[0xf] - param_1[0xe]) / 0x90 + iVar4 != iVar4) {
        pLVar5 = (LARGE_INTEGER *)0x0;
        do {
            var_ch = param_1[0xe] + (int32_t)pLVar5;
            uVar8 = flirt.Query_perf_counter();
            arg_8h = (LARGE_INTEGER *)((uint64_t)uVar8 >> 0x20);
            var_14h = (int32_t)uVar8;
            uVar9 = flirt.Query_perf_counter_1();
            arg_8h_00 = (uint32_t)((uint64_t)uVar9 >> 0x20);
            pLVar11 = arg_8h;
            uVar8 = flirt.alldvrm((uint32_t)uVar9, arg_8h_00, (int32_t)uVar8, (int32_t)arg_8h);
            pLVar5 = (LARGE_INTEGER *)((uint64_t)uVar8 >> 0x20);
            pLVar6 = arg_8h;
            uVar9 = flirt.allmul(arg_4h, arg_8h, 1000000000, (uint32_t *)0x0);
            flirt.alldiv((uint32_t)uVar9, (int32_t)((uint64_t)uVar9 >> 0x20), (uint32_t)arg_8h, (int32_t)pLVar11, arg_4h
                         , (uint32_t)pLVar6);
            iVar10 = flirt.allmul(arg_8h_00, pLVar5, 1000000000, (uint32_t *)0x0);
            iVar10 = iVar10 + CONCAT44(extraout_EDX, pLVar11);
            uVar3 = (uint32_t)iVar10;
            iVar10 = flirt.alldiv(uVar3 - *(uint32_t *)(pLVar6 + 0x11), 
                                  ((int32_t)((uint64_t)iVar10 >> 0x20) - *(int32_t *)((int32_t)pLVar6 + 0x8c)) -
                                  (uint32_t)(uVar3 < *(uint32_t *)(pLVar6 + 0x11)), 1000000, 0, arg_8h_00, 
                                  (uint32_t)pLVar5);
            if ((*(int32_t *)(param_1[0xe] + 4 + (int32_t)pLVar5) != 0) && (8000 < iVar10)) {
                piVar7 = *(int32_t **)(param_1[0xe] + 0x84 + (int32_t)pLVar5);
                pLVar6 = pLVar5;
                if (piVar7 == (int32_t *)0x0) goto code_r0x004e3715;
                (**(code **)(*piVar7 + 8))();
            }
            pLVar5 = pLVar5 + 0x12;
        } while ((int32_t)uVar8 + 1U < (uint32_t)((param_1[0xf] - param_1[0xe]) / 0x90));
    }
    var_20h = 0;
    pLVar6 = (LARGE_INTEGER *)0x0;
    iVar4 = param_1[0xf] - param_1[0xe] >> 0x1f;
    if ((param_1[0xf] - param_1[0xe]) / 0x90 + iVar4 != iVar4) {
        pLVar5 = (LARGE_INTEGER *)0x0;
        do {
            piVar7 = *(int32_t **)(param_1[0xe] + 0x5c + (int32_t)pLVar5);
            if (piVar7 == (int32_t *)0x0) goto code_r0x004e3715;
            uVar3 = (**(code **)(*piVar7 + 8))();
            if (pLVar6 <= (LARGE_INTEGER *)((uVar3 >> 1) + 0xf >> 4)) {
                piVar7 = *(int32_t **)(param_1[0xe] + 0x5c + (int32_t)pLVar5);
                if (piVar7 == (int32_t *)0x0) goto code_r0x004e3715;
                uVar3 = (**(code **)(*piVar7 + 8))();
                pLVar6 = (LARGE_INTEGER *)((uVar3 >> 1) + 0xf >> 4);
            }
            pLVar5 = pLVar5 + 0x12;
            var_20h = var_20h + 1;
        } while ((uint32_t)var_20h < (uint32_t)((param_1[0xf] - param_1[0xe]) / 0x90));
    }
    var_ch = (int32_t)*(uint8_t *)(param_1 + 1);
    piVar7 = *(int32_t **)(*(int32_t *)(param_1[9] + 0x10) + var_ch * 8);
    if ((uint32_t)(*piVar7 - piVar7[1]) <= (int32_t)pLVar6 + 1U) {
        uVar3 = 0;
        bVar2 = true;
        iVar4 = param_1[0xf] - param_1[0xe] >> 0x1f;
        if ((param_1[0xf] - param_1[0xe]) / 0x90 + iVar4 != iVar4) {
            var_ch = **(uint32_t **)(*(int32_t *)(param_1[9] + 0x10) + var_ch * 8);
            piVar7 = (int32_t *)(param_1[0xe] + 4);
            do {
                iVar4 = *piVar7;
                piVar7 = piVar7 + 0x24;
                uVar3 = uVar3 + 1;
                bVar2 = (bool)((uint32_t)var_ch < iVar4 + 5U & bVar2);
            } while (uVar3 < (uint32_t)((param_1[0xf] - param_1[0xe]) / 0x90));
            if (!bVar2) goto code_r0x004e35da;
        }
        if ((int32_t *)param_1[4] == (int32_t *)0x0) {
            uVar3 = 0;
        } else {
            (**(code **)(*(int32_t *)param_1[4] + 0x10))();
            uVar3 = fcn.00569d80();
            uVar3 = uVar3 & 0xffff;
        }
        ppcVar1 = (code **)param_1[9];
        pLVar6 = (LARGE_INTEGER *)(uint32_t)*(uint8_t *)(param_1 + 1);
        pLVar5 = *(LARGE_INTEGER **)(*ppcVar1 + 0x40);
        if (*ppcVar1 != vtable.Manbow::InputRecorder.0) goto code_r0x004e371a;
        if (pLVar6 < (LARGE_INTEGER *)((int32_t)ppcVar1[5] - (int32_t)ppcVar1[4] >> 3)) {
            fcn.00569cc0(uVar3);
        }
    }
code_r0x004e35da:
    while( true ) {
        pLVar5 = (LARGE_INTEGER *)param_1[0x11];
        iVar4 = 0;
        if (*(char *)((int32_t)param_1 + 5) != '\0') {
            do {
                *(undefined4 *)((int32_t)pLVar5 + iVar4 * 4 + 0x10) =
                     **(undefined4 **)(*(int32_t *)(param_1[9] + 0x10) + iVar4 * 8);
                iVar4 = iVar4 + 1;
            } while (iVar4 < (int32_t)(uint32_t)*(uint8_t *)((int32_t)param_1 + 5));
        }
        var_1ch = 0;
        iVar4 = param_1[0xf] - param_1[0xe] >> 0x1f;
        if ((param_1[0xf] - param_1[0xe]) / 0x90 + iVar4 == iVar4) break;
        var_18h = 0;
        while( true ) {
            uVar3 = (uint32_t)*(uint8_t *)(param_1 + 1);
            var_10h = param_1[0xe] + var_18h;
            pLVar6 = (LARGE_INTEGER *)(*(int32_t *)(var_10h + 8) + 5);
            pLVar11 = *(LARGE_INTEGER **)((int32_t)pLVar5 + uVar3 * 4 + 0x10);
            if (pLVar11 < pLVar6) {
                pLVar6 = pLVar11;
            }
            iVar4 = 0;
            if ((LARGE_INTEGER *)0x4 < pLVar6) {
                iVar4 = (int32_t)pLVar6 + -5;
            }
            var_ch = *(int32_t *)(*(code **)param_1[9] + 0x38);
            if (*(code **)param_1[9] == vtable.Manbow::InputRecorder.0) {
                if (uVar3 < (uint32_t)(*(int32_t *)(param_1[9] + 0x14) - *(int32_t *)(param_1[9] + 0x10) >> 3)) {
                    fcn.00569af0((int32_t)pLVar5 + 2, iVar4, (uint32_t)pLVar6);
                }
            } else {
                (*(code *)var_ch)(uVar3, (int32_t)pLVar5 + 2, iVar4, pLVar6);
            }
            *(LARGE_INTEGER **)((int32_t)pLVar5 + (uint32_t)*(uint8_t *)(param_1 + 1) * 4 + 0x10) = pLVar6;
            var_ch = (uint32_t)*(uint8_t *)((int32_t)param_1 + 5) * 4 + 0x10;
            var_14h = param_1[0x11];
            if (*(int32_t **)(var_10h + 0x34) == (int32_t *)0x0) break;
            (**(code **)(**(int32_t **)(var_10h + 0x34) + 8))(&var_14h, &var_ch);
            var_1ch = var_1ch + 1;
            var_18h = var_18h + 0x90;
            if ((uint32_t)((param_1[0xf] - param_1[0xe]) / 0x90) <= var_1ch) {
                return;
            }
        }
code_r0x004e3715:
        flirt.scrt_throw_std_bad_array_new_length__YAXXZ_2();
        uVar3 = extraout_EDX_00;
code_r0x004e371a:
        (*(code *)pLVar5)(pLVar6, uVar3);
    }
    return;
}