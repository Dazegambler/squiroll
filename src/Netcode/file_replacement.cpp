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

// To add new files: place xxx.nut under src/Netcode/embed/,
// add an entry to embed_manifest.txt, then run build.bat.
// No other C++ changes needed.

// Auto-generated embed declarations (arrays with #embed directives)
#include "embed_declarations.inc"

// Auto-generated embed map entries
static const std::unordered_map<std::string_view, const EmbedData> embeds = {
#include "embed_map.inc"
};

EmbedData get_embed_data(const char* name) {
    auto new_file = embeds.find(name);
    if (new_file != embeds.end()) {
        return new_file->second;
    }
    return {};
}
