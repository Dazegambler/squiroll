#pragma once

#ifndef CONFIG_H
#define CONFIG_H 1

#include <stdint.h>
#include <stdlib.h>


#include "util.h"

static inline constexpr size_t PLUGIN_VERSION = 1;

void init_config_file();

const char* get_lobby_host(const char* host);
const char* get_lobby_port(const char* port);
const char* get_lobby_pass(const char* pass);
int32_t get_ping_x();
int32_t get_ping_y();
float get_ping_scale_x();
float get_ping_scale_y();

enum IPv6State : int8_t {
	IPv6NeedsTest = -1,
	IPv6Disabled = 0,
	IPv6Enabled = 1
};

IPv6State get_ipv6_state();

void set_ipv6_state(bool state);

#endif