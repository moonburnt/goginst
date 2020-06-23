#!/bin/bash

### Copyright © 2020, moonburnt
###
### This program is free software. It comes without any warranty, to
### the extent permitted by applicable law. You can redistribute it
### and/or modify it under the terms of the Do What The Fuck You Want
### To Public License, Version 2, as published by Sam Hocevar.
### See the LICENSE file for more details.

### Script that makes extraction of gogrepo-downloaded games easier

##Global settings
scriptname=`basename "$0"`
scriptversion="0.8"

configpath="$HOME/.config/goginst"
configname="config"

delfunc="gio trash" #Command used to clean up temporary files

##Optional dependencies and miscelation options that dont need to be altered/configured manually by user. Will be overwritten by values from configfile, kept there in case they dont exist in it
inno=true
gogext=true
interactive=true
silent=true
menumaker=true

##Functions:
#returns false if $1 isnt directory or doesnt exist
dir_check() {
    if [ ! -d "$1" ]; then
        echo "$1 isnt directory or doesnt exist" >&2
        false
    fi
}

#returns false if $1 isnt file or doesnt exist
file_check() {
    if [ ! -f "$1" ]; then
        echo "$1 isnt file or doesnt exist" >&2
        false
    fi
}

#If dependency doesnt exist - returns "false". Which can be caught to either shut script down or change some variable's value
dep_check() {
    if [ ! $(command -v "$1") ]; then
        printf "$1 cant seem to be found on your system.\n" >&2
        false
    fi
}

#checks if $1 equal "true" or "false". If yes - prints $2 as message and $1 as variable's state, else - shuts script down with error
opt_check() {
    if [ -z "$2" ]; then
        echo "You're doing it wrong!"
        exit 1
    fi

    if [ "$1" == true ]; then
        printf " - $2: enabled\n"
    elif [ "$1" == false ]; then
        printf " - $2: disabled\n"
    else
        printf "Detected invalid configuration! Please edit or delete re-generate your config file and try again\n" >&2
        exit 1
    fi
}

#Creates menu entry file for passed game. Expects to receive two arguments - $1 as path to game's installation directory and $2 as type of game (wine or native)
menu_maker() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Function didnt receive enough arguments" >&2
        return 1
    fi

    if [ "$2" == "native" ]; then
        local gameinfo="$1/gameinfo"
        local gamename="$(head -n 1 "$1"/"gameinfo")"
        local gameicon="$1/support/icon.png"
        local game="$1/start.sh"
        local gamelauncher="$game"
    elif [ "$2" == "wine" ]; then
        dep_check "jq" || return 1

        local gameinfo="$(echo $1/goggame*.info)"
        local gamename="$(jq -r '.name' $1/goggame*.info)"
        local gameicon="$(echo $1/goggame*.ico)"
        local game="$1/$(jq -r '.playTasks | .[] | .path' $1/goggame*.info)"
        local gamelauncher="wine $game"
    else
        return 1
    fi
    local iconpath="$HOME/.local/share/applications"

    file_check "$gameinfo" || return 1
    file_check "$gameicon" || return 1
    file_check "$game" || return 1

    dir_check "$iconpath" || return 1

    if [ -f "$iconpath/$slug-goginst.desktop" ]; then
        echo "You already have menu entry for that game, wont overwrite" >&2
        return 1
    fi

    #Create menu file
    echo "Creating XDG-compatible menu file"
    printf "[Desktop Entry]
Type=Application
Version=1.0
Name=$gamename
GenericName=$slug
Icon=$gameicon
Exec=$gamelauncher
Terminal=false
Categories=Game;ActionGame;
Comment=" > "$iconpath/$slug-goginst.desktop"
}

