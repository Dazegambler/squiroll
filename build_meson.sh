meson setup build/ --reconfigure --cross-file toolchain/windows-clang-cl.txt

meson compile -C build
