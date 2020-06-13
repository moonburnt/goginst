Because I needed something to *just unpack selected games into selected directory*.

**Usage**:
- Throw this script somewhere
- Create `config` file inside `$HOME/.config/goginst` directory
- Write down script's settings according to your setup (you can find list of settings you can freely change in `##Fallback values` category on the very beginning of script)
- Run script like that: `./goginst.sh slug-of-the-game-you-want-to-unpack` (where slug is basically the name of your game's subdirectory, created by gogrepo. E.g, say, for "Death Road to Canada" it will be "death_road_to_canada")

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
- Additional safety checks here and there to shutdown script right away if things went wrong
- Unpacking multiple games with one command
- Further code improvements
- Automatically create configfile with default values, in case it doesnt exist (so it will be easier to edit)
- Built-in help, so I can throw half of "usage" category into the trash bin
