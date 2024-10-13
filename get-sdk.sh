#!/usr/bin/env sh
set -e
cargo install xwin
~/.cargo/bin/xwin --arch x86 splat --include-debug-libs --output ~/.xwin-cache/splat
