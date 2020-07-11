*I just wanted to unpack all my gogrepo-downloaded games with one unified script. Then this happend*

**Features**:
- **Fast and easy installation of all gogrepo-downloaded games**. Say, in order to install ftl you will need to just type `./goginst.sh faster*` and thats about it
- Optional creation of **XDG-compatible menu entries**, so you will be able to run your games right away from your favorite menu launcher, will it be whisker, gnome-menu or whatever - as if they were installed from repo
- **Goodies unpacker**. Will they be OSTs or wallpapers - for as long as you want it, they will be automatically unpacked into selected game-specific directory. No need to manually call for archive manager anymore!
- **Interactive search**. Too lazy to type in whole game's name? Dont worry, asterisks and other expressions are supported. If there are multiple games matching your input - you will be asked to pick the one, you trully wanted
- **Highly configurable with a single file**. Everything you want can be configured with one single file. Wanna change directory used to store installed games? Disable generation of menu entries? Or turn off interactive mode completely, to use script as part of daily automated update system in cron? No problems, just edit damn configuration file and thats about it! No messing with command line options required! (just dont type in anything stupid)

**Usage**:
- Throw this script somewhere
- During first run, enter required settings (or just edit configfile afterwards)
- Use script like that: `./goginst.sh <slug-of-the-game-you-want-to-unpack>` (where slug is basically the name of your game's subdirectory, created by gogrepo. E.g, say, for "Death Road to Canada" it will be "death_road_to_canada")

**Dependencies**:
- coreutils
- bash
- unzip (to unpack .zip files, located inside .sh installers)
- grep
- gvfs/gio (for gio trash, will be removed once I will be sure that this script is stable enough)

**Optional Dependencies**:
- innoextract (to unpack .exe installers)
- [gogextract](https://github.com/Yepoleb/gogextract) (to unpack .sh installers faster)
- jq (to create XDG-compatible menu entries for wine games)

**Limitations a.k.a "before you complain"**:
- During its work, script **uses disk space equal to up to x3 of game's size**. That happens because it first needs to get zip archive from gog-provided installer, then unpack it, and only then move received game files into their destination directory. Im looking for a way to reduce it a bit, probably with next update.
- For now, there is **no support for patch files** (used to update windows games from one version to another without redownloading entire game). Thats because of the way this script has been made - it doesnt track which version of game you've already installed, thus there is no way to decide which patch to apply. I *may* do something about that problem in future, but no ETA since I dont use these by myself.
- For now, **there is no free space check or preallocation**. Im trying to find a way to achieve that, but right now you should check by uself if you have enough free space on your hard drive before installing something
- Since its the only interface around unpackers, **it doesnt create wineprefixes for windows executables**. I *may* add something like that at some point. But since lot of games require not only custom prefix settings but also different wine versions (with certain patches), which kinda comes against the idea of having one unified script for everything - its highly unlikely

**#TODO**:
- Further code improvements
- Built-in help, so I will be able to throw half of "usage" category into the trash bin
- Checks for free space before installation
- Trully interactive mode
- Basic per-game wineprefix creation
- Remove gio from dependencies. I mean - I can already do that, but I want a bit more testing, just to be sure
- Yad/zenity GUI. Someday. Probably. Very unlikely
