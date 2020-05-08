#!/bin/bash

#wip gog games extractor
scriptname=`basename "$0"`

##Script's settings
downloads="." #directory where our downloaded games located. Default - the same as script
extractor="./gogextract.py" #path to gogextract.py. Default - "./gogextract.py"
delfunc="gio trash" #method used to clean garbage. Default - "gio trash"
tempdir="" #directory where temp files will be located. Default - "./temp". If blank - using "./$slug/temp" instead
gamedir="" #directory where game's files will be moved at the end". Default - "./games". If blank - using "./$slug/$slug" instead

##Functions
#checking if temporary variables has been set. If no - using fallback values
optvars_check() {
	if [ -z "$tempdir" ]; then
		echo "tempdir isnt set, using ./$slug/temp for temporary files instead"
		tempdir="./$slug/temp"
	else
		echo "Using $tempdir as tempdir"
	fi

	if [ -z "$gamedir" ]; then
		echo "gamedir isnt set, using ./$slug/$slug for unpacked game files instead"
		gamedir="./$slug/$slug"
	else
		echo "Using $gamedir as gamedir"
	fi
}

#checking if there are files in our temporary directory. If yes - deleting
tempfiles_check() {
	if [ -f $tempdir/$slug ] || [ -d $tempdir/$slug ] || [ -L $tempdir/$slug ]; then
		echo "Found leftover temporary files, cleaning up"
		$delfunc $tempdir/$slug
	fi
}

#unpacking linux (.sh) games into temporary folder
sh_unpack() {
	for workfile in "${gameinstallers[@]}"; do
		echo $workfile
		$extractor $workfile $tempdir/$slug
		unzip $tempdir/$slug/data.zip data/noarch/* -d $tempdir/$slug
		done
}

#unpacking windows (.exe) games into temporary folder
exe_unpack() {
	for workfile in "${gameinstallers[@]}"; do
		echo $workfile
		if ! [ -d $tempdir ]; then #TODO: remake gamedir_check() into dir_check(), so it will be possible to use there (and in sh_unpack too). Just in case that fallback directory's name is already occupied by some file
			mkdir $tempdir
		fi
		innoextract $workfile -d $tempdir/$slug
		done
}

#checking if directory where game files will be moved at the end ($gamedir) exists and is dir. If exists and isnt dir - rename and mkdir, if doesnt exists - mkdir $gamedir
#this needs to be done coz you cant cp into directory that doesnt exist
gamedir_check() {
	if [ -f $gamedir ] || [ -L $gamedir ]; then
		echo $gamedir "exists but isnt directory, renaming"
		x="1"
		while true; do
			x=$((x+1))
			newname=$(echo $gamedir.$x)
			if ! [ -f $newname ] || [ -d $newname ] || [ -L $newname ]; then
				mv $gamedir $newname #I have no idea where $newname will be located in case $gamedir has been pre-set to some variable, needs testing
				echo "Succesfully renamed" $gamedir "file into" $newname
				break
				fi
		done
		mkdir $gamedir
	elif [ -d $gamedir ]; then
		echo "Found" $gamedir "directory, proceed"
	else
		echo "Didnt find" $gamedir "directory, creating"
		mkdir $gamedir
	fi
}

linuxgamefiles_move() {
	echo "Moving game files into" $gamedir "directory"
	cp -a $tempdir/$slug/data/noarch/* $gamedir #This way (unlike with "mv") it will preserve attributes of files (if they are executable and such) and overwrite files that already exists. Which is what we usually want, coz $gamedir may contain custom launch script, game's saves and other stuff, created after initial installation - attempts to remove it completely (in case we are updating already installed game) will wipe these out.
	echo "Successfully moved game files into" $gamedir
}

windowsgamefiles_move() {
	echo "Moving game files into" $gamedir "directory"
	cp -a $tempdir/$slug/* $gamedir #This way (unlike with "mv") it will preserve attributes of files (if they are executable and such) and overwrite files that already exists. Which is what we usually want, coz $gamedir may contain custom launch script, game's saves and other stuff, created after initial installation - attempts to remove it completely (in case we are updating already installed game) will wipe these out.
	echo "Successfully moved game files into" $gamedir
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
	gamedir_check
	gamefiles_move
	cleanup
	echo "Done"
	exit 0
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
#actually, this whole part is dirty as hell. As you can see - most parts repeat themself for linux and windows installations. Sadly, I didnt figure out yet how to do that without copypasted spaghett
linuxinstallers=($(ls ./$slug/*.sh))
windowsinstallers=($(ls ./$slug/*.exe))

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


#TODO: add option to ignore patch_ files during installation of windows games
