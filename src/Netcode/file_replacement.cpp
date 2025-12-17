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

static constexpr uint8_t network_nut[] = {
#include "embed/network.nut.h"
};

static constexpr uint8_t network_component_nut[] = {
#include "embed/network_component.nut.h"
};

static constexpr uint8_t network_animation_nut[] = {
#include "embed/network_animation.nut.h"
};

static constexpr uint8_t version_nut[] = {
#include "embed/version.nut.h"
};

static constexpr uint8_t title_nut[] = {
#include "embed/title.nut.h"
};

static constexpr uint8_t config_nut[] = {
#include "embed/config.nut.h"
};

static constexpr uint8_t config_animation_nut[] = {
#include "embed/config_animation.nut.h"
};

static constexpr uint8_t battle_nut[] = {
#include "embed/battle.nut.h"
};

static constexpr uint8_t battle_network_nut[] = {
#include "embed/battle_network.nut.h"
};

static constexpr uint8_t dialog_wait_nut[] = {
#include "embed/dialog_wait.nut.h"
};

static constexpr uint8_t character_select_animation_nut[] = {
#include "embed/character_select_animation.nut.h"
};

static constexpr uint8_t menu_nut[] = {
#include "embed/menu.nut.h"
};

static constexpr uint8_t boot_nut[] = {
#include "embed/boot.nut.h"
};

static constexpr uint8_t battle_vs_player_nut[] = {
#include "embed/battle_vs_player.nut.h"
};

static constexpr uint8_t watch_nut[] = {
#include "embed/watch.nut.h"
};

static constexpr uint8_t replay_select_view_nut[] = {
#include "embed/replay_select_view.nut.h"
};

static constexpr uint8_t input_nut[] = {
#include "embed/input.nut.h"
};

static constexpr uint8_t mokou_nut[] = {
#include "embed/mokou.nut.h"
};

static constexpr uint8_t tenshi_shot_nut[] = {
#include "embed/tenshi_shot.nut.h"
};

static constexpr uint8_t kokoro_nut[] = {
#include "embed/kokoro.nut.h"
};

//static constexpr uint8_t actor_nut[] = {
//#include "embed/actor.nut.h"
//};

static constexpr uint8_t battle_team_nut[] = {
#include "embed/battle_team.nut.h"
};

static constexpr uint8_t loop_nut[] = {
#include "embed/loop.nut.h"
};

static constexpr uint8_t dialog_connect_nut[] = {
#include "embed/dialog_connect.nut.h"
};

static constexpr uint8_t debug_nut[] = {
#include "embed/debug.nut.h"
};

static constexpr uint8_t mod_config_nut[] = {
#include "embed/mod_config.nut.h"
};

static constexpr uint8_t UI_nut[] = {
#include "embed/UI.nut.h"
};

static constexpr uint8_t frame_data_nut[] = {
#include "embed/frame_data.nut.h"
};

static constexpr uint8_t input_display_nut[] = {
#include "embed/input_display.nut.h"
};

static constexpr uint8_t rollback_nut[] = {
#include "embed/rollback.nut.h"
};

// static constexpr uint8_t setting_nut[] = {
// #include "embed/setting.nut.h"
// };

static constexpr uint8_t ping_display_nut[] = {
#include "embed/ping_display.nut.h"
};

static constexpr uint8_t plugin_nut[] = {
#include "embed/plugin.nut.h"
};

static constexpr uint8_t misc_inputs_nut[] = {
#include "embed/misc_inputs.nut.h"
};

static constexpr uint8_t network_config_nut[] = {
#include "embed/network_config.nut.h"
};

static constexpr uint8_t patches_nut[] = {
#include "embed/patches.nut.h"
};

// static constexpr uint8_t actor_rollback_nut[] = {
// #include "embed/actor_rollback.nut.h"
// };

static const std::unordered_map<std::string_view, const EmbedData> embeds = {
    {"data/system/network/network.nut"sv, network_nut},
    {"data/system/component/network.nut"sv, network_component_nut},
    {"data/system/network/network_animation.nut"sv, network_animation_nut},
    {"data/script/version.nut"sv, version_nut},
    {"data/script/battle/battle.nut"sv, battle_nut},
    {"data/script/battle/battle_network.nut"sv, battle_network_nut},
    {"data/system/title/title.nut"sv, title_nut},
    {"data/system/config/config.nut"sv, config_nut},
    {"data/system/config/config_animation.nut"sv, config_animation_nut},
    {"data/system/network/dialog_wait.nut"sv, dialog_wait_nut},
    {"data/system/network/dialog_connect.nut"sv, dialog_connect_nut},
    {"data/system/select/script/character_select_animation.nut"sv, character_select_animation_nut},
    {"data/script/menu.nut"sv, menu_nut},
    {"data/system/boot/boot.nut"sv, boot_nut},
    {"data/script/battle/battle_vs_player.nut"sv, battle_vs_player_nut},
    {"data/system/watch/watch.nut"sv, watch_nut},
    {"data/system/replay_select/replay_select_view.nut"sv, replay_select_view_nut},
    {"data/script/input.nut"sv, input_nut},
    {"data/actor/mokou.nut"sv, mokou_nut},
    {"data/actor/tenshi_shot.nut"sv, tenshi_shot_nut},
    {"data/actor/kokoro.nut"sv, kokoro_nut},
    //{"data/script/actor.nut"sv, actor_nut},
    {"data/script/battle/battle_team.nut"sv, battle_team_nut},
    {"data/script/loop.nut"sv, loop_nut},

	{"patches.nut"sv, patches_nut},
    {"debug.nut"sv, debug_nut},
    {"UI.nut"sv, UI_nut},
    {"frame_data.nut"sv, frame_data_nut},
    {"mod_config.nut"sv, mod_config_nut},
    {"network_config.nut"sv, network_config_nut},
    {"input_display.nut"sv, input_display_nut},
    {"ping_display.nut"sv, ping_display_nut},
    {"misc_inputs.nut"sv, misc_inputs_nut},
    {"rollback.nut"sv, rollback_nut},
    // {"setting.nut"sv, setting_nut},
    {"plugin.nut"sv, plugin_nut},
    // {"actor_rollback.nut"sv, actor_rollback_nut},
};

EmbedData get_embed_data(const char* name) {
    auto new_file = embeds.find(name);
    if (new_file != embeds.end()) {
        return new_file->second;
    }
    return {};
}
