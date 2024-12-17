#pragma once

#ifndef DISCORD_H
#define DISCORD_H 1

#include <string>
#include <string_view>

extern bool DISCORD_ENABLED;

#define ENABLE_DISCORD_INTEGRATION 0

#if ENABLE_DISCORD_INTEGRATION

struct DiscordRPCPresence {
	char state[128];
	char details[128];
	char large_img_key[32];
	char large_img_text[128];
	char small_img_key[32];
	char small_img_text[128];
};

void discord_rpc_start();
void discord_rpc_commit();
void discord_rpc_stop();

#define RPC_FIELDS \
	RPC_FIELD(state) \
	RPC_FIELD(details) \
	RPC_FIELD(large_img_key) \
	RPC_FIELD(large_img_text) \
	RPC_FIELD(small_img_key) \
	RPC_FIELD(small_img_text) \

#define RPC_FIELD(field) void discord_rpc_set_##field(const char* value);
RPC_FIELDS
#undef RPC_FIELD

std::string_view get_discord_username();

#else

#define RPC_FIELDS

#endif

#endif