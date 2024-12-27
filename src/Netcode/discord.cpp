#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <atomic>
#include "discord.h"
#include "util.h"
#include "log.h"

#if ENABLE_DISCORD_INTEGRATION

struct sockaddr_un_win {
    uint16_t sun_family = AF_UNIX;
    char sun_path[108];
};

struct UnixSocketHack {
private:

#if !USE_MSVC_ASM
#define SYSCALL_ZERO_ARG(ret, number) __asm__("int $0x80":"=a"(ret):"a"(number))
#define SYSCALL_ONE_ARG(ret, number, arg1) __asm__("int $0x80":"=a"(ret):"a"(number),"b"(arg1))
#define SYSCALL_TWO_ARG(ret, number, arg1, arg2) __asm__("int $0x80":"=a"(ret):"a"(number),"b"(arg1),"c"(arg2))
#define SYSCALL_THREE_ARG(ret, number, arg1, arg2, arg3) __asm__("int $0x80":"=a"(ret):"a"(number),"b"(arg1),"c"(arg2),"d"(arg3))
#else
#define SYSCALL_ZERO_ARG(ret, number) __asm { __asm MOV EAX, number __asm INT 0x80 __asm MOV ret, EAX }
#define SYSCALL_ONE_ARG(ret, number, arg1) __asm { __asm MOV EAX, number __asm MOV EBX, arg1 __asm INT 0x80 __asm MOV ret, EAX }
#define SYSCALL_TWO_ARG(ret, number, arg1, arg2) __asm { __asm MOV EAX, number __asm MOV EBX, arg1 __asm MOV ECX, arg2 __asm INT 0x80 __asm MOV ret, EAX }
#define SYSCALL_THREE_ARG(ret, number, arg1, arg2, arg3) __asm { __asm MOV EAX, number __asm MOV EBX, arg1 __asm MOV ECX, arg2 __asm MOV EDX, arg3 __asm INT 0x80 __asm MOV ret, EAX }
#endif

    static inline int socketcall(int call_number, void* args) {
        int ret;
        SYSCALL_TWO_ARG(ret, 0x66, call_number, args);
        return ret;
    }
public:
    static inline int read(int fd, char* buf, unsigned int count) {
        int ret;
        SYSCALL_THREE_ARG(ret, 0x03, fd, buf, count);
        return ret;
    }
    static inline int write(int fd, const char* buf, unsigned int count) {
        int ret;
        SYSCALL_THREE_ARG(ret, 0x04, fd, buf, count);
        return ret;
    }
    static inline int open(const char* filename, int flags, int mode) {
        int ret;
        SYSCALL_THREE_ARG(ret, 0x05, filename, flags, mode);
        return ret;
    }
    static inline int close(int fd) {
        int ret;
        SYSCALL_ONE_ARG(ret, 0x06, fd);
        return ret;
    }
    static inline unsigned int getpid() {
        unsigned int ret;
        SYSCALL_ZERO_ARG(ret, 0x14);
        return ret;
    }
    static inline int fcntl(int fd, unsigned int cmd, unsigned long arg) {
        int ret;
        SYSCALL_THREE_ARG(ret, 0x37, fd, cmd, arg);
        return ret;
    }

    // Yes, volatile is necessary for these arrays
    // because the compiler hates the inline ASM.
    // 
    // TODO: Add a memory argument in there somewhere
    // to fix this more properly so the compiler can
    // reason about the memory properly.
    static inline int socket(int domain, int type, int protocol) {
        volatile uintptr_t args[3] = { domain, type, protocol };
        return socketcall(1, (void*)args);
    }
    static inline int connect(int sockfd, const sockaddr* addr, unsigned int addrlen) {
        volatile uintptr_t args[3] = { sockfd, (uintptr_t)addr, addrlen };
        return socketcall(3, (void*)args);
    }

    int sock;

    inline operator bool() const {
        return this->sock != -1;
    }

    inline bool operator!() const {
        return this->sock == -1;
    }

    void close() {
        int fd = this->sock;
        if (fd != -1) {
            this->sock = -1;
            close(fd);
        }
    }

    bool write(const void* data, unsigned int length) const {
        if (expect(length != 0, true)) {
            return write(this->sock, (const char*)data, length) == length;
        }
        return true;
    }

    template <typename T> requires(sizeof(T) <= (std::numeric_limits<unsigned int>::max)())
    bool write(const T& data) const {
        return this->write(&data, sizeof(T));
    }

    int read(void* data, unsigned int length) const {
        if (expect(length != 0, true)) {
            switch (int ret = read(this->sock, (char*)data, length)) {
                case -EAGAIN: case -EWOULDBLOCK:
                    return 0;
                default:
                    return ret == length ? 1 : -1;
            }
        }
        return 1;
    }

