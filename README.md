# Aocf_rollback

Aocf rollback aims to add rollback based netcode to touhou 15.5:Antinomy of Common Flowers

### As of now we only have a patcher working, we're currently working on making the netcode that is going to replace the currently existing one in the game

# Progress Dashboard:
### ~~Frame restoration/saving~~
### Input Management
### ~~Memory Allocation hooking~~
### ~~Frame stepping~~
## Prerequisites

- [i686-w64-mingw32-gcc](https://www.mingw-w64.org/downloads/)

## Build

Clone the repository:

```sh
git clone https://github.com/Dazegambler/Aocf_rollback
cd Aocf_rollback
```


### Linux

To build the project, follow these steps:


1. Make sure you have `i686-w64-mingw32-gcc` installed. You can install it via your package manager:

    ```sh
    sudo apt-get install mingw-w64
    ```

2. Run the `build.sh` script:

    ```sh
    ./build.sh
    ```

This will compile the source code and produce the following output files:
- `th155r.exe`
- `Netcode.dll`

### Windows

1. Ensure you have [MinGW-w64](https://www.mingw-w64.org/downloads/) installed.
2. Open a terminal and navigate to the project directory.
3. Run the `build.bat` script:

    ```batch
    build.bat
    ```
    
## Usage

### Windows
1. Put the following files on your game directory:
- `th155r.exe`
- `Netcode.dll`
2. Run the game from the `th155r.exe` file

### Linux
1. Put the following files on your game directory:
- `th155r.exe`
- `Netcode.dll`
2. Run `th155r.exe` with your preferred wine version/fork

#### Steam/Proton
- If you're running the game on steam via proton simply change the target executable in the properties for `/path/to/game/th155r.exe`

- If you're running the steam version you're going to need to add `th155r.exe` as a non steam game and change its compatibility settings to force it to run via proton
