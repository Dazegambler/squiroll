Squiroll
---
[![GitHub Release](https://img.shields.io/github/release/dazegambler/squiroll.svg)](https://github.com/Dazegambler/squiroll/releases)

Squiroll is a patcher made for Touhou 15.5 that adds missing QOL features to the game alongside adding rollback based netcode to the game(Future plan)

Prerequisites
---
### - [clang](https://releases.llvm.org/download.html)
### - [xwin(linux)](https://github.com/Jake-Shadle/xwin)

Build
---
Clone the repository:
```sh
git clone --recursive https://github.com/Dazegambler/squiroll.git
```

### Linux
To build the project, follow these steps:
1. Acquire the  windows SDK headers and libraries with xwin 

    ```sh
    cd /path/to/xwin
    xwin --accept-license --arch x86 splat
    ```
2. Build the tools
    ```sh
    cd /path/to/squiroll/tools
    ./build.sh
    cd ..
    ```
3. Run the `build.sh` script:

    ```sh
    ./build.sh
    ```
### Windows

1. Build the tools
    ```sh
    cd /path/to/squiroll/tools
    ./build.bat
    cd ..
    ```
2. Run the `build.bat` script:

    ```batch
    build.bat
    ```
    
Usage
---

### Windows
1. Put the following files on your game directory:
- `th155r.exe`
- `Netcode.dll`
2. Run the game from `th155r.exe`

### Linux
1. Put the following files on your game directory:
- `th155r.exe`
- `Netcode.dll`
2. Run `th155r.exe` with your preferred wine version/fork

#### Steam/Proton
- If you're running the game on steam via proton simply change the target executable in the properties for `/path/to/game/th155r.exe`

- If you're running the steam version you're going to need to add `th155r.exe` as a non steam game and change its compatibility settings to force it to run via proton
