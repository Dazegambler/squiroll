#include <stdint.h>
#include <string_view>
#include <unordered_set>
#include <unordered_map>

#include "rollback.h"
#include "patch_utils.h"
#include "squirrel.h"
#include "util.h"
#include "kite_api.h"
#include "log.h"

using namespace std::string_view_literals;

extern HSQUIRRELVM v;
extern const KiteSquirrelAPI* KITE;

struct ACRTThreadData {
    char dont_care0[0x24]; // 0x0
    uint32_t rand_state; // 0x24
    char dont_care28[0x364 - 0x28]; // 0x28
    // 0x364
};

typedef ACRTThreadData* stdcall acrt_getptd_t();
#define acrt_getptd ((acrt_getptd_t*)0x319663_R)

#define SQVM_Get ((bool (*thiscall)(void*, SQObject*, SQObject*, SQObject*, bool, int32_t))(0x1918E0_R))
#define SQVM_Set ((bool (*thiscall)(void*, SQObject*, SQObject*, SQObject*, int32_t))(0x192F80_R))

#define MEMBER_TYPE_METHOD 0x01000000
#define MEMBER_TYPE_FIELD 0x02000000

#define type(obj) ((obj)._type)
#define _integer(obj) ((obj)._unVal.nInteger)
#define _weakref(obj) ((obj)._unVal.pWeakRef)
#define _realval(o) (type((o)) != OT_WEAKREF ? (SQObject)o : _weakref(o)->_obj)
#define _ismethod(o) (_integer(o) & MEMBER_TYPE_METHOD)
#define _isfield(o) (_integer(o) & MEMBER_TYPE_FIELD)
#define _make_method_idx(i) ((SQInteger)(MEMBER_TYPE_METHOD | i))
#define _make_field_idx(i) ((SQInteger)(MEMBER_TYPE_FIELD | i))
#define _member_type(o) (_integer(o) & 0xFF000000)
#define _member_idx(o) (_integer(o) & 0x00FFFFFF)

struct SQObjectPtrVec {
    SQObject* _vals; // 0x0
    uint32_t _size; // 0x4
    uint32_t allocated; // 0x8
    // 0xC
};

struct SQRefCounted {
    char dont_care0[0xC]; // 0x0
    // 0xC
};

struct SQCollectable : SQRefCounted {
    char dont_careC[0xC]; // 0xC
    // 0x18
};

struct SQDelegable : SQCollectable {
    char dont_care18[4]; // 0x18
    // 0x1C
};

struct SQFunctionProto : SQCollectable {
    SQObject _sourcename; // 0x18
    SQObject _name; // 0x20
    // don't feel like filling in the rest rn
};

struct SQString : SQRefCounted {
    void* _sharedstate; // 0xC
    SQString* _next; // 0x10
    int32_t _len; // 0x14
    uint32_t _hash; // 0x18
    char _val[1]; // 0x1C
    // 0x1C+
};

struct SQWeakRef : SQRefCounted {
    SQObject _obj; // 0xC
    // 0x14
};

struct SQTable : SQDelegable {
    struct _HashNode {
        _HashNode() { next = nullptr; }
        SQObject val;
        SQObject key;
        _HashNode *next;
    };

    _HashNode* _firstfree; // 0x1C
    _HashNode* _nodes; // 0x20
    int32_t _numofnodes; // 0x24
    int32_t _usednodes; // 0x28
    // 0x2C
};

struct SQArray : SQCollectable {
    SQObjectPtrVec _values; // 0x18
    // 0x24
};

struct SQClosure : SQCollectable {
    void* _env; // 0x18
    void* _base; // 0x1C
    SQFunctionProto* _function; // 0x20
    SQObject* _outervalues; // 0x24
    SQObject* _defaultparams; // 0x28
    // 0x2C
};

struct SQClass : SQCollectable {
    SQTable* _members; // 0x18
    // don't feel like filling in the rest rn
};

struct SQInstance : SQDelegable {
    SQClass* _class; // 0x1C
    void* _userpointer; // 0x20
    void* _hook; // 0x24
    int32_t _memsize; // 0x28
    SQObject _values[1]; // 0x2C
    // 0x2C+
};

