#!/bin/bash
#wip gog games extractor

##Global settings
scriptname=`basename "$0"`
configfile="$HOME/.config/goginst/config"

##Fallback values. Used if config file doesnt feature any of these (or simply doesnt exist at all)
downloads="." #directory where our downloaded games located
gamedir="./goginst/Games" #directory where game's files will be moved at the end
tempdir="./goginst/temp" #directory where temp files will be located
extractor="./gogextract.py" #path to gogextract.py
delfunc="gio trash" #command used to clean temporary files


##Functions:
#If directory doesnt exist - shuts whole script down
dircheck() {
    if [ ! -d "$1" ]; then
        echo "$1 doesnt exist or isnt directory, abort"
        exit 1
    fi
}

#If dependency doesnt exist - shuts script down
depcheck() {
    if [ ! $(command -v "$1") ]; then
        printf "$1 is necessary dependency but cant seem to be found on your system.\nPlease install related package and try again\n"
        exit 1
    fi
}

#The main installation function. Expects to receive either "sh" or "exe" to decide about unpacking process
install() {

    #Checking if there are leftovers in our temporary directory. If yes - deleting them
    if [ -f $tempdir/$slug ] || [ -d $tempdir/$slug ] || [ -L $tempdir/$slug ]; then
        echo "Found leftover temporary files, cleaning up"
        $delfunc $tempdir/$slug
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
            echo "Unpacking" $workfile
            $extractor $workfile $tempdir/$slug
            unzip $tempdir/$slug/data.zip data/noarch/* -d $tempdir/$slug
            done

        #moving unpacked native game into $gamedir/$slug
        echo "Moving game files into" $gamedir/$slug "directory"
        cp -a $tempdir/$slug/data/noarch/* $gamedir/$slug #This way (unlike with "mv") it will preserve attributes of files (if they are executable and such) and overwrite files that already exists. Which is what we usually want, coz $gamedir/$slug may contain custom launch script, game's saves and other stuff, created after initial installation - attempts to remove it completely (in case we are updating already installed game) will wipe these out.
        echo "Successfully moved game files into" $gamedir/$slug

    elif [ "$1" == "exe" ]; then
        #unpacking exes with innoextract
        for workfile in "${exes[@]}"; do
            echo "Unpacking" $workfile
            innoextract $workfile -d $tempdir/$slug
            done

        #moving unpacked wine game into $gamedir/$slug
        echo "Moving game files into" $gamedir/$slug "directory"
        cp -a $tempdir/$slug/* $gamedir/$slug
        echo "Successfully moved game files into" $gamedir/$slug

    else
        echo "Thats not how this function works, degenerate"
        exit 1
    fi

    echo "Cleaning up temporary files"
    $delfunc $tempdir/$slug
}


##Script
#Looking for configfile and importing stats from it. If dont exist - using default ones
echo "Looking for configuration file in $configfile"
if [ -f "$configfile" ]; then
    echo "Found configuration file, importing available settings"
    #this isnt really secure way of doing things, since source will basically execute the very script it receives. May need to switch to some sed-based solution later
    source "$configfile"
else
    echo "No config file has been found, using fallback values"
fi

#Checking if provided paths are valid. If no - abort
dircheck $downloads
dircheck $gamedir
dircheck $tempdir

#Checking if $extractor exists on its path
if [ ! -f "$extractor" ]; then
    echo "$extractor leads nowhere or isnt file, abort"
    exit 1
fi

#There are thousand of possible cleanup functions, so there is no way to check if the particular one exists. Lets just assume that user isnt retarded and move to dependency check
depcheck "unzip"
depcheck "innoextract"

#Once all necessary checks are done, printing the values that will be used by script. Using printf coz echo is janky when it comes to printing multiple lines at once
printf "Running $scriptname with following settings:
 - Downloaded games directory: $downloads
 - Installed games directory: $gamedir
 - Temporary files directory: $tempdir
 - Path to gogextract: $extractor
 - Cleanup function: $delfunc \n"

#Checking launch arguments. If none - printing info regarding usage and abort.
if [ -z "$1" ]; then
    echo "Input is empty. Usage:" $scriptname "game-to-unpack"
    exit 1
else
    slug="$1"
    echo "Unpacking the game:" $slug
fi

#Entering $downloads directory
cd $downloads

#Checking if directory named $slug exists in $downloads, which usually means that gogrepo has already downloaded such game
if [ -d $slug ]; then
    echo "Found game with slug" $slug", proceed"
#    cd ./$slug
else
    echo "Couldnt find such game, abort"
    exit 1
fi

#Checking if our $slug directory contain native linux (.sh) or wine's .exe installation files and, if yes - proceed accordingly
shopt -s nullglob #this way we are avoiding inclusion of search command itself into array - so if there are no valid files, it wont trigger false-positive results
shells=(./$slug/*.sh) #removed check for slugs, coz some games (like dont starve) have installer names that dont match game's slug
exes=(./$slug/*.exe)
shopt -u nullglob #unchecking after creation of arrays to avoid unwanted behavior of other commands

#removing patch files from valid executables array, since these arent supported anyway
for x in "${!exes[@]}"; do
    if [[ ${exes[x]} == *patch* ]]; then
        unset 'exes[x]'
    fi
    done

#if lengh of array is not 0 - proceed
if ! [ ${#shells[@]} -eq 0 ]; then
    echo "Found native shell installers, proceed"
    install "sh"
elif ! [ ${#exes[@]} -eq 0 ]; then
    echo "Found exe installers, proceed"
    install "exe"
else
    echo "No valid files has been found, abort"
    exit 1
fi

echo "Done"
exit 0
