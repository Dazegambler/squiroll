#pragma once

#ifndef DISCORD_H
#define DISCORD_H 1

#include <string>
#include <string_view>

#include "util.h"

#define ENABLE_DISCORD_INTEGRATION 1

#define ENABLE_DISCORD_LOGGING 1

#if !DISABLE_ALL_LOGGING_FOR_BUILD && ENABLE_DISCORD_LOGGING
#define log_discordf(...) log_printf(__VA_ARGS__)
#else
#define log_discordf(...) EVAL_NOOP(__VA_ARGS__)
#endif

#define RPC_FIELDS \
	RPC_FIELD(state) \
	RPC_FIELD(details) \
	RPC_FIELD(large_img_key) \
	RPC_FIELD(large_img_text) \
	RPC_FIELD(small_img_key) \
	RPC_FIELD(small_img_text) \

#if ENABLE_DISCORD_INTEGRATION

extern bool DISCORD_ENABLED;

struct DiscordRPCPresence {
	char state[128];
	char details[128] = "Idle";
	char large_img_key[32] = "mainicon";
	char large_img_text[128];
	char small_img_key[32];
	char small_img_text[128];
};

void discord_rpc_start();
void discord_rpc_commit();
void discord_rpc_stop();

#define RPC_FIELD(field) \
void discord_rpc_set_##field(const char* value);

RPC_FIELDS

#undef RPC_FIELD

size_t get_discord_userid_length();
extern char lobby_user_id[1 + INTEGER_BUFFER_SIZE<uint64_t>];

#else

#define RPC_FIELDS

#endif

#endif