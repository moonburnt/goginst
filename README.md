Because I needed something to *just unpack selected games into selected directory*.

**Usage**:
- Throw this script somewhere
- Run it once to generate default configfile in `$HOME/.config/goginst/config`
- Edit configfile according to your setup
- Run script like that: `./goginst.sh <slug-of-the-game-you-want-to-unpack>` (where slug is basically the name of your game's subdirectory, created by gogrepo. E.g, say, for "Death Road to Canada" it will be "death_road_to_canada")

**Dependencies**:
- coreutils
- bash
- unzip (to unpack .zip files, located inside .sh installers)
- grep

**Optional Dependencies**:
- innoextract (to unpack .exe installers)
- [gogextract](https://github.com/Yepoleb/gogextract) (to unpack .sh installers faster)
- gio (optionally for "gio trash". Can be altered to "rm -f" or whatever you want)

**Notes a.k.a "before you complain"**:
- Before its work - as mentioned in "usage" category, script **needs to be configured**. Set paths of specified variables according to your system, and set "delfunc" to be whatever command you use to delete unwanted files (by default script tries to use "gio trash", in order to avoid accident data loss due to misconfigured settings).
- During its work, script **uses disk space equal to up to x3 of game's size**. That happens because it first needs to get zip archive from gog-provided installer, then unpack it, and only then move received game files into their destination directory. For now, Im unsure if its possible to fix even theoretically.
- For now, there is **no support for patch files** (used to update windows games from one version to another without redownloading entire game). Thats because of the way this script has been made - it doesnt track which version of game you've already installed, thus there is no way to decide which patch to apply. I *may* do something about that problem in future, but no ETA since I dont use these by myself.

**Limitations a.k.a #wontfix**:
- Space check and preallocation. Because I have no idea how to implement that without requiring to provide some config file for each update of each game (which kinda goes against the idea of this script, thats designed to be "unified" for everything you download)

**#TODO**:
- Further code improvements
- Built-in help, so I can throw half of "usage" category into the trash bin
- Optional interactive mode (for guided configfile creation and search)
