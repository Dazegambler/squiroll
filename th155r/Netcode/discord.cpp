#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <atomic>
#include "discord.h"
#include "util.h"
#include "log.h"

#if ENABLE_DISCORD_RICH_PRESENCE

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

static std::atomic_bool rpc_presence_queued;
static DiscordRPCPresence rpc_queued_presence;
static DiscordRPCPresence rpc_cur_presence;
static SRWLOCK rpc_presence_lock = SRWLOCK_INIT;

static bool pipe_open() {
	if (rpc_pipe != INVALID_HANDLE_VALUE)
		return true;

	char path[] = "\\\\?\\pipe\\discord-ipc-0";
	constexpr size_t digit = sizeof(path) - 2;

	while (true) {
		rpc_pipe = CreateFileA(path, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);
		if (rpc_pipe != INVALID_HANDLE_VALUE)
			return true;

		auto err = GetLastError();
		if (err == ERROR_FILE_NOT_FOUND) {
			if (path[digit] < '9') {
				path[digit]++;
				continue;
			}
		}
		else if (err == ERROR_PIPE_BUSY) {
			if (!WaitNamedPipeA(path, 1000))
				return false;
			continue;
		}
		return false;
	}
}

static void pipe_close() {
	if (rpc_pipe != INVALID_HANDLE_VALUE)
		CloseHandle(rpc_pipe);
	rpc_pipe = INVALID_HANDLE_VALUE;
	rpc_connected = false;
}

static bool pipe_write(void* data, size_t len) {
	if (rpc_pipe == INVALID_HANDLE_VALUE)
		return false;

	DWORD written = 0;
	if (WriteFile(rpc_pipe, data, len, &written, NULL) && written == len)
		return true;

	pipe_close();
	return false;
}

static bool pipe_read(void* data, size_t len) {
	if (rpc_pipe == INVALID_HANDLE_VALUE)
		return false;

	// The official implementation uses PeekNamedPipe here, but I don't know if that's necessary
	DWORD avail = 0;
	if (PeekNamedPipe(rpc_pipe, NULL, 0, NULL, &avail, NULL)) {
		if (avail >= len) {
			if (ReadFile(rpc_pipe, data, len, NULL, NULL))
				return true;
		} else {
			// Don't close!
			return false;
		}
	}

	log_printf("PeekNamedPipe failed: 0x%X\n", GetLastError());
	pipe_close();
	return false;
}

static bool rpc_read_msg() {
	if (rpc_pipe == INVALID_HANDLE_VALUE)
		return false;

	while (true) {
		if (!pipe_read(&rpc_recv_msg, HeaderSize) || rpc_recv_msg.len >= sizeof(rpc_recv_msg.msg))
			return false;

		if (!pipe_read(&rpc_recv_msg.msg, rpc_recv_msg.len))
			return false;
		rpc_recv_msg.msg[rpc_recv_msg.len] = '\0';

		switch (rpc_recv_msg.opcode) {
			case Opcode::Frame:
				return true;
			case Opcode::Ping: {
				rpc_recv_msg.opcode = Opcode::Pong;
				if (!pipe_write(&rpc_recv_msg, HeaderSize + rpc_recv_msg.len))
					return false;
				break;
			}
			case Opcode::Pong:
				break;
			default: {
				log_printf("Bad opcode: 0x%X\n", rpc_recv_msg.opcode);
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

		while (!rpc_read_msg()) {
			if (!rpc_thread_running.load() || rpc_pipe == INVALID_HANDLE_VALUE)
				return;
			Sleep(100);
		}

		rpc_connected = true;
		log_printf("Discord RPC connected\n");
	}

	if (rpc_presence_queued.load()) {
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

		rpc_presence_queued.store(false);
		ReleaseSRWLockShared(&rpc_presence_lock);

		snprintf(rpc_send_msg.msg, sizeof(rpc_send_msg.msg), R"({"cmd":"SET_ACTIVITY","nonce":%zu,"args":{"pid":%lu,"activity":{%s}}})", rpc_nonce++, rpc_pid, activity.finish());
		log_printf("Updating rich presence: %s\n", rpc_send_msg.msg);

		rpc_send_msg.opcode = Opcode::Frame;
		rpc_send_msg.len = strlen(rpc_send_msg.msg);
		pipe_write(&rpc_send_msg, HeaderSize + rpc_send_msg.len);
	}
}

static DWORD stdcall rpc_thread_proc(void*) {
	rpc_thread_running.store(true);
	while (rpc_thread_running.load()) {
		rpc_update();
		Sleep(500);
	}
	return 0;
}

void discord_rpc_start() {
	rpc_pid = GetCurrentProcessId();
	rpc_thread = CreateThread(NULL, 0, rpc_thread_proc, NULL, 0, NULL);
}

#define RPC_FIELD(field) \
	void discord_rpc_set_##field(const char* value) { \
		strncpy(rpc_queued_presence.field, value, sizeof(rpc_queued_presence.field)); \
		rpc_queued_presence.field[sizeof(rpc_queued_presence.field) - 1] = '\0'; \
	}
RPC_FIELDS
#undef RPC_FIELD

void discord_rpc_commit() {
	AcquireSRWLockExclusive(&rpc_presence_lock);
	if (memcmp(&rpc_cur_presence, &rpc_queued_presence, sizeof(DiscordRPCPresence))) {
		memcpy(&rpc_cur_presence, &rpc_queued_presence, sizeof(DiscordRPCPresence));
		rpc_presence_queued.store(true);
	}
	ReleaseSRWLockExclusive(&rpc_presence_lock);
}

void discord_rpc_stop() {
	rpc_thread_running.store(false);
}

#endif