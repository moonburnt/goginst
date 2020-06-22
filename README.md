Because I needed something to *just unpack selected games into selected directory*.

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

**Limitations a.k.a "before you complain"**:
- During its work, script **uses disk space equal to up to x3 of game's size**. That happens because it first needs to get zip archive from gog-provided installer, then unpack it, and only then move received game files into their destination directory. Im looking for a way to reduce it a bit, probably with next update.
- For now, there is **no support for patch files** (used to update windows games from one version to another without redownloading entire game). Thats because of the way this script has been made - it doesnt track which version of game you've already installed, thus there is no way to decide which patch to apply. I *may* do something about that problem in future, but no ETA since I dont use these by myself.
- For now, **there is no free space check or preallocation**. Im trying to find a way to achieve that, but right now you should check by uself if you have enough free space on your hard drive before installing something

**#TODO**:
- Further code improvements
- Built-in help, so I will be able to throw half of "usage" category into the trash bin
- Remove gio from dependencies
- Zenity GUI. Someday. Probably. Very unlikely
