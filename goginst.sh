#!/bin/bash

#wip gog games extractor
scriptname=`basename "$0"`

##Script's settings
downloads="." #directory where our downloaded games located. Default - "." (the same as script)
extractor="./gogextract.py" #path to gogextract.py. Default - "./gogextract.py"
delfunc="gio trash" #method used to clean garbage. Default - "gio trash"
tempdir="" #directory where temp files will be located. If blank - using "./goginst/temp" instead
gamedir="" #directory where game's files will be moved at the end". If blank - using "./goginst/Games" instead

##Functions
#checking if temporary variables has been set. If no - using fallback values
optvars_check() {
	if [ -z "$tempdir" ]; then
		echo "tempdir isnt set, using ./goginst/temp for temporary files instead"
		tempdir="./goginst/temp"
	else
		echo "Using $tempdir as tempdir"
	fi

	if [ -z "$gamedir" ]; then
		echo "gamedir isnt set, using ./goginst/Games for unpacked game files instead"
		gamedir="./goginst/Games"
	else
		echo "Using $gamedir as gamedir"
	fi
}

#checking if there are files in our temporary directory. If yes - deleting
tempfiles_check() {
	dir_check $tempdir
	if [ -f $tempdir/$slug ] || [ -d $tempdir/$slug ] || [ -L $tempdir/$slug ]; then
		echo "Found leftover temporary files, cleaning up"
		$delfunc $tempdir/$slug
	fi
}

#unpacking linux (.sh) games into temporary folder
sh_unpack() {
	for workfile in "${gameinstallers[@]}"; do
		echo "unpacking" $workfile
		$extractor $workfile $tempdir/$slug
		unzip $tempdir/$slug/data.zip data/noarch/* -d $tempdir/$slug
		done
}

#unpacking windows (.exe) games into temporary folder
exe_unpack() {
	for workfile in "${gameinstallers[@]}"; do
		echo "unpacking" $workfile
		innoextract $workfile -d $tempdir/$slug
		done
}

#checking if directory exists and is dir. If exists and isnt dir - rename and mkdir, if doesnt exists - mkdir $gamedir
#this needs to be done coz you cant cp into directory that doesnt exist
dir_check() {
	if [ -f $1 ] || [ -L $1 ]; then
		echo $1 "exists but isnt directory, renaming"
		x="1"
		while true; do
			x=$((x+1))
			newname=$(echo $1.$x)
			if ! [ -f $newname ] || [ -d $newname ] || [ -L $newname ]; then
				mv $1 $newname #I have no idea where $newname will be located in case $gamedir has been pre-set to some variable, needs testing
				echo "Succesfully renamed" $1 "file into" $newname
				break
				fi
		done
		mkdir $1
	elif [ -d $1 ]; then
		echo "Found" $1 "directory, proceed"
	else
		echo "Didnt find" $1 "directory, creating"
		mkdir $1
	fi
}

linuxgamefiles_move() {
	echo "Moving game files into" $gamedir/$slug "directory"
	dir_check $gamedir/$slug
	cp -a $tempdir/$slug/data/noarch/* $gamedir/$slug #This way (unlike with "mv") it will preserve attributes of files (if they are executable and such) and overwrite files that already exists. Which is what we usually want, coz $gamedir/$slug may contain custom launch script, game's saves and other stuff, created after initial installation - attempts to remove it completely (in case we are updating already installed game) will wipe these out.
	echo "Successfully moved game files into" $gamedir/$slug
}

windowsgamefiles_move() {
	echo "Moving game files into" $gamedir/$slug "directory"
	dir_check $gamedir/$slug
	cp -a $tempdir/$slug/* $gamedir/$slug
	echo "Successfully moved game files into" $gamedir/$slug
}

cleanup() {
	echo "Cleaning up temporary files"
	$delfunc $tempdir/$slug
}

installation() {
	if [ $1 == "linux" ]; then
#		echo "linux"
		gameinstallers=${linuxinstallers[@]}
		gamefiles_unpack() {
			sh_unpack
		}
		gamefiles_move () {
			linuxgamefiles_move
		}
	elif [ $1 == "windows" ]; then
#		echo "windows"
		gameinstallers=${windowsinstallers[@]}
		gamefiles_unpack() {
			exe_unpack
		}
		gamefiles_move() {
			windowsgamefiles_move
		}
	else
		echo "thats not how this function works, degenerate"
		exit 1
	fi

	optvars_check
	tempfiles_check
	gamefiles_unpack
	dir_check $gamedir
	gamefiles_move
	cleanup
	echo "Done"
}

##Script
#Entering $downloads directory
cd $downloads

#Checking if input is empty
if [ -z "$1" ]; then	#"-z" stands for "if null"
	echo "Input is empty. Usage:" $scriptname "game-to-unpack"
	exit 1
else
	slug="$1"
	echo "Unpacking the game:" $slug
fi

#Checking if directory named $slug exists
if [ -d $slug ]; then
	echo "Found game with slug" $slug", proceed"
#	cd ./$slug
else
	echo "Couldnt find such game, abort"
	exit 1
fi

#Checking if our $slug directory contain linux or windows executables and, if yes - proceed accordingly
shopt -s nullglob #this way we are avoiding inclusion of search command itself into array - so if there are no valid files, it wont trigger false-positive results
linuxinstallers=(./$slug/*.sh) #removed check for slugs, coz some games (like dont starve) have installer names that dont match game's slug
windowsinstallers=(./$slug/*.exe)
shopt -u nullglob #unchecking after creation of arrays to avoid unwanted behavior of other commands

#removing patch files from valid executables array, since these arent supported anyway
for x in "${!windowsinstallers[@]}"; do
	if [[ ${windowsinstallers[x]} == *patch* ]]; then
		unset 'windowsinstallers[x]'
	fi
	done

#if lengh of array is not 0 - proceed
if ! [ ${#linuxinstallers[@]} -eq 0 ]; then
	echo "Found linux installers, proceed"
	installation linux
elif ! [ ${#windowsinstallers[@]} -eq 0 ]; then
	echo "Found windows installers, proceed"
	installation windows
else
	echo "No valid files has been found"
	exit 1
fi

exit 0
