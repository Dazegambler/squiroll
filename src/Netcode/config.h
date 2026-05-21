#pragma once

#ifndef CONFIG_H
#define CONFIG_H 1

#include <stdint.h>
#include <stdlib.h>


#include "util.h"

// Increase the main version number whenever a change
// results in incompatibilites with the previous netcode.
static inline constexpr size_t PLUGIN_VERSION = 2;
// Increase the revision number for bugfixing builds and
// other sorts of changes that don't make the netcode
// incompatible. Reset to 0 whenever increasing the main version.
static inline constexpr size_t PLUGIN_REVISION = 0;

extern int32_t GAME_VERSION;

void init_config_file();

void config_watcher_check();
void config_watcher_stop();

void set_config_string(const char* section, const char* key, const char* value);

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

bool get_hitbox_vis_enabled();
int32_t get_hitbox_border_width();
float get_hitbox_inner_alpha();
float get_hitbox_border_alpha();
uint32_t get_hitbox_collision_color();
uint32_t get_hitbox_hit_color();
uint32_t get_hitbox_player_hurt_color();
uint32_t get_hitbox_player_unhit_color();
uint32_t get_hitbox_player_ungrab_color();
uint32_t get_hitbox_player_unhit_ungrab_color();
uint32_t get_hitbox_misc_hurt_color();

int8_t get_ipv6_state();
bool get_hide_ip_enabled();
bool get_share_watch_ip_enabled();
bool get_hide_name_enabled();
bool get_hide_profile_pictures_enabled();
void set_ipv6_state(bool state);

bool get_cache_rsa_enabled();
float get_timer_leniency();

bool get_hide_wip_enabled();
bool get_skip_intro_enabled();
int8_t get_discord_enabled();
bool get_dev_mode_enabled();
void set_discord_enabled(bool state);

#endif