#Creates configfile with default settings. Expects to receive two arguments - $1 for config path and $2 for configfile name
config_maker() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Thats not how this function works, retard" >&2
        exit 1
    fi

    #At first - lets determine if config dir exists. If exists but not dir - abort to avoid data loss. If exists - proceed, if doesnt exist - creating
    if [ -f "$1" ] || [ -L "$1" ]; then
        echo "$1 exists but isnt directory, abort" >&2
        exit 1
    elif [ -d "$1" ]; then
        echo "Found config directory, proceed"
    else
        echo "Config directory doesnt exist, creating"
        mkdir -p "$1" || exit 1
    fi

    #Now lets check if configfile exists and is file
    if [ -d "$1/$2" ] || [ -L "$1/$2" ]; then
        echo "$1/$2 exists but isnt file, abort" >&2
        exit 1
    elif [ -f "$1/$2" ]; then
        echo "Found $1/$2, proceed"
    else
        echo "Creating $2"
        #there goes configfile creation. Every new user-configurable variable should be added to this list
        if [ "$interactive" = true ]; then
            printf "Enter the path to your directory with gogrepo-downloaded games:\n"
            read downloads
            printf "Enter the path to directory that you would like to install games into:\n"
            read gamedir
            printf "Enter the path to directory that will be used to store temporary files:\n"
            read tempdir
            printf "Enter the path to gogextract.py, in case you have it and want to speed up unpacking of native linux games:\n"
            read extractor

            echo "Writing values into file"
        else
            downloads="$HOME/Downloads/gogrepo/"
            gamedir="$HOME/.local/share/games/gog/"
            tempdir="$HOME/.cache/goginst/temp/"
            extractor="$HOME/gogextract.py"
        fi

        printf "#This is a settings file for goginst.sh. Change values of variables below according to your setup. General bash rules apply
downloads=\"$downloads\" #Path to directory with gogrepo-downloaded games
gamedir=\"$gamedir\" #Path to directory that will contain your installed games
tempdir=\"$tempdir\" #Path to directory with temporary files
extractor=\"$extractor\" #Path to gogextract.py, which is used to speed up unpacking on native linux games

##Optional dependencies
inno=true #Determines if you want to unpack windows games. Default = true, if innoextract isnt found on your system - will be switched to false
gogext=true #Determines if you want to use gogextract.py, or rely on built-in version. Default = true, if gogextract.py isnt found on path provided via $extractor - will be switched to false
interactive=true #Determines if you want to enable some options that require user to confirm certain actions. Default = true, may be usefull to switch to false if you want goginst to perform as part of automated cronjob or something like that
silent=true #Determines if you want to see full output of unpacking scripts. Default = true
menumaker=true #Determines if you want to create XDG menu entries for games you've installed. Default = true" > "$1/$2"
    fi
}

#Extractor used as fallback option if gogextract.py doesnt exist. Receives $1 as input file and $2 as output dir, unpacks data.zip into output dir (coz we dont really need other stuff). Slower than gogextract.py due to dd's limitations
bash_extract() {
    #maybe I should I safety checks to mkdir? idk
    mkdir "$2" #coz dd cant create $tempdir/$slug by its own
    #Checking for first 10kbytes of installer in order to find offset size's variable, then importing it
    eval "$(dd count=10240 if=$1 bs=1 status=none | grep "head -n" | head -n 1)"
    #Safety check in case it didnt return the necessary info
    if [ -z "$offset" ]; then
        echo "Couldnt find the correct offset, abort" >&2
        exit 1
    else
        echo "Makeself script size: $offset"
    fi

    #Now lets do the same, but regarding mojosetup archive
    eval "$(dd count=10240 if=$1 bs=1 status=none | grep "filesizes=" | head -n 1)"

    if [ -z "$filesizes" ]; then
        echo "Couldnt find size of mojosetup archive, abort" >&2
        exit 1
    else
        echo "MojoSetup archive size: $filesizes"
    fi

    #With all necessary data gathered, unpacking the data
    echo "Extracting game files as data.zip (may take a while)"
    dd skip="$(($offset+$filesizes))" if="$1" of="$2/"data.zip ibs=1 status=none

    echo "Successfully unpacked $1"
}

