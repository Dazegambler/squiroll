#pragma once

#ifndef CONFIG_H
#define CONFIG_H 1

#include <stdint.h>
#include <stdlib.h>


#include "util.h"

void init_config_file();

const char* get_lobby_host(const char* host);
const char* get_lobby_port(const char* port);
const char* get_lobby_pass(const char* pass);
int32_t get_ping_x();
int32_t get_ping_y();
float get_ping_scale_x();
float get_ping_scale_y();

#endif