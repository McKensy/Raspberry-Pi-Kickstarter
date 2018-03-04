#!/bin/bash

###
#
# Command:	sudo ./raspi_ks.sh
#
# Description:	
#	This is a Bash-script or Kickstart-script for my Raspberry Pi.
#	Currently it is configured to work on any Ubuntu 16.04 LTS versions.
#	The script installs the following programs:
#	-Raspicast (Video, Photo and YouTube streaming)
#	-Parsec (Gamestreaming)
#	-Teamviewer (Remote control)
#
#	The options are About, Install, Uninstall, Clean and Exit:
#	About: About is a small description of the current script.
#	Install: Installs all mentioned programs.
#	Uninstall: Uninstall all mentioned programs.
#	Clean: Removes downloaded files and installs any pending dependencies.
#	Exit: Exits the program.
#
# Requirements:
#	-Superuser permissions
#	-Internet connection
# 	-Any Ubuntu 16.04 LTS version
#	-20 Megabytes of space
#
# Author: Jordan Mac Kensy (McKensy)
#
###

### Variables ###

## Text colors ##
WHITE="\\033[0m" # For date, time and the user
LCYAN="\\033[1;36m" # For information to the user
RED="\\033[0;31m" # For errors
LGREEN="\\033[1;32m" # For user input requests

## Path for the logfile ##
LOGFILE="/dev/null" # Standard path for undefined logfile

### Functions ###

## Start script ##

# The startscript function is the first function the script runs.
# Checks if the user ran the script as root and has internet connection.
# After that, it clears the current window and greets the user.

function startscript {
	printlog "${LCYAN}" "Raspberry Kickstart Setup"
	if [ "$EUID" -ne 0 ];then
		printlog "${RED}" "Please run as root! (sudo ./raspi_ks.sh)"
		exit 13
	fi
	wget -nv -a "$LOGFILE" --spider https://google.com
	exitstatus "$?"
	clear
	printlog "${LCYAN}" "Welcome to the Raspberry Kickstart Script"
	menu
}

## Main menu ##
# This is the main menu showed after the first function.
# The user can choose between: About, Install, Uninstall, Clean and Exit.
# Cases doesn't matter aslong the user types the word correctly.
# The user can choose after an installation, uninstallation or cleanup to go back to the menu.

function menu {
	printlog "${LGREEN}" "Enter an option (Install/Uninstall/About/Clean/Exit): "
	read -r uoption
	case $uoption in
		About | about ) about;;
		Install | install ) installer;;
		Uninstall | uninstall ) uninstaller;;
		Clean | clean ) cleanup;;
		Exit | exit ) exit 0;;
		* ) printlog "${RED}" "Option not found, please try again...";menu;;
	esac
}


## Installation script ##

# This is the installation script to install the mentioned programs.
# First, it will ask for a logfile and then continues with updating the system to the newest version.
# After that it will install the programs if they aren't installed yet.
# Followed by a cleanup, which deletes the downloaded files and installs any pending dependencies.
# It will hint the user where to find the $LOGFILE, if the $LOGFILE was set previously.
# At last, it will ask if the user wants to go back to the main menu.

function installer {
	setlog
	printlog "${LCYAN}" "Starting installation script."
	update
	upgrade
	check "libjpeg8-dev"
	check "libpng12-dev"
	check "Parsec"
	check "TeamViewer-Host"
	cleanup
	printlog "${LCYAN}" "End of installation script."
	if [ "$LOGFILE" != "/dev/null" ];then
		printlog "${LCYAN}" "Logfile can be found in $LOGFILE"
	fi
	printlog "${LGREEN}" "Do you want to return to the main menu? (Yes/No)"
	while read -r uinput; do
	case $uinput in
		Yes | yes | Y | y ) menu;;
		No | no | N | n | Exit | exit ) exit 0;;
		* )printlog "${RED}" "Option not found, please try again...";;
	esac
	done
}

## Logfile configurator ##

# The function asks the user if the installation should be logged.
# If the user wants the script to be logged, then it will ask for the location of the file.
# After that, it will log all output of the script to the $LOGFILE.
# Otherwise It will dump all output of stdout & stderr into /dev/null if the user doesn't want a logfile.

function setlog {
	printlog "${LGREEN}" "Do you want to log the process?"
	read -r uinput
	case $uinput in
		Yes | yes | Y | y )
			printlog "${LGREEN}" "Insert the absolute path to the log file: "
			read -rp "(Example: /tmp/example.log): " LOGFILE
			printlog "${LGREEN}" "Is this the correct path? $LOGFILE (Yes/No)"
			read -r uinput
			case $uinput in
				Yes | yes | Y | y )
					printlog "${LCYAN}" "Starting $uoption script, logfile located in $LOGFILE"
					;;
				No | no | N | n | Exit | exit ) 
					rm -f "$LOGFILE"
					LOGFILE="/dev/null"
					setlog
					;;
				* )
					printlog "${RED}" "Option not found, please try again..."
					;;
			esac
			;;
		No | no | N | n )
			printlog "${LCYAN}" "Starting $uoption script, no log will be created."
			;;
		* )
			printlog "${RED}" "Option not found, please try again..."
			setlog
			;;
	esac
}