#The main installation function. Expects to receive either "sh" or "exe" to decide about unpacking process
install() {

    #Checking if there are leftovers in our temporary directory. If yes - deleting them
    if [ -f "$tempdir/$slug" ] || [ -d "$tempdir/$slug" ] || [ -L "$tempdir/$slug" ]; then
        echo "Found leftover temporary files, cleaning up"
        $delfunc "$tempdir/$slug"
    fi

    #Checking if game's final destination exists and is directory
    if [ -f "$gamedir/$slug" ] || [ -L "$gamedir/$slug" ]; then
        echo "Unable to install the game - $gamedir/$slug exists but isnt directory. Please remove/rename it and try again"
        exit 1
    elif [ ! -d "$gamedir/$slug" ]; then
        echo "Didnt find $gamedir/$slug, creating"
        mkdir "$gamedir/$slug"
    fi

    #unpacking gamefiles and moving them into $gamedir/$slug
    if [ "$1" == "sh" ]; then
        #unpacking shells with gogextract
        for workfile in "${shells[@]}"; do
            echo "Unpacking $workfile"
            #if gogextract file has been found on its path - using it. Else - using built-in version which is noticably slower
            if [ "$gogext" == true ]; then
                if [ "$silent" == true ]; then
                    "$extractor" "$workfile" "$tempdir/$slug" >/dev/null || exit 1
                else
                    "$extractor" "$workfile" "$tempdir/$slug" || exit 1
                fi
            else
                if [ "$silent" == true ]; then
                    bash_extract "$workfile" "$tempdir/$slug" >/dev/null || exit 1
                else
                    "$extractor" "$workfile" "$tempdir/$slug" || exit 1
                fi
            fi

            if [ "$silent" == true ]; then
                unzip "$tempdir"/"$slug"/data.zip data/noarch/* -d "$tempdir"/"$slug" >/dev/null || exit 1
            else
                unzip "$tempdir"/"$slug"/data.zip data/noarch/* -d "$tempdir"/"$slug" || exit 1
            fi
            done

        #moving unpacked native game into $gamedir/$slug
        echo "Moving game files into $gamedir/$slug directory"
        cp -a "$tempdir"/"$slug"/data/noarch/* "$gamedir"/"$slug" || exit 1
        echo "Successfully moved game files into $gamedir/$slug"

        #creating menu file for game
        if [ "$menumaker" == true ]; then
            menu_maker "$gamedir"/"$slug" "native" || echo "Couldnt create menu entry for that game" >&2
        fi

    elif [ "$1" == "exe" ]; then
        #unpacking exes with innoextract
        for workfile in "${exes[@]}"; do
            echo "Unpacking $workfile"
            if [ "$silent" == true ]; then
                innoextract "$workfile" -d "$tempdir"/"$slug" >/dev/null || exit 1
            else
                innoextract "$workfile" -d "$tempdir"/"$slug" || exit 1
            fi
            done

        #moving unpacked wine game into $gamedir/$slug
        echo "Moving game files into $gamedir/$slug directory"
        cp -a "$tempdir"/"$slug"/app/* "$gamedir"/"$slug" || exit 1
        echo "Successfully moved game files into $gamedir/$slug"

        #creating menu file for game
        if [ "$menumaker" == true ]; then
            menu_maker "$gamedir"/"$slug" "wine" || echo "Couldnt create menu entry for that game" >&2
        fi

    else
        echo "Thats not how this function works, degenerate"
        exit 1
    fi

    echo "Cleaning up temporary files"
    $delfunc "$tempdir"/"$slug"
}


##Script
#Checking os version. If not linux - echoing warning about unsupported system
echo "Running $scriptname version $scriptversion"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    true
else
    echo "Your OS isnt officially supported. Proceed with caution!"
fi

#Looking for configfile and importing stats from it. If doesnt exist - creating the one with default stats
echo "Looking for configuration file in $configpath"
config_maker "$configpath" "$configname"

echo "Importing settings"
source "$configpath/$configname"

#Checking if provided paths are valid. If no - abort
dir_check "$downloads" || exit 1
dir_check "$gamedir" || exit 1
dir_check "$tempdir" || exit 1

#Checking if $extractor exists on its path. If no - using built-in
if [ ! -f "$extractor" ]; then
    printf '$extractor leads nowhere or isnt file, using built-in instead\n'
    gogext=false
fi

#If dep_check has returned false (which happens only in case dependency doesnt exist on your system) - shut script down
dep_check "unzip" || exit 1
dep_check "grep" || exit 1
#Since its optional dependency - if no innoextract has been found on user's system - set inno to false
dep_check "innoextract" || inno=false

#temporary, will be removed after testing
dep_check "gio" || exit 1

#Once all necessary checks are done, printing the values that will be used by script. Using printf coz echo is janky when it comes to printing multiple lines at once
printf "Running $scriptname with following settings:
 - Downloaded games directory: $downloads
 - Installed games directory: $gamedir
 - Temporary files directory: $tempdir
 - XDG menu entry creation: $menumaker\n"

if [ "$gogext" == true ]; then
    printf " - Shell extractor: $extractor\n"
elif [ "$gogext" == false ]; then
    printf " - Shell extractor: built-in\n"
else
    exit 1
fi

opt_check "$inno" "Innoextract support"
opt_check "$interactive" "Interactive mode"
opt_check "$silent" "Silent mode"

#Entering $downloads directory
cd "$downloads"

#Checking launch arguments. If none - printing info regarding usage and abort.
if [ "$#" == 0 ]; then
    echo "Input is empty. Usage: $scriptname game-to-unpack"
    exit 1
fi

#Trying to guess slug based on input. If there are no matching dirs - shutdown with error, if there is a match but its not dir - shutdown with error, if there are multiple results - depending on state of interactive mode, either shutdown or ask to specify one
shopt -s nullglob
search=("$@")
shopt -u nullglob

for x in "${!search[@]}"; do
    if [[ ! -d "${search[x]}" ]] || [[ "${search[x]}" == "!orphaned" ]] || [[ "${search[x]}" == "!downloading" ]]; then
        unset 'search[x]'
    fi
    done

if [ "${#search[@]}" == 0 ]; then
    echo "Couldnt find any games matching your input, abort"
    exit 1
elif [ "${#search[@]}" == 1 ]; then
    dir_check "${search[@]}" || exit 1
    slug="${search[@]}"
else
    if [ "$interactive" == false ]; then
        echo "Got multiple results. Please try again with something more accurate."
        echo "Current search returned: ${search[@]}"
        exit 1
    else
        echo "Got multiple results. Please select the correct one:"
        select choice in "${search[@]}"; do
        if [[ "$choice" ]]; then
            echo "You've selected $choice"
            break
        fi
        done
        slug="$choice"
    fi
fi
echo "Found game with slug $slug, proceed"

#Checking if our $slug directory contain native linux (.sh) or wine's .exe installation files and, if yes - proceed accordingly
shopt -s nullglob #this way we are avoiding inclusion of search command itself into array - so if there are no valid files, it wont trigger false-positive results
shells=(./"$slug"/*.sh) #removed check for slugs, coz some games (like dont starve) have installer names that dont match game's slug
exes=(./"$slug"/*.exe)
shopt -u nullglob #unchecking after creation of arrays to avoid unwanted behavior of other commands

#removing patch files from valid executables array, since these arent supported anyway
for x in "${!exes[@]}"; do
    if [[ "${exes[x]}" == *patch* ]]; then
        unset 'exes[x]'
    fi
    done

#If lengh of arrays isnt 0 - proceed
if ! [ "${#shells[@]}" == 0 ]; then
    echo "Found native shell installers, proceed"
    install "sh"
elif [ "$inno" = true ]; then
    if ! [ "${#exes[@]}" == 0 ]; then
        echo "Found exe installers, proceed"
        install "exe"
    else
        echo "No valid files has been found, abort"
        exit 1
    fi
else
    echo "No valid files has been found, abort"
    exit 1
fi

echo "Done"
exit 0
