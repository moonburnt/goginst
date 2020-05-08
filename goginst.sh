#!/bin/bash

#wip gog games extractor
scriptname=`basename "$0"`

#script's settings
downloads="." #directory where our downloaded games located. Default - the same as script
extractor="./gogextract.py" #path to gogextract.py. Default - "./gogextract.py"
delfunc="gio trash" #method used to clean garbage. Default - "gio trash"
tempdir="" #directory where temp files will be located. Default - "./temp". If blank - using "./$slug/temp" instead
gamedir="" #directory where game's files will be moved at the end". Default - "./games". If blank - using "./$slug/$slug" instead

cd $downloads
if [ -z "$1" ]; then	#"-z" stands for "if null"
	echo "Input is empty. Usage:" $scriptname "game-to-unpack"
	exit 1
else
	slug="$1"
	echo "Unpacking the game:" $slug
fi

if [ -d $slug ]; then
	echo "Found game with slug" $slug", proceed"
#	cd ./$slug
else
	echo "Couldnt find such game, abort"
	exit 1
fi

#checking if our $slug directory contain .sh files that match out $slug mask
#gameinstallers=($(ls ./$slug/$slug*.sh))
gameinstallers=($(ls ./$slug/*.sh)) #removed check for slugs, coz some games (like dont starve) have installer names that dont match game's slug
#if lengh of gameinstallers array is not 0 - proceed
if ! [ ${#gameinstallers[@]} -eq 0 ]; then
	echo "Found linux installers, proceed"
else
	echo "No valid files has been found, abort"
	exit 1
fi

#checking if optional variables has been set
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

#checking if we have uncleaned temporary files
if [ -f $tempdir/$slug ] || [ -d $tempdir/$slug ] || [ -L $tempdir/$slug ]; then
	echo "Found leftover temporary files, cleaning up"
	$delfunc $tempdir/$slug
fi

#unpacking valid .sh files into temporary directory
for workfile in "${gameinstallers[@]}"; do
	echo $workfile
	$extractor $workfile $tempdir/$slug
	unzip $tempdir/$slug/data.zip data/noarch/* -d $tempdir/$slug
	done

#checking if directory named $gamedir exists and is dir. If exists and isnt dir - rename and mkdir, if doesnt exists - mkdir $gamedir
#this needs to be done coz you cant cp into directory that doesnt exist
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

#moving unpacked files into $gamedir
echo "Moving game files into" $gamedir "directory"
#mv $tempdir/$slug/data/noarch/* $gamedir
cp -a $tempdir/$slug/data/noarch/* $gamedir #This way (unlike with "mv") it will preserve attributes of files (if they are executable and such) and overwrite files that already exists. Which is what we usually want, coz $gamedir may contain custom launch script, game's saves and other stuff, created after initial installation - attempts to remove it completely (in case we are updating already installed game) will wipe these out.
echo "Successfully moved game files into" $gamedir

#cleaning up temporary files
echo "Cleaning up temporary files"
$delfunc $tempdir/$slug
echo "Done!"
