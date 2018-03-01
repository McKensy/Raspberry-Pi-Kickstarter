#!/bin/bash

# Command:	sudo ./raspi_ks.sh
#
# Description:	A Kickstart-script for my Raspberry Pi
#				The script installs the following programs:
#				-Raspicast (Video, Photo and YouTube streaming)
#				-Parsec (Gamestreaming)
#				-Teamviewer (Remote control)
# Requirements:
#				-Internet connection
# 				-Any Ubuntu 16.04 LTS version
#

### Variables ###

# Text colors
WHITE='\033[0m' # For date, time and the user
LCYAN='\033[1;36m' # For information to the user
RED='\033[0;31m' # For errors
LGREEN='\033[1;32m'	# For user input requests

# Path for the logfile
LOGFILE='/dev/null' # Standard path for undefined logfile

### Functions ###

# Start script #

# First function and checks if the user ran the script as root.
function startscript {
	printlog "${LCYAN}" "Raspberry Kickstart Setup"
	if [ "$EUID" -ne 0 ];then
		printlog "${RED}" "Please run as root! (sudo ./raspi_ks.sh)"
		exit 13
	fi
	menu
}

# Main menu to choose all options.
function menu {
	printlog "${LGREEN}" "Enter an option (Install/Uninstall/About/Clean/Exit): "
	read -r uoption
	option "$uoption"
}

function option {
	case $1 in
		About | about ) about;;
		Install | install ) installer;;
		Uninstall | uninstall ) uninstaller;;
		Clean | clean ) cleanup;;
		Exit | exit ) exit 0;;
		* ) printlog "${RED}" "Option not found, please try again...";menu;;
	esac
}

### Installation script ###

function installer {
	setlog
	printlog "${LCYAN}" "Starting installation script."
	update
	upgrade
	check libjpeg8-dev
	check libpng12-dev
	check Parsec
	check TeamViewer-Host
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

### Logfile configurator ###

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
					printlog "Starting $uoption script, logfile located in $LOGFILE"
					;;
				No | no | N | n | Exit | exit ) 
					rm "$LOGFILE" -f
					LOGFILE='/dev/null'
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

### A function to get more information about the script. ###

function about {
	printlog "${LCYAN}" "This Setup script installs the following programs:"
	printlog "${LCYAN}" "	-Raspicast (libjpeg8-dev & libpng12-dev)"
	printlog "${LCYAN}" "	-Parsec"
	printlog "${LCYAN}" "	-TeamViewer Host"
	printlog "${LCYAN}" "You can choose to install or uninstall these programs and you can remove the setup files with clean."
	menu
}

