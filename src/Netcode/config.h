#pragma once

#ifndef CONFIG_H
#define CONFIG_H 1

#include <stdint.h>
#include <stdlib.h>


#include "util.h"

// Increase the main version number whenever a change
// results in incompatibilites with the previous netcode.
static inline constexpr size_t PLUGIN_VERSION = 1;
// Increase the revision number for bugfixing builds and
// other sorts of changes that don't make the netcode
// incompatible. Reset to 0 whenever increasing the main version.
static inline constexpr size_t PLUGIN_REVISION = 4;

extern int32_t GAME_VERSION;

void init_config_file();

enum ConfigTestState : int8_t {
    ConfigNeedsTest = -1,
    ConfigDisabled = 0,
    ConfigEnabled = 1
};

#define TST_CONFIG_MAYBE(...) ((__VA_ARGS__)<0)
#define TST_CONFIG_DISABLED(...) ((__VA_ARGS__)==0)
#define TST_CONFIG_ENABLED(...) ((__VA_ARGS__)>0)

const char* get_lobby_host(const char* host);
const char* get_lobby_port(const char* port);
const char* get_lobby_pass(const char* pass);

bool get_ping_enabled();
int32_t get_ping_x();
int32_t get_ping_y();
float get_ping_scale_x();
float get_ping_scale_y();
uint32_t get_ping_color();
bool get_ping_frames();

bool get_inputp1_enabled();
int32_t get_inputp1_x();
int32_t get_inputp1_y();
float get_inputp1_scale_x();
float get_inputp1_scale_y();
int32_t get_inputp1_offset();
int32_t get_inputp1_count();
uint32_t get_inputp1_color();
bool get_inputp1_spacing();
int32_t get_inputp1_timer();
bool get_inputp1_raw_input();

bool get_inputp2_enabled();
int32_t get_inputp2_x();
int32_t get_inputp2_y();
float get_inputp2_scale_x();
float get_inputp2_scale_y();
int32_t get_inputp2_offset();
int32_t get_inputp2_count();
uint32_t get_inputp2_color();
bool get_inputp2_spacing();
int32_t get_inputp2_timer();
bool get_inputp2_raw_input();

bool get_hitbox_vis_enabled();
int32_t get_hitbox_border_width();
float get_hitbox_inner_alpha();
float get_hitbox_border_alpha();
uint32_t get_hitbox_collision_col();
uint32_t get_hitbox_hit_col();
uint32_t get_hitbox_player_hurt_col();
uint32_t get_hitbox_player_unhit_col();
uint32_t get_hitbox_player_ungrab_col();
uint32_t get_hitbox_player_unhit_ungrab_col();
uint32_t get_hitbox_misc_hurt_col();

int8_t get_ipv6_state();
bool get_netplay_state();
bool get_hide_ip_enabled();
bool get_share_watch_ip_enabled();
bool get_hide_name_enabled();
bool get_prevent_input_drops();
void set_ipv6_state(bool state);

bool get_cache_rsa_enabled();
bool get_better_game_loop_enabled();
float get_timer_leniency();

bool get_hide_wip_enabled();
bool get_skip_intro_enabled();
int8_t get_discord_enabled();
bool get_dev_mode_enabled();
void set_discord_enabled(bool state);

#endif