    template <typename T> requires(sizeof(T) <= (std::numeric_limits<unsigned int>::max)())
    int read(T& data) const {
        return this->read(&data, sizeof(T));
    }
};

union DiscordRPC {
    struct {
        union {
            NamedPipeClient windows_pipe;
            UnixSocketHack unix_socket;
        };
        bool is_wine;
    };

    inline operator bool() const {
        if (expect(!this->is_wine, true)) {
            return this->windows_pipe;
        } else {
            return this->unix_socket;
        }
    }

    inline bool operator!() const {
        if (expect(!this->is_wine, true)) {
            return !this->windows_pipe;
        } else {
            return !this->unix_socket;
        }
    }

    void initialize() {
        if (expect(!(this->is_wine = GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "wine_get_version")), true)) {
            this->windows_pipe.pipe_handle = INVALID_HANDLE_VALUE;
        } else {
            this->unix_socket.sock = -1;
        }
    }

    bool connect() {
        if (expect(!this->is_wine, true)) {
            wchar_t path[] = L"\\\\?\\pipe\\discord-ipc-0";
            constexpr size_t digit = countof(path) - 1;
            do {
                if (this->windows_pipe.connect(path, GENERIC_READ | GENERIC_WRITE, 1000)) {
                    return true;
                }
            } while (++path[digit] <= L'9');
            return false;
        } else {
            int fd = UnixSocketHack::socket(AF_UNIX, SOCK_STREAM, 0);
            if (fd != -1) {
                // Trying to turn off blocking, but it tends to fail
                UnixSocketHack::fcntl(fd, 4, UnixSocketHack::fcntl(fd, 3, 0) | 0x4000);

                sockaddr_un_win addr;

                auto get_env = [&](const char* name) {
                    size_t length = GetEnvironmentVariableA(name, addr.sun_path, countof(addr.sun_path));
                    return length < countof(addr.sun_path) ? length : 0;
                };

                size_t env_length; 
                if (!(
                    (env_length = get_env("XDG_RUNTIME_DIR")) ||
                    (env_length = get_env("TMPDIR")) ||
                    (env_length = get_env("TMP")) ||
                    (env_length = get_env("TEMP"))
                )) {
                    memcpy(addr.sun_path, "/tmp", env_length = countof("/tmp") - 1);
                }

                //log_discordf("Socket temp path \"%.*s\"\n", (int)env_length, addr.sun_path);

                size_t copy_length = std::min(countof("/discord-ipc-0"), countof(addr.sun_path) - env_length) - 1;
                addr.sun_path[env_length + copy_length] = '\0';
                memcpy(&addr.sun_path[env_length], "/discord-ipc-0", copy_length);
                env_length += copy_length - 1;
                do {
                    //log_discordf("Socket path \"%s\"\n", addr.sun_path);
                    if (!UnixSocketHack::connect(fd, (const sockaddr*)&addr, sizeof(sockaddr_un_win))) {
                        this->unix_socket.sock = fd;
                        return true;
                    }
                } while (++addr.sun_path[env_length] <= '9');
                UnixSocketHack::close(fd);
            }
            //else {
                //log_discordf("Linux socket creation failed\n");
            //}
            return false;
        }
    }

    void close() {
        if (expect(!this->is_wine, true)) {
            this->windows_pipe.close();
        } else {
            this->unix_socket.close();
        }
    }

    bool write(const void* data, unsigned int length) const {
        if (expect(!this->is_wine, true)) {
            return this->windows_pipe.write(data, length);
        } else {
            return this->unix_socket.write(data, length);
        }
    }

    template <typename T> requires(sizeof(T) <= (std::numeric_limits<unsigned int>::max)())
    bool write(const T& data) const {
        return this->write(&data, sizeof(T));
    }

    int read(void* data, unsigned int length) const {
        if (expect(!this->is_wine, true)) {
            return this->windows_pipe.read(data, length);
        } else {
            return this->unix_socket.read(data, length);
        }
    }

    template <typename T> requires(sizeof(T) <= (std::numeric_limits<unsigned int>::max)())
    int read(T& data) const {
        return this->read(&data, sizeof(T));
    }

    unsigned int current_pid() const {
        if (expect(!this->is_wine, true)) {
            return GetCurrentProcessId();
        } else {
            return UnixSocketHack::getpid();
        }
    }
};

static DiscordRPC discord_rpc;


bool DISCORD_ENABLED = false;

#define APP_ID "1317594942289350666"

class JsonWriter {
public:
    JsonWriter() {
        cap = 1024;
        data = (char*)malloc(cap);
        pos = 0;
    }

    ~JsonWriter() {
        free(data);
    }

