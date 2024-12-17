@echo off
clang++ -std=c++20 -O2 aocf_server.cpp -o aocf_server.exe -Wno-switch -Wno-c99-designator -Wno-vla-cxx-extension -ferror-limit=100
