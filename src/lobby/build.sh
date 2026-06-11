#!/usr/bin/env sh

clang++ -std=c++20 -O2 aocf_server.cpp -o aocf_server.run -I../shared -Wno-switch -Wno-c99-designator -Wno-vla-cxx-extension -Wno-narrowing -DNOMINMAX -D_WINSOCKAPI_ -ferror-limit=100
