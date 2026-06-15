project('squiroll', 'cpp',
  default_options : [
    'cpp_std=c++20',
    'warning_level=0',
    'buildtype=release',
    'optimization=2',
    'b_vscrt=mt',
    'b_lto=true',
  ]
)

add_project_arguments(
  language : 'cpp',
)

shared_inc = include_directories('src/shared')
netcode_inc = include_directories('src/Netcode/include')

python = find_program('python3', 'python', required: true)
rc = find_program('llvm-rc', required: true)

embed_includes = custom_target(
  'embed_includes',
  output: [
    'embed_declarations.inc',
    'embed_map.inc',
  ],
  command: [
    python,
    files('generate_embeds.py'),
    '@OUTPUT0@',
    '@OUTPUT1@',
  ],
  build_by_default : true,
)

th155r_res = custom_target(
  'th155r_res',
  input: 'src/th155r/th155r.rc',
  output: 'th155r.res',
  command: [rc, '/fo', '@OUTPUT@', '@INPUT@']
)

th155r_src = [
  'src/th155r/main.cpp',
  th155r_res
]

exe_th155r = executable(
  'th155r',
  th155r_src,
  include_directories : shared_inc,
  install : false,
)

netcode_src = files([
  'src/Netcode/overlay.cpp',
  'src/Netcode/file_replacement.cpp',
  'src/Netcode/alloc_man.cpp',
  'src/Netcode/config.cpp',
  'src/Netcode/main.cpp',
  'src/Netcode/better_game_loop.cpp',
  'src/Netcode/netcode.cpp',
  'src/Netcode/lobby.cpp',
  'src/Netcode/frame_data_display.cpp',
  'src/Netcode/sq_debug.cpp',
  'src/Netcode/patch_utils.cpp',
  'src/Netcode/misc.cpp',
  'src/Netcode/RSACache.cpp',
  'src/Netcode/rollback.cpp',
  'src/Netcode/log.cpp',
  'src/Netcode/discord.cpp',
  'src/Netcode/plugin.cpp',
]) + embed_includes

shared_library(
  'Netcode',
  netcode_src,
  include_directories : [
    shared_inc,
    netcode_inc,
    include_directories('src/Netcode')
  ],
  link_args : [
    'user32.lib',
    'WS2_32.lib',
    'dbghelp.lib',
    'winmm.lib',
    '-exclude-all-symbols',
    '-kill-at',
    '/DEF:' + meson.project_source_root() / 'Netcode.def',
  ],
  install : false,
)