### Uninstall script ###
function uninstaller {
	setlog
	printlog "${LCYAN}" "Starting uninstallation script."
	uninstall TeamViewer-Host
	exitstatus $?
	uninstall Parsec
	exitstatus $?
	printlog "${LCYAN}" "Uninstalling dependencies..."
	apt autoremove -y >> "$LOGFILE" 2>&1
	exitstatus $?
	uninstall libjpeg8-dev
	exitstatus $?
	uninstall libpng12-dev
	exitstatus $?
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

### Cleanup ###
function cleanup {
	printlog "${LCYAN}" "Removing installation files..."
	{
	rm parsec-rpi.deb
	rm teamviewer-rpi.deb
	apt-get -f install -y
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

# Message preset for the user
# Contains the date and time, color of the text and pushes the message to the $LOGFILE
function printlog {
	date="$(date "+%d.%m.%Y %T")"
	echo -e "$date":"$1" "$2" "${WHITE}" | tee -a "$LOGFILE"
}

# Checks if $1 is installed
# $1 is the program name
function check {
	if ! dpkg -s "$1" > /dev/null >> "$LOGFILE" 2>&1 # Checks with dpkg if the program is installed
	then # dpkg error, $1 is not installed.
		printlog "${LCYAN}" "$1 is not installed."
		install_"$1"		
	else # No dpkg error, $1 is installed.
		printlog "${LCYAN}" "$1 is already installed, skipping $1..."
	fi
}

# Checks if $1 is installed
# $1 is the program name
function uninstall {
	if ! dpkg -s "$1" > /dev/null >> "$LOGFILE" 2>&1 # Checks with dpkg if the program is installed
	then # dpkg error, $1 is not installed
		printlog "${LCYAN}" "$1 is not installed. Skipping $1..."
	else # No dpkg error, $1 is installed
		printlog "${LCYAN}" "Uninstalling $1..."
		apt-get purge "${1,,}" -y >> "$LOGFILE" 2>&1
	fi
}

# Error checker
# Checks the variable $? after the last command.
# The second variable is optional and checks dependency errors.
function exitstatus {
	if [ "$1" -ge 1 ];then # Error occured
		if [ -z "$2" ];then # No variable in $2; Normal error
			errorcode "$1"
		else # Check dependency error of $2
			apt-get upgrade -y >> "$LOGFILE" 2>&1
			if [ "$?" -ge 1 ];then # Dependency error
					printlog "${RED}" "Dependency error detected!"
					printlog "${LCYAN}" "Installing dependencies..."
					apt-get update >> "$LOGFILE" 2>&1
					apt-get -f install -y >> "$LOGFILE" 2>&1
				else # Normal error (Not a dependency error)
					errorcode "$1"
			fi
		fi
	else # No Error
		printlog "${LCYAN}" "Done."
	fi
}

# Program installations #

# Update
function update {
	printlog "${LCYAN}" "Checking dependencies..."
	apt-get -f install -y >> "$LOGFILE" 2>&1
	exitstatus $?
	printlog "${LCYAN}" "Starting update..."
	apt-get update >> "$LOGFILE" 2>&1
	exitstatus $?
}

# Upgrade
function upgrade {
	printlog "${LCYAN}" "Starting upgrade..."
	apt-get upgrade -y >> "$LOGFILE" 2>&1
	exitstatus $?
}

# Raspicast
function install_libjpeg8-dev {
	printlog "${LCYAN}" "Installing libjpeg8-dev..."
	apt-get install libjpeg8-dev -y >> "$LOGFILE" 2>&1
	exitstatus $? libjpeg8-dev
	#git clone https://github.com/HaarigerHarald/omxiv >> "$LOGFILE" 2>&1
}

function install_libpng12-dev {
	printlog "${LCYAN}" "Installing libpng12-dev..."
	apt-get install libpng12-dev -y >> "$LOGFILE" 2>&1
	exitstatus $? libpng12-dev
	#git clone https://github.com/HaarigerHarald/omxiv >> "$LOGFILE" 2>&1
}

# Parsec
function install_Parsec {
	printlog "${LCYAN}" "Downloading Parsec..."
	wget -nv -a "$LOGFILE" https://s3.amazonaws.com/parsec-build/package/parsec-linux.deb -O parsec-rpi.deb # For Linux Ubuntu
	#wget -nv -a "$LOGFILE" https://s3.amazonaws.com/parsec-build/package/parsec-rpi.deb -O parsec-rpi.deb # For RasPi
	exitstatus $?
	printlog "${LCYAN}" "Installing Parsec..."
	dpkg -i parsec-rpi.deb >> "$LOGFILE" 2>&1
	exitstatus $? Parsec
}

# TeamViewer
function install_TeamViewer-Host {
	printlog "${LCYAN}" "Downloading TeamViewer..."
	wget -nv -a "$LOGFILE" https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb -O teamviewer-rpi.deb # for Linux Ubuntu
	#wget -nv -a "$LOGFILE" https://download.teamviewer.com/download/linux/teamviewer-host_armhf.deb -O teamviewer-rpi.deb # for RasPi
	printlog "${LCYAN}" "Installing TeamViewer..."
	dpkg -i teamviewer-rpi.deb >> "$LOGFILE" 2>&1
	exitstatus $? TeamViewer-Host
}

# Error message
# Input: the error code
function errorcode {
	printlog "${RED}" "An error has occured. (ERROR CODE: $1)" 
	case $1 in
		1 ) printlog "${RED}" "Common error, retry the installation.";;
		4 ) printlog "${RED}" "Check your internet connection.";;
		13) printlog "${RED}" "No permission, are you root?";;
		100) printlog "${RED}" "Check your internet connection.";;
		* ) printlog "${RED}" "Other error";;
	esac
	if [ "$LOGFILE" != '/dev/null' ];then
		printlog "${RED}" "Check the logfile in $LOGFILE or the error code for more information."
	fi
	exit "$1"
}

startscript