static const char* sq_type_to_str(SQObjectType type) {
#define TYPE(x) case x: return #x;
    switch (type) {
        TYPE(OT_NULL)
        TYPE(OT_INTEGER)
        TYPE(OT_FLOAT)
        TYPE(OT_BOOL)
        TYPE(OT_STRING)
        TYPE(OT_TABLE)
        TYPE(OT_ARRAY)
        TYPE(OT_USERDATA)
        TYPE(OT_CLOSURE)
        TYPE(OT_NATIVECLOSURE)
        TYPE(OT_GENERATOR)
        TYPE(OT_USERPOINTER)
        TYPE(OT_THREAD)
        TYPE(OT_FUNCPROTO)
        TYPE(OT_CLASS)
        TYPE(OT_INSTANCE)
        TYPE(OT_WEAKREF)
        TYPE(OT_OUTER)
        default:
            __debugbreak();
            return "WTF";
    }
#undef TYPE
}

#define STATE_END 0xDEADBEEFu

static const std::unordered_set<std::string_view> ignored_keys = {
    "__getTable"sv,
    "__setTable"sv,
    "temp_actor_data"sv,
};

static bool should_dump_sq_obj(SQObject* key, SQObject* obj) {
    if (key && key->_type == OT_STRING && ignored_keys.contains({key->_unVal.pString->_val, key->_unVal.pString->_len}))
        return false;

    switch (obj->_type) {
        case OT_CLOSURE: {
            if (!key)
                return true;

            SQFunctionProto* func = obj->_unVal.pClosure->_function;
            return memcmp(&func->_name, key, sizeof(SQObject)) != 0; // This works because strings are pooled
        }
        default:
            return true;
    }
}

// debug...
/*
static void print_sq_obj(SQObject* obj, int depth, std::unordered_set<uint32_t>& already_dumped) {
    if ((obj->_type & SQOBJECT_REF_COUNTED) == 0)
        return;

    if (already_dumped.contains((uint32_t)obj->_unVal.raw))
        return;
    already_dumped.insert((uint32_t)obj->_unVal.raw);

    switch (obj->_type) {
        case OT_TABLE: {
            SQTable* table = obj->_unVal.pTable;
            for (int32_t i = 0; i < table->_numofnodes; i++) {
                // Squirrel's hash table uses linked lists for collisions, but all nodes are stored in the array
                SQTable::_HashNode* cur = &table->_nodes[i];
                if (cur->key._type == OT_NULL) {
                    continue;
                } else if (cur->key._type != OT_STRING && cur->key._type != OT_INTEGER) {
                    log_printf("WTF %s\n", sq_type_to_str(cur->key._type));
                    __debugbreak();
                }

                if (should_dump_sq_obj(&cur->key, &cur->val)) {
                    if (cur->key._type == OT_STRING) {
                        SQString* key = cur->key._unVal.pString;
                        log_printf("%*s%.*s %s %p\n", depth * 4, "", key->_len, &key->_val, sq_type_to_str(cur->val._type), cur->val._unVal.raw);
                    } else {
                        log_printf("%*s%d %s %p\n", depth * 4, "", cur->key._unVal.nInteger, sq_type_to_str(cur->val._type), cur->val._unVal.raw);
                    }
                    print_sq_obj(&cur->val, depth + 1, already_dumped);
                }
            }
            break;
        }
        case OT_ARRAY: {
            SQArray* array = obj->_unVal.pArray;
            for (uint32_t i = 0; i < array->_values._size; i++) {
                SQObject* cur = &array->_values._vals[i];
                if (should_dump_sq_obj(nullptr, cur)) {
                    log_printf("%*s%u %s %p\n", depth * 4, "", i, sq_type_to_str(cur->_type), cur->_unVal.raw);
                    print_sq_obj(&array->_values._vals[i], depth + 1, already_dumped);
                }
            }
            break;
        }
        case OT_STRING: {
            SQString* str = obj->_unVal.pString;
            log_printf("%*s\"%*s\"\n", depth * 4, "", str->_len, &str->_val);
            break;
        }
        case OT_INSTANCE: {
            SQInstance* inst = obj->_unVal.pInstance;
            SQTable* members = inst->_class->_members;
            for (int32_t i = 0; i < members->_numofnodes; i++) {
                if (members->_nodes[i].key._type == OT_NULL)
                    continue;

                SQObject* val = &inst->_values[_member_idx(members->_nodes[i].val)];
                if (_isfield(members->_nodes[i].val) && should_dump_sq_obj(&members->_nodes[i].key, val)) {
                    SQString* key = members->_nodes[i].key._unVal.pString;
                    log_printf("%*s%.*s %s %p\n", depth * 4, "", key->_len, &key->_val, sq_type_to_str(val->_type), val->_unVal.raw);
                    print_sq_obj(val, depth + 1, already_dumped);
                }
            }
            break;
        }
        case OT_WEAKREF: {
            SQWeakRef* ref = obj->_unVal.pWeakRef;
            if (should_dump_sq_obj(nullptr, &ref->_obj)) {
                log_printf("%*s%s %p\n", depth * 4 + 4, "", sq_type_to_str(ref->_obj._type), ref->_obj._unVal.raw);
                print_sq_obj(&ref->_obj, depth + 2, already_dumped);
            }
            break;
        }
        case OT_CLASS:
        case OT_CLOSURE:
            // We don't care about the contents of these
            break;
        default:
            log_printf("%*sunhandled %s\n", depth * 4, "", sq_type_to_str(obj->_type));
    }
}
*/