## About ##

# This is a function to get more information about the script.
# I didn't use "\n" because it is easier to read when editing the script.

function about {
	printlog "${LCYAN}" "This is a Bash-script or Kickstart-script for my Raspberry Pi."
	printlog "${LCYAN}" "The options are About, Install, Uninstall, Clean and Exit\n"
	printlog "${LCYAN}" "It installs the following programs:"
	printlog "${LCYAN}" "	-libjpeg8-dev & libpng12-dev for Raspicast (Video, Photo and YouTube streaming)"
	printlog "${LCYAN}" "	-Parsec (Gamestreaming)"
	printlog "${LCYAN}" "	-Teamviewer (Remote control)\n"
	printlog "${LCYAN}" "You can choose to install or uninstall these programs and you can remove the setup files with clean."
	printlog "${LCYAN}" "The minimum requirements to install these programs:"
	printlog "${LCYAN}" "	-Superuser permissions"
	printlog "${LCYAN}" "	-Internet connection"
 	printlog "${LCYAN}" "	-Any Ubuntu 16.04 LTS version"
	printlog "${LCYAN}" "	-20 Megabytes of diskspace"
	menu
}

## Program installations ##

# Here are the seperate installations for every program.
# The basic idea behind all installations is:
# -Let the user know what is happening with an echo.
# -Install the program if it isn't installed already.
# -Check if there were any problems with $? after the installation.
# Note: If the program is already installed, it won't run the desired function.

# Update
# Checks pending dependencies and checks for updates.

function update {
	printlog "${LCYAN}" "Checking dependencies..."
	apt autoremove -y >> "$LOGFILE" 2>&1
	exitstatus "$?"
	printlog "${LCYAN}" "Starting update..."
	apt-check "update"
	exitstatus "$?"
}

# Upgrade
# Installs any pending updates.

function upgrade {
	printlog "${LCYAN}" "Starting upgrade..."
	apt-check "upgrade"
	exitstatus "$?"
}

# Raspicast
# Installs libjpeg8-dev to display jpeg images.

function install_libjpeg8-dev {
	printlog "${LCYAN}" "Installing libjpeg8-dev..."
	apt-get install libjpeg8-dev -y >> "$LOGFILE" 2>&1
	exitstatus "$?" "libjpeg8-dev"
}

# Installs libpng12-dev to display png images.

function install_libpng12-dev {
	printlog "${LCYAN}" "Installing libpng12-dev..."
	apt-get install libpng12-dev -y >> "$LOGFILE" 2>&1
	exitstatus "$?" "libpng12-dev"
}

# Parsec
# Downloads the latest version of Parsec and installs it if it isn't installed already.

function install_Parsec {
	printlog "${LCYAN}" "Downloading Parsec..."
	wget -nv -a "$LOGFILE" https://s3.amazonaws.com/parsec-build/package/parsec-linux.deb -O parsec-rpi.deb # For Linux Ubuntu
	#wget -nv -a "$LOGFILE" https://s3.amazonaws.com/parsec-build/package/parsec-rpi.deb -O parsec-rpi.deb # For RasPi
	exitstatus "$?"
	printlog "${LCYAN}" "Installing Parsec..."
	dpkg -i parsec-rpi.deb >> "$LOGFILE" 2>&1
	exitstatus "$?" "Parsec"
}

# TeamViewer
# Downloads the latest version of TeamViewer-Host and installs it if it isn't installed already.

function install_TeamViewer-Host {
	printlog "${LCYAN}" "Downloading TeamViewer..."
	wget -nv -a "$LOGFILE" https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb -O teamviewer-rpi.deb # for Linux Ubuntu
	#wget -nv -a "$LOGFILE" https://download.teamviewer.com/download/linux/teamviewer-host_armhf.deb -O teamviewer-rpi.deb # for RasPi
	printlog "${LCYAN}" "Installing TeamViewer..."
	dpkg -i teamviewer-rpi.deb >> "$LOGFILE" 2>&1
	exitstatus "$?" "TeamViewer-Host"
}

## Uninstall script ##

# This is the uninstallation script to uninstall the mentioned programs.
# First, it will ask for a logfile and then it will uninstall the programs if they are installed.
# After that, it will clean the downloaded files and checks any pending dependencies for good measure.
# At last, it will ask if the user wants to go back to the main menu.

function uninstaller {
	setlog
	printlog "${LCYAN}" "Starting uninstallation script."
	uninstall "TeamViewer-Host"
	exitstatus "$?"
	uninstall "Parsec"
	exitstatus "$?"
	printlog "${LCYAN}" "Uninstalling dependencies..."
	apt autoremove -y >> "$LOGFILE" 2>&1
	exitstatus "$?"
	uninstall "libjpeg8-dev"
	exitstatus "$?"
	uninstall "libpng12-dev"
	exitstatus "$?"
	printlog "${LCYAN}" "Cleaning up setup files."
	cleanup
	printlog "${LCYAN}" "Uninstallation finished."
	printlog "${LGREEN}" "Do you want to return to the main menu? (Yes/No)"
	while read -r uinput; do
		case $uinput in
			Yes | yes | Y | y ) menu;;
			No | no | N | n | Exit | exit ) exit 0;;
			* ) printlog "${RED}" "Option not found, please try again...";;
		esac
	done
}

