#pragma once

#ifndef KITE_API_H
#define KITE_API_H 1

#include <stdint.h>
#include <stdlib.h>

#include <squirrel.h>

#ifndef _PRINT_INT_PREC
#define _PRINT_INT_PREC
#endif

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

extern const KiteSquirrelAPI* KITE;

// HSQUIRRELVM sq_open(SQInteger initialstacksize);
#define sq_open(...) KITE->sq_open(__VA_ARGS__)
// HSQUIRRELVM sq_newthread(HSQUIRRELVM friendvm, SQInteger initialstacksize);
#define sq_newthread(...) KITE->sq_newthread(__VA_ARGS__)
// void sq_seterrorhandler(HSQUIRRELVM v);
#define sq_seterrorhandler(...) KITE->sq_seterrorhandler(__VA_ARGS__)
// void sq_close(HSQUIRRELVM v);
#define sq_close(...) KITE->sq_close(__VA_ARGS__)
// void sq_setforeignptr(HSQUIRRELVM v,SQUserPointer p);
#define sq_setforeignptr(...) KITE->sq_setforeignptr(__VA_ARGS__)
// SQUserPointer sq_getforeignptr(HSQUIRRELVM v);
#define sq_getforeignptr(...) KITE->sq_getforeignptr(__VA_ARGS__)
// void sq_setprintfunc(HSQUIRRELVM v, SQPRINTFUNCTION printfunc, SQPRINTFUNCTION errfunc);
#define sq_setprintfunc(...) KITE->sq_setprintfunc(__VA_ARGS__)
// SQPRINTFUNCTION sq_getprintfunc(HSQUIRRELVM v);
#define sq_getprintfunc(...) KITE->sq_getprintfunc(__VA_ARGS__)
// SQPRINTFUNCTION sq_geterrorfunc(HSQUIRRELVM v);
#define sq_geterrorfunc(...) KITE->sq_geterrorfunc(__VA_ARGS__)
// SQRESULT sq_suspendvm(HSQUIRRELVM v);
#define sq_suspendvm(...) KITE->sq_suspendvm(__VA_ARGS__)
// SQRESULT sq_wakeupvm(HSQUIRRELVM v, SQBool resumedret, SQBool retval, SQBool raiseerror, SQBool throwerror);
#define sq_wakeupvm(...) KITE->sq_wakeupvm(__VA_ARGS__)
// SQInteger sq_getvmstate(HSQUIRRELVM v);
#define sq_getvmstate(...) KITE->sq_getvmstate(__VA_ARGS__)
// SQInteger sq_getversion();
#define sq_getversion(...) KITE->sq_getversion(__VA_ARGS__)
// SQRESULT sq_compile(HSQUIRRELVM v, SQLEXREADFUNC read, SQUserPointer p, const SQChar* sourcename, SQBool raiseerror);
#define sq_compile(...) KITE->sq_compile(__VA_ARGS__)
// SQRESULT sq_compilebuffer(HSQUIRRELVM v, const SQChar* s, SQInteger size, const SQChar* sourcename, SQBool raiseerror);
#define sq_compilebuffer(...) KITE->sq_compilebuffer(__VA_ARGS__)
// void sq_enabledebuginfo(HSQUIRRELVM v, SQBool enable);
#define sq_enabledebuginfo(...) KITE->sq_enabledebuginfo(__VA_ARGS__)
// void sq_notifyallexceptions(HSQUIRRELVM v, SQBool enable);
#define sq_notifyallexceptions(...) KITE->sq_notifyallexceptions(__VA_ARGS__)
// void sq_setcompilererrorhandler(HSQUIRRELVM v, SQCOMPILERERROR f);
#define sq_setcompilererrorhandler(...) KITE->sq_setcompilererrorhandler(__VA_ARGS__)
// void sq_push(HSQUIRRELVM v, SQInteger idx);
#define sq_push(...) KITE->sq_push(__VA_ARGS__)
#define sq_pop(...) KITE->sq_pop(__VA_ARGS__)
#define sq_poptop(...) KITE->sq_poptop(__VA_ARGS__)
#define sq_remove(...) KITE->sq_remove(__VA_ARGS__)
#define sq_gettop(...) KITE->sq_gettop(__VA_ARGS__)
#define sq_settop(...) KITE->sq_settop(__VA_ARGS__)
#define sq_reservestack(...) KITE->sq_reservestack(__VA_ARGS__)
#define sq_cmp(...) KITE->sq_cmp(__VA_ARGS__)
#define sq_move(...) KITE->sq_move(__VA_ARGS__)
#define sq_newuserdata(...) KITE->sq_newuserdata(__VA_ARGS__)
#define sq_newtable(...) KITE->sq_newtable(__VA_ARGS__)
#define sq_newtableex(...) KITE->sq_newtableex(__VA_ARGS__)
#define sq_newarray(...) KITE->sq_newarray(__VA_ARGS__)
#define sq_newclosure(...) KITE->sq_newclosure(__VA_ARGS__)
#define sq_setparamscheck(...) KITE->sq_setparamscheck(__VA_ARGS__)
#define sq_bindenv(...) KITE->sq_bindenv(__VA_ARGS__)
#define sq_pushstring(...) KITE->sq_pushstring(__VA_ARGS__)
#define sq_pushfloat(...) KITE->sq_pushfloat(__VA_ARGS__)
#define sq_pushinteger(...) KITE->sq_pushinteger(__VA_ARGS__)
#define sq_pushbool(...) KITE->sq_pushbool(__VA_ARGS__)
#define sq_pushuserpointer(...) KITE->sq_pushuserpointer(__VA_ARGS__)
#define sq_pushnull(...) KITE->sq_pushnull(__VA_ARGS__)
#define sq_gettype(...) KITE->sq_gettype(__VA_ARGS__)
#define sq_typeof(...) KITE->sq_typeof(__VA_ARGS__)
#define sq_getsize(...) KITE->sq_getsize(__VA_ARGS__)
#define sq_gethash(...) KITE->sq_gethash(__VA_ARGS__)
#define sq_getbase(...) KITE->sq_getbase(__VA_ARGS__)
#define sq_instanceof(...) KITE->sq_instanceof(__VA_ARGS__)
#define sq_tostring(...) KITE->sq_tostring(__VA_ARGS__)
#define sq_tobool(...) KITE->sq_tobool(__VA_ARGS__)
#define sq_getstring(...) KITE->sq_getstring(__VA_ARGS__)
#define sq_getinteger(...) KITE->sq_getinteger(__VA_ARGS__)
#define sq_getfloat(...) KITE->sq_getfloat(__VA_ARGS__)
#define sq_getbool(...) KITE->sq_getbool(__VA_ARGS__)
#define sq_getthread(...) KITE->sq_getthread(__VA_ARGS__)
#define sq_getuserpointer(...) KITE->sq_getuserpointer(__VA_ARGS__)
// SQRESULT sq_getuserdata(HSQUIRRELVM v, SQInteger idx, SQUserPointer* p, SQUserPointer* typetag);
#define sq_getuserdata(...) KITE->sq_getuserdata(__VA_ARGS__)
#define sq_settypetag(...) KITE->sq_settypetag(__VA_ARGS__)
#define sq_gettypetag(...) KITE->sq_gettypetag(__VA_ARGS__)
#define sq_setreleasehook(...) KITE->sq_setreleasehook(__VA_ARGS__)
#define sq_getscratchpad(...) KITE->sq_getscratchpad(__VA_ARGS__)
#define sq_getfunctioninfo(...) KITE->sq_getfunctioninfo(__VA_ARGS__)
#define sq_getclosureinfo(...) KITE->sq_getclosureinfo(__VA_ARGS__)
#define sq_getclosurename(...) KITE->sq_getclosurename(__VA_ARGS__)
#define sq_setnativeclosurename(...) KITE->sq_setnativeclosurename(__VA_ARGS__)
#define sq_setinstanceup(...) KITE->sq_setinstanceup(__VA_ARGS__)
#define sq_getinstanceup(...) KITE->sq_getinstanceup(__VA_ARGS__)
#define sq_setclassudsize(...) KITE->sq_setclassudsize(__VA_ARGS__)
#define sq_newclass(...) KITE->sq_newclass(__VA_ARGS__)
#define sq_createinstance(...) KITE->sq_createinstance(__VA_ARGS__)
#define sq_setattributes(...) KITE->sq_setattributes(__VA_ARGS__)
#define sq_getattributes(...) KITE->sq_getattributes(__VA_ARGS__)
#define sq_getclass(...) KITE->sq_getclass(__VA_ARGS__)
#define sq_weakref(...) KITE->sq_weakref(__VA_ARGS__)
#define sq_getdefaultdelegate(...) KITE->sq_getdefaultdelegate(__VA_ARGS__)
#define sq_getmemberhandle(...) KITE->sq_getmemberhandle(__VA_ARGS__)
#define sq_getbyhandle(...) KITE->sq_getbyhandle(__VA_ARGS__)
#define sq_setbyhandle(...) KITE->sq_setbyhandle(__VA_ARGS__)
#define sq_pushroottable(...) KITE->sq_pushroottable(__VA_ARGS__)
#define sq_pushregistrytable(...) KITE->sq_pushregistrytable(__VA_ARGS__)
#define sq_pushconsttable(...) KITE->sq_pushconsttable(__VA_ARGS__)
#define sq_setroottable(...) KITE->sq_setroottable(__VA_ARGS__)
#define sq_setconsttable(...) KITE->sq_setconsttable(__VA_ARGS__)
#define sq_newslot(...) KITE->sq_newslot(__VA_ARGS__)
#define sq_deleteslot(...) KITE->sq_deleteslot(__VA_ARGS__)
#define sq_set(...) KITE->sq_set(__VA_ARGS__)
#define sq_get(...) KITE->sq_get(__VA_ARGS__)
#define sq_rawget(...) KITE->sq_rawget(__VA_ARGS__)
#define sq_rawset(...) KITE->sq_rawset(__VA_ARGS__)
#define sq_rawdeleteslot(...) KITE->sq_rawdeleteslot(__VA_ARGS__)
#define sq_newmember(...) KITE->sq_newmember(__VA_ARGS__)
#define sq_rawnewmember(...) KITE->sq_rawnewmember(__VA_ARGS__)
#define sq_arrayappend(...) KITE->sq_arrayappend(__VA_ARGS__)
#define sq_arraypop(...) KITE->sq_arraypop(__VA_ARGS__)
#define sq_arrayresize(...) KITE->sq_arrayresize(__VA_ARGS__)
#define sq_arrayreverse(...) KITE->sq_arrayreverse(__VA_ARGS__)
#define sq_arrayremove(...) KITE->sq_arrayremove(__VA_ARGS__)
#define sq_arrayinsert(...) KITE->sq_arrayinsert(__VA_ARGS__)
#define sq_setdelegate(...) KITE->sq_setdelegate(__VA_ARGS__)
#define sq_getdelegate(...) KITE->sq_getdelegate(__VA_ARGS__)
#define sq_clone(...) KITE->sq_clone(__VA_ARGS__)
#define sq_setfreevariable(...) KITE->sq_setfreevariable(__VA_ARGS__)
#define sq_next(...) KITE->sq_next(__VA_ARGS__)
#define sq_getweakrefval(...) KITE->sq_getweakrefval(__VA_ARGS__)
#define sq_clear(...) KITE->sq_clear(__VA_ARGS__)
#define sq_call(...) KITE->sq_call(__VA_ARGS__)
#define sq_resume(...) KITE->sq_resume(__VA_ARGS__)
#define sq_getlocal(...) KITE->sq_getlocal(__VA_ARGS__)
#define sq_getcallee(...) KITE->sq_getcallee(__VA_ARGS__)
#define sq_getfreevariable(...) KITE->sq_getfreevariable(__VA_ARGS__)
#define sq_throwerror(...) KITE->sq_throwerror(__VA_ARGS__)
#define sq_throwobject(...) KITE->sq_throwobject(__VA_ARGS__)
#define sq_reseterror(...) KITE->sq_reseterror(__VA_ARGS__)
#define sq_getlasterror(...) KITE->sq_getlasterror(__VA_ARGS__)
#define sq_getstackobj(...) KITE->sq_getstackobj(__VA_ARGS__)
#define sq_pushobject(...) KITE->sq_pushobject(__VA_ARGS__)
#define sq_addref(...) KITE->sq_addref(__VA_ARGS__)
#define sq_release(...) KITE->sq_release(__VA_ARGS__)
#define sq_getrefcount(...) KITE->sq_getrefcount(__VA_ARGS__)
#define sq_resetobject(...) KITE->sq_resetobject(__VA_ARGS__)
#define sq_objtostring(...) KITE->sq_objtostring(__VA_ARGS__)
#define sq_objtobool(...) KITE->sq_objtobool(__VA_ARGS__)
#define sq_objtointeger(...) KITE->sq_objtointeger(__VA_ARGS__)
#define sq_objtofloat(...) KITE->sq_objtofloat(__VA_ARGS__)
#define sq_objtouserpointer(...) KITE->sq_objtouserpointer(__VA_ARGS__)
#define sq_getobjtypetag(...) KITE->sq_getobjtypetag(__VA_ARGS__)
#define sq_collectgarbage(...) KITE->sq_collectgarbage(__VA_ARGS__)
#define sq_resurrectunreachable(...) KITE->sq_resurrectunreachable(__VA_ARGS__)
#define sq_writeclosure(...) KITE->sq_writeclosure(__VA_ARGS__)
#define sq_readclosure(...) KITE->sq_readclosure(__VA_ARGS__)
#define sq_malloc(...) KITE->sq_malloc(__VA_ARGS__)
#define sq_realloc(...) KITE->sq_realloc(__VA_ARGS__)
#define sq_free(...) KITE->sq_free(__VA_ARGS__)
#define sq_stackinfos(...) KITE->sq_stackinfos(__VA_ARGS__)
#define sq_setdebughook(...) KITE->sq_setdebughook(__VA_ARGS__)
#define sq_setnativedebughook(...) KITE->sq_setnativedebughook(__VA_ARGS__)

#endif