template <>
struct std::hash<SQObject> {
    size_t operator()(const SQObject& k) const {
        return std::hash<uint32_t>()(k._type) ^ std::hash<uint32_t>()(k._unVal.raw);
    }
};

static size_t rollback_cur_frame = 0;
struct TrackedSqObj {
    SQObject obj;
    size_t frame_created;
    size_t frame_destroyed;

    TrackedSqObj(SQObject* src) {
        obj = *src;
        frame_created = rollback_cur_frame;
        frame_destroyed = ~0;
        sq_addref(v, &obj);
    }

    ~TrackedSqObj() {
        log_printf("Releasing %s %p\n", sq_type_to_str(obj._type), obj._unVal.raw);
        sq_release(v, &obj);
    }
};

static void scan_sq_obj(SQObject* obj, std::unordered_map<SQObject, TrackedSqObj>& scanned) {
    if (obj->_type != OT_TABLE && obj->_type != OT_ARRAY && obj->_type != OT_INSTANCE && obj->_type != OT_WEAKREF)
        return;

    if (scanned.contains(*obj))
        return;
    scanned.emplace(*obj, obj);

    switch (obj->_type) {
        case OT_TABLE: {
            SQTable* table = obj->_unVal.pTable;
            for (int32_t i = 0; i < table->_numofnodes; i++) {
                // Squirrel's hash table uses linked lists for collisions, but all nodes are stored in the array
                SQTable::_HashNode* cur = &table->_nodes[i];
                if (cur->key._type == OT_NULL) {
                    continue;
                } else if (cur->key._type != OT_STRING && cur->key._type != OT_INTEGER) {
                    log_printf("unhandled table key %s %p\n", sq_type_to_str(cur->key._type), cur->key._unVal.raw);
                    __debugbreak();
                }

                if (should_dump_sq_obj(&cur->key, &cur->val)) {
                    scan_sq_obj(&cur->val, scanned);
                }
            }
            break;
        }
        case OT_ARRAY: {
            SQArray* array = obj->_unVal.pArray;
            for (uint32_t i = 0; i < array->_values._size; i++) {
                SQObject* cur = &array->_values._vals[i];
                if (should_dump_sq_obj(nullptr, cur)) {
                    scan_sq_obj(&array->_values._vals[i], scanned);
                }
            }
            break;
        }
        case OT_INSTANCE: {
            SQInstance* inst = obj->_unVal.pInstance;
            SQTable* members = inst->_class->_members;
            for (int32_t i = 0; i < members->_numofnodes; i++) {
                if (members->_nodes[i].key._type == OT_NULL)
                    continue;

                SQObject* val = &inst->_values[_member_idx(members->_nodes[i].val)];
                if (_isfield(members->_nodes[i].val) && should_dump_sq_obj(&members->_nodes[i].key, val)) {
                    SQString* key = members->_nodes[i].key._unVal.pString;
                    scan_sq_obj(val, scanned);
                }
            }
            break;
        }
        case OT_WEAKREF: {
            SQWeakRef* ref = obj->_unVal.pWeakRef;
            if (should_dump_sq_obj(nullptr, &ref->_obj)) {
                scan_sq_obj(&ref->_obj, scanned);
            }
            break;
        }
        default:
            unreachable;
    }
}

