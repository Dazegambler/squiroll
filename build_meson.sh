python3 generate_embeds.py
meson setup build/ --reconfigure --cross-file toolchain/windows-clang-cl.txt

meson compile -C build
