project('squiroll', 'cpp',
  default_options : [
    'cpp_std=c++20',
    'warning_level=0',
    'optimization=2',
    'b_lto=true',
  ]
)

shared_inc = include_directories('src/shared')
netcode_inc = include_directories('src/Netcode/include')

rc = find_program('llvm-rc', required: true)
th155r_res = custom_target(
  'th155r_res',
  input: 'src/th155r/th155r.rc',
  output: 'th155r.res',
  command: [rc, '@INPUT@', '@OUTPUT@']
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
])

dll_netcode = shared_library(
  'Netcode',
  netcode_src,
  include_directories : [
    shared_inc,
    netcode_inc
  ],
  install : false,
)