struct SqObjDiff {
    SQObject key;
    SQObject val;

    SqObjDiff(SQObject* key, SQObject* val) {
        this->key = *key;
        this->val = *val;
        sq_addref(v, &this->key);
        sq_addref(v, &this->val);
    }

    ~SqObjDiff() {
        sq_release(v, &this->key);
        sq_release(v, &this->val);
    }
};

static std::unordered_map<SQObject, TrackedSqObj> tracked_objs;

static uint32_t frame_start_rand;
static std::unordered_map<SQObject, std::vector<SqObjDiff>> frame_obj_vals;

struct FrameUndo {
    bool free;
    uint32_t rand;
    std::unordered_map<SQObject, std::vector<SqObjDiff>> obj_vals;

    void save() {
        if (!free)
            happened();

        rand = frame_start_rand;
        obj_vals = std::move(frame_obj_vals);
    }

    void reset() {
        free = true;
        obj_vals.clear();
    }

    void happened() {
        reset();
    }

    void didnt_happen() {
        for (auto& [obj, diffs] : obj_vals) {
            for (auto& diff : diffs)
                SQVM_Set((SQVM*)v, (SQObject*)&obj, &diff.key, &diff.val, 0);
        }
        reset();
    }
};

static bool rollback_enabled = false;
static FrameUndo rollback_deltas[ROLLBACK_MAX_FRAMES];

static void dump_test() {
    /*
    sq_pushroottable(v);
    sq_pushstring(v, "battle", -1);
    sq_get(v, -2);

    HSQOBJECT battle_table;
    sq_getstackobj(v, -1, &battle_table);

    static std::unordered_set<uint32_t> already_dumped;
    already_dumped.clear();
    print_sq_obj(&battle_table, 0, already_dumped);

    // TODO: Dump Actor2Ds from the managers too

    sq_pop(v, 2);
    */

    size_t roll_idx = rollback_cur_frame & ROLLBACK_FRAME_MASK;
    FrameUndo& delta = rollback_deltas[roll_idx];
}

void rollback_rewind(size_t frames) {
    if (frames == 0) {
        return;
    } else if (frames > ROLLBACK_MAX_FRAMES || frames >= rollback_cur_frame) {
        log_printf("can't roll back %zu frames\n", frames);
        __debugbreak();
    }

    log_printf("starting rollback of %zu frames\n", frames);
    uint64_t start = current_qpc();

    /*
    for (size_t i = 0; i < frames; i++, rollback_cur_frame--) {
        if (i != 0)
            rollback_states[rollback_cur_frame & ROLLBACK_FRAME_MASK].reset();
    }

    size_t roll_idx = rollback_cur_frame & ROLLBACK_FRAME_MASK;
    GameState& state = rollback_states[roll_idx];

    acrt_ptd->rand_state = state.read<uint32_t>();
    if (state.read<uint32_t>() != STATE_END) {
        log_printf("leftover data???\n");
        __debugbreak();
    }
    */

    for (size_t i = 0; i < frames; i++, rollback_cur_frame--) {
        rollback_deltas[(rollback_cur_frame - 1) & ROLLBACK_FRAME_MASK].didnt_happen();
    }

    log_printf("finished in %llu " SYNC_UNIT_STR "\n", qpc_to_sync_time(current_qpc() - start));
}