    void start_obj(const char* name) {
        push_raw_char('"');
        push_raw_str(name);
        push_raw_str("\":{");
    }

    void end_obj() {
        if (pos && data[pos - 1] == ',')
            data[pos - 1] = '}';
        else
            push_raw_char('}');
        push_raw_char(',');
    }

    // Assuming the key won't have any unprintable characters
    void add_str(const char* key, const char* value) {
        push_raw_char('"');
        push_raw_str(key);
        push_raw_str("\":\"");
        push_escaped_str(value);
        push_raw_str("\",");
    }

    inline void add_opt_str(const char* key, const char* value) {
        if (value && *value)
            add_str(key, value);
    }

    void add_raw(const char* key, const char* value) {
        push_raw_char('"');
        push_raw_str(key);
        push_raw_str("\":");
        push_raw_str(value);
        push_raw_char(',');
    }

    char* finish() {
        data[pos ? (pos - 1) : 0] = '\0';
        return data;
    }

private:
    char* data;
    size_t pos;
    size_t cap;

    inline void push_raw_char(char c) {
        if (pos == cap) {
            cap *= 2;
            data = (char*)realloc(data, cap);
        }
        data[pos++] = c;
    }

    inline void push_raw_str(const char* str) {
        size_t len = strlen(str);
        if (pos + len > cap) {
            while (pos + len > cap)
                cap *= 2;
            data = (char*)realloc(data, cap);
        }
        memcpy(&data[pos], str, len);
        pos += len;
    }

    // TODO: Support UTF-8
    inline void push_escaped_str(const char* str) {
        constexpr char ESCAPE_CHARS[256] = {
            ['"'] = '"',
            ['\\'] = '\\',
            ['\b'] = 'b',
            ['\f'] = 'f',
            ['\n'] = 'n',
            ['\r'] = 'r',
            ['\t'] = 't',
        };

        char c = *str;
        while (c) {
            char escape = ESCAPE_CHARS[(uint8_t)c];
            if (escape) {
                push_raw_char('\\');
                push_raw_char(escape);
            } else {
                push_raw_char(c);
            }
            c = *++str;
        }
    }
};

enum class Opcode : uint32_t {
    Handshake = 0,
    Frame = 1,
    Close = 2,
    Ping = 3,
    Pong = 4,
};

struct MessageFrame {
    Opcode opcode;
    uint32_t len;
    char msg[0x10000 - sizeof(opcode) - sizeof(len)];
};
constexpr size_t HeaderSize = sizeof(MessageFrame) - sizeof(MessageFrame::msg);

static DWORD rpc_pid = 0;
static size_t rpc_nonce = 0;

static HANDLE rpc_thread = INVALID_HANDLE_VALUE;
static HANDLE rpc_pipe = INVALID_HANDLE_VALUE;
static bool rpc_connected = false;
static std::atomic_bool rpc_thread_running;
static MessageFrame rpc_send_msg;
static MessageFrame rpc_recv_msg;

static size_t user_id_length = 0;
char lobby_user_id[1 + INTEGER_BUFFER_SIZE<uint64_t>] = "d";

static std::atomic_bool rpc_presence_queued;
static DiscordRPCPresence rpc_queued_presence;
static DiscordRPCPresence rpc_cur_presence;
static SRWLOCK rpc_presence_lock = SRWLOCK_INIT;

static bool pipe_open() {
    if (discord_rpc) {
        return true;
    }
    return discord_rpc.connect();
}

static void pipe_close() {
    discord_rpc.close();
    rpc_connected = false;
}

static bool pipe_write(void* data, size_t len) {
    if (!discord_rpc) {
        return false;
    }
    if (discord_rpc.write(data, len)) {
        return true;
    }
    pipe_close();
    return false;
}

static bool pipe_read(void* data, size_t len) {
    if (!discord_rpc) {
        return false;
    }

    switch (discord_rpc.read(data, len)) {
        case -1:
            log_discordf("RPC Read failed: 0x%X\n", GetLastError());
            pipe_close();
        case 0:
            return false;
        default:
            return true;
    }
}

