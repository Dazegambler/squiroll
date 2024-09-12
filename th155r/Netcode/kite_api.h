#pragma once

#ifndef KITE_API_H
#define KITE_API_H 1

#include <stdint.h>
#include <stdlib.h>

#include <squirrel.h>

// size: 0xC
struct KiteSquirrelAPIVftable {
	void *const __validate_api; // 0x0
	void *const __method_4; // 0x4
	void *const __method_8; // 0x8
	// 0xC
};

// size: 0x268
struct KiteSquirrelAPI {
	const KiteSquirrelAPIVftable* vftable; // 0x0
	int __dword_4; // 0x4
	decltype(sq_open)* sq_open; // 0x8
	decltype(sq_newthread)* sq_newthread; // 0xC
	decltype(sq_seterrorhandler)* sq_seterrorhandler; // 0x10
	decltype(sq_close)* sq_close; // 0x14
	decltype(sq_setforeignptr)* sq_setforeignptr; // 0x18
	decltype(sq_getforeignptr)* sq_getforeignptr; // 0x1C
	int __dword_20; // 0x20
	int __dword_24; // 0x24
	int __dword_28; // 0x28
	int __dword_2C; // 0x2C
	int __dword_30; // 0x30
	int __dword_34; // 0x34
	decltype(sq_setprintfunc)* sq_setprintfunc; // 0x38
	decltype(sq_getprintfunc)* sq_getprintfunc; // 0x3C
	decltype(sq_geterrorfunc)* sq_geterrorfunc; // 0x40
	decltype(sq_suspendvm)* sq_suspendvm; // 0x44 GUESS
	decltype(sq_wakeupvm)* sq_wakeupvm; // 0x48
	decltype(sq_getvmstate)* sq_getvmstate; // 0x4C
	decltype(sq_getversion)* sq_getversion; // 0x50
	decltype(sq_compile)* sq_compile; // 0x54
	decltype(sq_compilebuffer)* sq_compilebuffer; // 0x58
	decltype(sq_enabledebuginfo)* sq_enabledebuginfo; // 0x5C
	decltype(sq_notifyallexceptions)* sq_notifyallexceptions; // 0x60
	decltype(sq_setcompilererrorhandler)* sq_setcompilererrorhandler; // 0x64
	decltype(sq_push)* sq_push; // 0x68
	decltype(sq_pop)* sq_pop; // 0x6C
	decltype(sq_poptop)* sq_poptop; // 0x70 GUESS
	decltype(sq_remove)* sq_remove; // 0x74
	decltype(sq_gettop)* sq_gettop; // 0x78
	decltype(sq_settop)* sq_settop; // 0x7C
	decltype(sq_reservestack)* sq_reservestack; // 0x80
	decltype(sq_cmp)* sq_cmp; // 0x84
	decltype(sq_move)* sq_move; // 0x88
	decltype(sq_newuserdata)* sq_newuserdata; // 0x8C
	decltype(sq_newtable)* sq_newtable; // 0x90
	decltype(sq_newtableex)* sq_newtableex; // 0x94
	decltype(sq_newarray)* sq_newarray; // 0x98
	decltype(sq_newclosure)* sq_newclosure; // 0x9C
	decltype(sq_setparamscheck)* sq_setparamscheck; // 0xA0
	decltype(sq_bindenv)* sq_bindenv; // 0xA4
	int __dword_A8; // 0xA8
	int __dword_AC; // 0xAC
	decltype(sq_pushstring)* sq_pushstring; // 0xB0
	decltype(sq_pushfloat)* sq_pushfloat; // 0xB4
	decltype(sq_pushinteger)* sq_pushinteger; // 0xB8
	decltype(sq_pushbool)* sq_pushbool; // 0xBC
	decltype(sq_pushuserpointer)* sq_pushuserpointer; // 0xC0
	decltype(sq_pushnull)* sq_pushnull; // 0xC4
	int __dword_C8; // 0xC8
	decltype(sq_gettype)* sq_gettype; // 0xCC
	decltype(sq_typeof)* sq_typeof; // 0xD0 GUESS
	decltype(sq_getsize)* sq_getsize; // 0xD4
	decltype(sq_gethash)* sq_gethash; // 0xD8
	decltype(sq_getbase)* sq_getbase; // 0xDC
	decltype(sq_instanceof)* sq_instanceof; // 0xE0
	decltype(sq_tostring)* sq_tostring; // 0xE4 GUESS
	decltype(sq_tobool)* sq_tobool; // 0xE8
	decltype(sq_getstring)* sq_getstring; // 0xEC
	decltype(sq_getinteger)* sq_getinteger; // 0xF0
	decltype(sq_getfloat)* sq_getfloat; // 0xF4
	decltype(sq_getbool)* sq_getbool; // 0xF8
	decltype(sq_getthread)* sq_getthread; // 0xFC
	decltype(sq_getuserpointer)* sq_getuserpointer; // 0x100
	decltype(sq_getuserdata)* sq_getuserdata; // 0x104
	decltype(sq_settypetag)* sq_settypetag; // 0x108
	decltype(sq_gettypetag)* sq_gettypetag; // 0x10C
	decltype(sq_setreleasehook)* sq_setreleasehook; // 0x110
	int __dword_114; // 0x114
	decltype(sq_getscratchpad)* sq_getscratchpad; // 0x118
	decltype(sq_getfunctioninfo)* sq_getfunctioninfo; // 0x11C GUESS
	decltype(sq_getclosureinfo)* sq_getclosureinfo; // 0x120 GUESS
	decltype(sq_getclosurename)* sq_getclosurename; // 0x124 GUESS
	decltype(sq_setnativeclosurename)* sq_setnativeclosurename; // 0x128
	decltype(sq_setinstanceup)* sq_setinstanceup; // 0x12C
	decltype(sq_getinstanceup)* sq_getinstanceup; // 0x130
	decltype(sq_setclassudsize)* sq_setclassudsize; // 0x134 GUESS
	decltype(sq_newclass)* sq_newclass; // 0x138
	decltype(sq_createinstance)* sq_createinstance; // 0x13C GUESS
	decltype(sq_setattributes)* sq_setattributes; // 0x140 GUESS
	decltype(sq_getattributes)* sq_getattributes; // 0x144 GUESS
	decltype(sq_getclass)* sq_getclass; // 0x148 GUESS
	decltype(sq_weakref)* sq_weakref; // 0x14C GUESS
	decltype(sq_getdefaultdelegate)* sq_getdefaultdelegate; // 0x150 GUESS
	decltype(sq_getmemberhandle)* sq_getmemberhandle; // 0x154 GUESS
	decltype(sq_getbyhandle)* sq_getbyhandle; // 0x158 GUESS
	decltype(sq_setbyhandle)* sq_setbyhandle; // 0x15C GUESS
	decltype(sq_pushroottable)* sq_pushroottable; // 0x160
	decltype(sq_pushregistrytable)* sq_pushregistrytable; // 0x164
	decltype(sq_pushconsttable)* sq_pushconsttable; // 0x168
	decltype(sq_setroottable)* sq_setroottable; // 0x16C
	decltype(sq_setconsttable)* sq_setconsttable; // 0x170
	decltype(sq_newslot)* sq_newslot; // 0x174
	decltype(sq_deleteslot)* sq_deleteslot; // 0x178 GUESS
	decltype(sq_set)* sq_set; // 0x17C
	decltype(sq_get)* sq_get; // 0x180
	decltype(sq_rawget)* sq_rawget; // 0x184
	decltype(sq_rawset)* sq_rawset; // 0x188 GUESS
	decltype(sq_rawdeleteslot)* sq_rawdeleteslot; // 0x18C GUESS
	decltype(sq_newmember)* sq_newmember; // 0x190 GUESS
	decltype(sq_rawnewmember)* sq_rawnewmember; // 0x194 GUESS
	decltype(sq_arrayappend)* sq_arrayappend; // 0x198 GUESS
	decltype(sq_arraypop)* sq_arraypop; // 0x19C GUESS
	decltype(sq_arrayresize)* sq_arrayresize; // 0x1A0
	decltype(sq_arrayreverse)* sq_arrayreverse; // 0x1A4 GUESS
	decltype(sq_arrayremove)* sq_arrayremove; // 0x1A8 GUESS
	decltype(sq_arrayinsert)* sq_arrayinsert; // 0x1AC
	decltype(sq_setdelegate)* sq_setdelegate; // 0x1B0
	decltype(sq_getdelegate)* sq_getdelegate; // 0x1B4
	decltype(sq_clone)* sq_clone; // 0x1B8
	decltype(sq_setfreevariable)* sq_setfreevariable; // 0x1BC GUESS
	decltype(sq_next)* sq_next; // 0x1C0 GUESS
	decltype(sq_getweakrefval)* sq_getweakrefval; // 0x1C4
	decltype(sq_clear)* sq_clear; // 0x1C8 GUESS
	decltype(sq_call)* sq_call; // 0x1CC
	decltype(sq_resume)* sq_resume; // 0x1D0
	decltype(sq_getlocal)* sq_getlocal; // 0x1D4
	decltype(sq_getcallee)* sq_getcallee; // 0x1D8
	decltype(sq_getfreevariable)* sq_getfreevariable; // 0x1DC
	decltype(sq_throwerror)* sq_throwerror; // 0x1E0
	decltype(sq_throwobject)* sq_throwobject; // 0x1E4 GUESS
	decltype(sq_reseterror)* sq_reseterror; // 0x1E8
	decltype(sq_getlasterror)* sq_getlasterror; // 0x1EC
	decltype(sq_getstackobj)* sq_getstackobj; // 0x1F0 GUESS
	decltype(sq_pushobject)* sq_pushobject; // 0x1F4
	decltype(sq_addref)* sq_addref; // 0x1F8
	decltype(sq_release)* sq_release; // 0x1FC
	decltype(sq_getrefcount)* sq_getrefcount; // 0x200
	decltype(sq_resetobject)* sq_resetobject; // 0x204
	decltype(sq_objtostring)* sq_objtostring; // 0x208
	decltype(sq_objtobool)* sq_objtobool; // 0x20C
	decltype(sq_objtointeger)* sq_objtointeger; // 0x210
	decltype(sq_objtofloat)* sq_objtofloat; // 0x214
	decltype(sq_objtouserpointer)* sq_objtouserpointer; // 0x218
	decltype(sq_getobjtypetag)* sq_getobjtypetag; // 0x21C GUESS
	int __dword_220; // 0x220
	decltype(sq_collectgarbage)* sq_collectgarbage; // 0x224
	decltype(sq_resurrectunreachable)* sq_resurrectunreachable; // 0x228 GUESS
	decltype(sq_writeclosure)* sq_writeclosure; // 0x22C
	decltype(sq_readclosure)* sq_readclosure; // 0x230 GUESS
	decltype(sq_malloc)* sq_malloc; // 0x234
	decltype(sq_realloc)* sq_realloc; // 0x238
	decltype(sq_free)* sq_free; // 0x23C
	decltype(sq_stackinfos)* sq_stackinfos; // 0x240
	decltype(sq_setdebughook)* sq_setdebughook; // 0x244 GUESS
	decltype(sq_setnativedebughook)* sq_setnativedebughook; // 0x248
	int __dword_24C; // 0x24C
	int __dword_250; // 0x250
	int __dword_254; // 0x254
	void* sqstd_register_iolib; // 0x258
	int __dword_25C; // 0x25C
	void* sqstd_seterrorhandlers; // 0x260
	void* sqstd_printcallstack; // 0x264
	// 0x268
};

extern KiteSquirrelAPI* KITE;

#endif