static bool dump_toggled = false;
bool thiscall SQVM_set_hook(void* _this, SQObject* self, SQObject* key, SQObject* val, int32_t selfidx) {
    if (dump_toggled) {
        switch (key->_type) {
            case OT_STRING: {
                SQString* str = key->_unVal.pString;
                log_printf("%s %p %.*s %s %p\n", sq_type_to_str(self->_type), self->_unVal.raw, str->_len, &str->_val, sq_type_to_str(val->_type), val->_unVal.raw);
                break;
            }
            case OT_INTEGER: {
                log_printf("%s %p %d %s %p\n", sq_type_to_str(self->_type), self->_unVal.raw, key->_unVal.nInteger, sq_type_to_str(val->_type), val->_unVal.raw);
                break;
            }
            default: {
                log_printf("%s %p %p %p %s %p\n", sq_type_to_str(self->_type), self->_unVal.raw, key->_type, key->_unVal.raw, sq_type_to_str(val->_type), val->_unVal.raw);
                break;
            }
        }
    }

    auto tracked_self = tracked_objs.find(*self);
    if (tracked_self != tracked_objs.end() &&
        (key->_type != OT_STRING || !ignored_keys.contains(std::string_view(key->_unVal.pString->_val, key->_unVal.pString->_len))))
    {
        // Save old value, start tracking new one
        bool already_saved = false;
        auto& diffs = frame_obj_vals.try_emplace(*self, std::vector<SqObjDiff>()).first->second;
        for (const auto& diff : diffs) {
            if (!memcmp(&diff.key, key, sizeof(SQObject))) {
                already_saved = true;
                break;
            }
        }

        SQObject cur_val;
        if (!already_saved && SQVM_Get((SQVM*)v, self, key, &cur_val, false, selfidx)) {
            diffs.emplace_back(key, &cur_val);
        }

        scan_sq_obj(val, tracked_objs);
    }

    return SQVM_Set(_this, self, key, val, selfidx);
}

extern const uintptr_t base_address;
static constexpr uintptr_t SQVM_set_calls[] = {
    0x184A6A, 0x184EC5, 0x18E497, 0x18F0B9, 0x191415
};

static ACRTThreadData* acrt_ptd = nullptr;
void rollback_start() {
    if (rollback_enabled) {
        log_printf("Tried to enable rollback twice?\n");
        __debugbreak();
    }

    log_printf("Enabling rollback\n");
    acrt_ptd = acrt_getptd(); // This is running on the game thread, so this should be fine
    for (size_t i = 0; i < ROLLBACK_MAX_FRAMES; i++)
        rollback_deltas[i].reset();

    /*
    sq_pushroottable(v);
    sq_pushstring(v, "battle", -1);
    sq_get(v, -2);
    HSQOBJECT battle_table;
    sq_getstackobj(v, -1, &battle_table);
    scan_sq_obj(&battle_table, tracked_objs);
    log_printf("Tracking %zu objects\n", tracked_objs.size());
    // TODO: Dump Actor2Ds from the managers too
    sq_pop(v, 2);
    */

    sq_pushroottable(v);
    HSQOBJECT root_table;
    sq_getstackobj(v, -1, &root_table);
    scan_sq_obj(&root_table, tracked_objs);
    log_printf("Tracking %zu objects\n", tracked_objs.size());
    // TODO: Dump Actor2Ds from the managers too
    sq_pop(v, 1);

    for (size_t i = 0; i < countof(SQVM_set_calls); i++)
        hotpatch_call(base_address + SQVM_set_calls[i], SQVM_set_hook);
    rollback_enabled = true;
}

void rollback_stop() {
    if (!rollback_enabled) {
        log_printf("Tried to disable rollback twice?\n");
        __debugbreak();
    }

    log_printf("Disabling rollback\n");
    for (size_t i = 0; i < ROLLBACK_MAX_FRAMES; i++)
        rollback_deltas[i].reset();
    tracked_objs.clear();
    for (size_t i = 0; i < countof(SQVM_set_calls); i++)
        hotpatch_call(base_address + SQVM_set_calls[i], SQVM_Set);
    rollback_enabled = false;
}

void rollback_preframe() {
    if (!rollback_enabled)
        return;

    frame_start_rand = acrt_ptd->rand_state;
}

void rollback_postframe() {
    if (!rollback_enabled)
        return;

    rollback_deltas[rollback_cur_frame & ROLLBACK_FRAME_MASK].save();
    rollback_cur_frame++;
}