## Cleanup ##

# This is the cleanup function.
# It removes the downloaded files and checks if there are pending dependencies.
# After that, it will ask if the user wants to go back to the main menu.

function cleanup {
	printlog "${LCYAN}" "Removing installation files..."
	{
	rm -f parsec-rpi.deb
	rm -f teamviewer-rpi.deb
	apt autoremove -y
	} >> "$LOGFILE" 2>&1
	printlog "${LGREEN}" "Do you want to return to the main menu? (Yes/No)"
	while read -r uinput; do
		case $uinput in
			Yes | yes | Y | y ) menu;;
			No | no | N | n | Exit | exit ) exit 0;;
			* ) printlog "${RED}" "Option not found, please try again...";;
		esac
	done
}

### Other functions ###

## Message preset for the user ##
# Contains the date and time, color ($1) of the text ($2) and pushes the message to the $LOGFILE

function printlog {
	date="$(date "+%d.%m.%Y %T")" # Sets the current time and date to $date.
	echo -e "$date":"$1" "$2" "${WHITE}" | tee -a "$LOGFILE"
}

## Program checker ##

# $1 is the program name and checks the function with dpkg if $1 is installed.
# If it is not installed, it will output an error with dpkg and calls the required function with 'install_"$1"'.
# Parsec for example: install_Parsec
# If it is installed, dpkg won't output an error and it will skip the installation.

function check {
	if ! dpkg -s "$1" > /dev/null >> "$LOGFILE" 2>&1
	then # dpkg error, $1 is not installed.
		printlog "${LCYAN}" "$1 is not installed."
		install_"$1"		
	else # No dpkg error, $1 is installed.
		printlog "${LCYAN}" "$1 is already installed, skipping $1..."
	fi
}

## Uninstall checker ##

# $1 is the program name and checks the function with dpkg if $1 is installed.
# If it is not installed, it will output an error with dpkg and skips the uninstallation of $1.
# If it is installed, dpkg won't output an error and it will uninstall $1.

function uninstall {
	if ! dpkg -s "$1" > /dev/null >> "$LOGFILE" 2>&1 
	then # dpkg error, $1 is not installed
		printlog "${LCYAN}" "$1 is not installed. Skipping $1..."
	else # No dpkg error, $1 is installed
		printlog "${LCYAN}" "Uninstalling $1..."
		apt-get purge "${1,,}" -y >> "$LOGFILE" 2>&1 # Note: "${1,,}" sets $1 to lowercase because apt-get doesn't like uppercase.
	fi
}

## Error checker ##

# Checks the variable $? after the last command.
# The second variable is optional and checks dependency errors.

function exitstatus {
	if [ "$1" -ge 1 ];then # Error occured
		if [ -z "$2" ];then # No variable in $2; Normal error
			errorcode "$1"
		else # Check dependency error of $2
			apt-get upgrade -y >> "$LOGFILE" 2>&1
			if [ "$?" -ge 1 ];then # Dependency error
					printlog "${LCYAN}" "Installing dependencies..."
					apt-check "update"
					apt-get -f install -y >> "$LOGFILE" 2>&1
				else # Normal error (Not a dependency error)
					errorcode "$1"
			fi
		fi
	else # No Error
		printlog "${LCYAN}" "Done."
	fi
}

## apt-get checker ##

# Checks problems in apt-get commands because apt-get doesn't output normal exitcodes.

function apt-check {
	if { apt-get "$1" -y 2>&1; } | tee -a "$LOGFILE" | grep -q '^[WE]:'; then
		errorcode "apt"
	fi
}

## Error message ##

# $1 is the errorcode and the function explains common errors to the user.
# It will hint the user where to find the $LOGFILE, if the $LOGFILE was set previously.
# At last, it will exit the script with the exitcode.

function errorcode {
	printlog "${RED}" "An error has occured. (ERROR CODE: $1)" 
	case $1 in
		1 ) printlog "${RED}" "Common error, retry the installation.";;
		4 ) printlog "${RED}" "Check your internet connection.";;
		13) printlog "${RED}" "No permission, are you root?";;
		100) printlog "${RED}" "Check your internet connection.";;
		apt ) printlog "${RED}" "Error with apt-get. Check you internet connection and/or try to run the script again."; exit "1";;
		* ) printlog "${RED}" "Other error";;
	esac
	if [ "$LOGFILE" != "/dev/null" ];then
		printlog "${RED}" "Check the logfile in $LOGFILE or the error code for more information."
	fi
	exit "$1"
}

### Here is the first function of the script. ###
startscript
