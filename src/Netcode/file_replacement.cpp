#if __INTELLISENSE__
#undef _HAS_CXX20
#define _HAS_CXX20 0
#endif

#include <stdint.h>
#include <stdlib.h>
#include <windows.h>

#include <string>
#include <string_view>
#include <unordered_map>

#include "util.h"
#include "patch_utils.h"
#include "file_replacement.h"

using namespace std::literals::string_view_literals;

//||||||||||||||||||||||||||||||||||
// FILE REPLACEMENTS
//||||||||||||||||||||||||||||||||||

// BATTLE
static constexpr uint8_t battle_nut[] = {
#embed "embed/battle/battle.nut"
};

static constexpr uint8_t battle_network_nut[] = {
#embed "embed/battle/battle_network.nut"
};

static constexpr uint8_t battle_vs_player_nut[] = {
#embed "embed/battle/battle_vs_player.nut"
};

static constexpr uint8_t battle_team_nut[] = {
#embed "embed/battle/battle_team.nut"
};

// NETWORK
static constexpr uint8_t network_nut[] = {
#embed "embed/network/network.nut"
};

static constexpr uint8_t network_component_nut[] = {
#embed "embed/network/network_component.nut"
};

static constexpr uint8_t network_animation_nut[] = {
#embed "embed/network/network_animation.nut"
};

// CONFIG
static constexpr uint8_t config_nut[] = {
#embed "embed/config/config.nut"
};

static constexpr uint8_t config_animation_nut[] = {
#embed "embed/config/config_animation.nut"
};

// DIALOG
static constexpr uint8_t dialog_wait_nut[] = {
#embed "embed/dialog/dialog_wait.nut"
};

static constexpr uint8_t dialog_connect_nut[] = {
#embed "embed/dialog/dialog_connect.nut"
};

// CHARACTER
static constexpr uint8_t mokou_nut[] = {
#embed "embed/character/mokou.nut"
};

static constexpr uint8_t tenshi_shot_nut[] = {
#embed "embed/character/tenshi_shot.nut"
};

static constexpr uint8_t kokoro_nut[] = {
#embed "embed/character/kokoro.nut"
};

// MISC
static constexpr uint8_t version_nut[] = {
#embed "embed/version.nut"
};

static constexpr uint8_t title_nut[] = {
#embed "embed/title.nut"
};

static constexpr uint8_t character_select_animation_nut[] = {
#embed "embed/character_select_animation.nut"
};

static constexpr uint8_t menu_nut[] = {
#embed "embed/menu.nut"
};

static constexpr uint8_t boot_nut[] = {
#embed "embed/boot.nut"
};

static constexpr uint8_t watch_nut[] = {
#embed "embed/watch.nut"
};

static constexpr uint8_t replay_select_view_nut[] = {
#embed "embed/replay_select_view.nut"
};

static constexpr uint8_t input_nut[] = {
#embed "embed/input.nut"
};

static constexpr uint8_t loop_nut[] = {
#embed "embed/loop.nut"
};

//||||||||||||||||||||||||||||||||||
// NEW FILES
//||||||||||||||||||||||||||||||||||

// PLUGIN
static constexpr uint8_t pluginCFG_nut[] = {
#embed "embed/plugin/core/cfg.nut"
};

static constexpr uint8_t plugin_nut[] = {
#embed "embed/plugin/core/manager.nut"
};

static constexpr uint8_t frame_data_nut[] = {
#embed "embed/plugin/frame_data.nut"
};

static constexpr uint8_t input_display_nut[] = {
#embed "embed/plugin/input_display.nut"
};

static constexpr uint8_t rollback_nut[] = {
#embed "embed/plugin/rollback.nut"
};

static constexpr uint8_t ping_display_nut[] = {
#embed "embed/plugin/ping_display.nut"
};

static constexpr uint8_t misc_inputs_nut[] = {
#embed "embed/plugin/misc_inputs.nut"
};

// UI
static constexpr uint8_t UICore_nut[] = {
#embed "embed/UI/core.nut"
};

static constexpr uint8_t UIMenu_nut[] = {
#embed "embed/UI/menu.nut"
};

static constexpr uint8_t UI_nut[] = {
#embed "embed/UI/ui.nut"
};
// CONFIG
static constexpr uint8_t mod_config_nut[] = {
#embed "embed/config/mod_config.nut"
};

static constexpr uint8_t network_config_nut[] = {
#embed "embed/config/network_config.nut"
};

static const std::unordered_map<std::string_view, const EmbedData> embeds = {
    //REPLACEMENTS
    {"data/system/network/network.nut"sv, network_nut},
    {"data/system/network/dialog_wait.nut"sv, dialog_wait_nut},
    {"data/system/network/dialog_connect.nut"sv, dialog_connect_nut},
    {"data/system/network/network_animation.nut"sv, network_animation_nut},
    
    {"data/script/battle/battle.nut"sv, battle_nut},
    {"data/script/battle/battle_network.nut"sv, battle_network_nut},
    {"data/script/battle/battle_team.nut"sv, battle_team_nut},
    {"data/script/battle/battle_vs_player.nut"sv, battle_vs_player_nut},

    {"data/system/component/network.nut"sv, network_component_nut},
    {"data/system/title/title.nut"sv, title_nut},
    {"data/system/config/config.nut"sv, config_nut},
    {"data/system/config/config_animation.nut"sv, config_animation_nut},
    {"data/system/select/script/character_select_animation.nut"sv, character_select_animation_nut},
    {"data/system/boot/boot.nut"sv, boot_nut},
    {"data/system/watch/watch.nut"sv, watch_nut},
    {"data/system/replay_select/replay_select_view.nut"sv, replay_select_view_nut},
    
    {"data/script/input.nut"sv, input_nut},
    {"data/script/loop.nut"sv, loop_nut},
    {"data/script/menu.nut"sv, menu_nut},
    {"data/script/version.nut"sv, version_nut},
    
    {"data/actor/mokou.nut"sv, mokou_nut},
    {"data/actor/tenshi_shot.nut"sv, tenshi_shot_nut},
    {"data/actor/kokoro.nut"sv, kokoro_nut},
    //NEW FILES
    {"squiroll/plugin/frame_data.nut"sv, frame_data_nut},
    {"squiroll/plugin/input_display.nut"sv, input_display_nut},
    {"squiroll/plugin/ping_display.nut"sv, ping_display_nut},
    {"squiroll/plugin/misc_inputs.nut"sv, misc_inputs_nut},
    {"squiroll/plugin/rollback.nut"sv, rollback_nut},
    {"squiroll/plugin/core/cfg.nut"sv, pluginCFG_nut},
    {"squiroll/plugin/core/manager.nut"sv, plugin_nut},
    {"squiroll/UI/core.nut",UICore_nut},
    {"squiroll/UI/menu.nut",UIMenu_nut},
    {"squiroll/UI/ui.nut"sv, UI_nut},
    {"squiroll/config/mod_config.nut"sv, mod_config_nut},
    {"squiroll/config/network_config.nut"sv, network_config_nut},
};

EmbedData get_embed_data(const char* name) {
    auto new_file = embeds.find(name);
    if (new_file != embeds.end()) {
        return new_file->second;
    }
    return {};
}