static bool rpc_read_msg(bool update_user_id = false) {
    if (!discord_rpc) {
        return false;
    }

    while (true) {
        if (!pipe_read(&rpc_recv_msg, HeaderSize) || rpc_recv_msg.len >= sizeof(rpc_recv_msg.msg))
            return false;

        if (!pipe_read(&rpc_recv_msg.msg, rpc_recv_msg.len))
            return false;
        rpc_recv_msg.msg[rpc_recv_msg.len] = '\0';

        switch (rpc_recv_msg.opcode) {
            case Opcode::Frame: {
                log_discordf("Discord RPC message: %s\n", rpc_recv_msg.msg);
                if (update_user_id) {
                    // I'd rather not pull in a whole JSON parsing library for this
                    constexpr char target_field[] = "\"id\":\"";
                    char* pos = strstr(rpc_recv_msg.msg, target_field);
                    if (!pos)
                        return true;

                    char* start = pos + sizeof(target_field) - 1;
                    char* end = start;
                    while (*end) {
                        if (*end == '"') {
                            if (start != end) {
                                memcpy(lobby_user_id + 1, start, user_id_length = std::min(sizeof(lobby_user_id) - 2, (size_t)(end - start)));
                                log_discordf("Got Discord user ID: %s\n", lobby_user_id + 1);
                            }
                            break;
                        }
                        end++;
                    }
                }
                return true;
            }
            case Opcode::Ping: {
                rpc_recv_msg.opcode = Opcode::Pong;
                if (!pipe_write(&rpc_recv_msg, HeaderSize + rpc_recv_msg.len))
                    return false;
                break;
            }
            case Opcode::Pong:
                break;
            default: {
                log_discordf("Bad opcode: 0x%X\n", rpc_recv_msg.opcode);
                pipe_close();
                return false;
            }
        }
    }
}

static void rpc_update() {
    if (!rpc_connected) {
        if (!pipe_open())
            return;

        constexpr char handshake_json[] = R"({"v":1,"client_id":")" APP_ID R"("})";
        rpc_send_msg.opcode = Opcode::Handshake;
        memcpy(rpc_send_msg.msg, handshake_json, sizeof(handshake_json) - 1);
        rpc_send_msg.len = sizeof(handshake_json) - 1;
        if (!pipe_write(&rpc_send_msg, HeaderSize + rpc_send_msg.len))
            return;

        while (!rpc_read_msg(true)) {
            if (!rpc_thread_running || !discord_rpc)
                return;
            Sleep(100);
        }

        rpc_connected = true;
        log_discordf("Discord RPC connected\n");
    }

    if (rpc_presence_queued) {
        AcquireSRWLockShared(&rpc_presence_lock);

        JsonWriter activity;
        activity.add_opt_str("state", rpc_cur_presence.state);
        activity.add_opt_str("details", rpc_cur_presence.details);
        activity.add_raw("instance", "true");

        activity.start_obj("assets");
        activity.add_opt_str("large_image", rpc_cur_presence.large_img_key);
        activity.add_opt_str("large_text", rpc_cur_presence.large_img_text);
        activity.add_opt_str("small_image", rpc_cur_presence.small_img_key);
        activity.add_opt_str("small_text", rpc_cur_presence.small_img_text);
        activity.end_obj();

        rpc_presence_queued = false;
        ReleaseSRWLockShared(&rpc_presence_lock);

        snprintf(rpc_send_msg.msg, sizeof(rpc_send_msg.msg), R"({"cmd":"SET_ACTIVITY","nonce":%zu,"args":{"pid":%lu,"activity":{%s}}})", rpc_nonce++, rpc_pid, activity.finish());
        log_discordf("Updating rich presence: %s\n", rpc_send_msg.msg);

        rpc_send_msg.opcode = Opcode::Frame;
        rpc_send_msg.len = strlen(rpc_send_msg.msg);
        pipe_write(&rpc_send_msg, HeaderSize + rpc_send_msg.len);
    }
}

static DWORD stdcall rpc_thread_proc(void*) {
    discord_rpc.initialize();
    rpc_pid = discord_rpc.current_pid();

    rpc_thread_running = true;
    do {
        rpc_update();
        Sleep(500);
    } while (rpc_thread_running);
    return 0;
}

void discord_rpc_start() {
    rpc_thread = CreateThread(NULL, 0, rpc_thread_proc, NULL, 0, NULL);
    rpc_presence_queued = true;
}

#define RPC_FIELD(field) \
    void discord_rpc_set_##field(const char* value) { \
        if (!memccpy(rpc_queued_presence.field, value, '\0', countof(rpc_queued_presence.field))) { \
            rpc_queued_presence.field[countof(rpc_queued_presence.field) - 1] = '\0'; \
        } \
    }
RPC_FIELDS
#undef RPC_FIELD

void discord_rpc_commit() {
    AcquireSRWLockExclusive(&rpc_presence_lock);
    if (memcmp(&rpc_cur_presence, &rpc_queued_presence, sizeof(DiscordRPCPresence))) {
        rpc_cur_presence = rpc_queued_presence;
        rpc_presence_queued = true;
    }
    ReleaseSRWLockExclusive(&rpc_presence_lock);
}

void discord_rpc_stop() {
    rpc_thread_running = false;
}

size_t get_discord_userid_length() {
    return user_id_length;
}

#endif