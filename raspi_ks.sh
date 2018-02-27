#!/bin/bash

# Command:		sudo ./raspi_ks.sh
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
# TODO:
# Document common errors with solutions: 1 standart, 13 no sudo, 100 no internet.
# Document everything: What it does, the input and the output.

### Variables ###

WHITE='\033[0m'
LCYAN='\033[1;36m'
RED='\033[0;31m'
LGREEN='\033[1;32m'
LOGFILE='/dev/null' # Standart path for undefined log path

### Functions ###

# Start script #

function startscript {
	echo -e ${LCYAN}"Raspberry Kickstart Setup"${WHITE}
	if [ "$EUID" -ne 0 ];then
		printlog ${RED}"Please run as root! (sudo ./raspi_ks.sh)"${WHITE}
		exit 13
	fi
	menu
}

function menu {
	printlog ${LGREEN}"Enter an option (Install/Uninstall/About/Clean/Exit): "${WHITE}
	read uoption
	option $uoption
}

function option {
	case $1 in
		About | about) about;;
		Install | install) installer;;
		Uninstall | uninstall) uninstaller;;
		Clean | clean) cleanup;;
		Exit | exit) exit 0;;
		*) printlog ${RED}"Option not found, please try again..."${WHITE};menu;;
	esac
}

# Installation script #
function installer {
	setlog
	printlog "Starting installation script."
	update
	upgrade
	check libjpeg8-dev
	check libpng12-dev
	check Parsec
	check TeamViewer-Host
	cleanup
	printlog "End of installation script."
	if [ $LOGFILE != '/dev/null' ];then
		printlog "Logfile can be found in $LOGFILE"
	fi
	printlog -e ${LGREEN}"Do you want to return to the main menu? (yes/no)"
	while read uinput; do
	case $uinput in
		Yes | yes | Y | y | ye) menu;;
		No | no | N | n | exit) exit 0;;
		*)printlog ${RED}"Option not found, please try again..."${WHITE};;
	esac
	done
}

# Logfile setter #
function setlog {
	printlog ${LGREEN}"Do you want to log the process?"${WHITE}
	read uinput
	case $uinput in
		Yes | yes | Y | y | ye | Ja | ja | J | j | Affirmative | affirmative)
			printlog ${LGREEN}"Insert the absolute path to the log file: "${WHITE}
			read -p "(Example: /tmp/example.log): " LOGFILE
			printlog "Logfile set in $LOGFILE"
			;;
		No | no | N | n | Nein | nein | Negative | negative)
			printlog ${LCYAN}"Starting $uoption script, no log will be created."${WHITE}
			;;
		*)
			printlog ${RED}"Option not found, please try again..."${WHITE}
			setlog
			;;
	esac
}

# A function to get more information about the script.

function about {
	printlog ${LCYAN}"This Setup script installs the following programs:"
	printlog "	-Raspicast (libjpeg8-dev & libpng12-dev)"
	printlog "	-Parsec"
	printlog "	-TeamViewer Host"
	printlog "You can choose to install or uninstall these programs and you can remove the setup files with clean."
	menu
}

# Uninstall script
function uninstaller {
	setlog
	printlog "Starting uninstallation script."
	uninstall TeamViewer-Host
	status $?
	uninstall Parsec
	status $?
	printlog "Uninstalling dependencies..."
	apt autoremove -y >> $LOGFILE 2>&1
	status $?
	uninstall libjpeg8-dev
	status $?
	uninstall libpng12-dev
	status $?
	printlog "Cleaning up setup files."
	cleanup
	printlog "Uninstallation finished."
	printlog -e ${LGREEN}"Do you want to return to the main menu? (yes/no)"${WHITE}
	while read uinput; do
	case $uinput in
		Yes | yes | Y | y | ye | Ja | ja | J | j | Affirmative | affirmative) menu;;
		No | no | N | n | Nein | nein | Negative | negative | exit ) exit 0;;
		*)	printlog ${RED}"Option not found, please try again..."${WHITE}
	esac
	done
}

# Cleanup
function cleanup {
	printlog "Removing installation files..."
	rm parsec-rpi.deb >> $LOGFILE 2>&1
	rm teamviewer-rpi.deb >> $LOGFILE 2>&1
	apt-get -f install -y >> $LOGFILE 2>&1
	printlog ${LGREEN}"Do you want to return to the main menu? (yes/no)"${WHITE}
	while read uinput; do
	case $uinput in
		Yes | yes | Y | y | ye | Ja | ja | J | j | Affirmative | affirmative) menu;;
		No | no | N | n | Nein | nein | Negative | negative | exit ) exit 0;;
		*) printlog ${RED}"Option not found, please try again..."${WHITE};;
	esac
	done
}

# Other functions

function printlog {
	echo -e $(date "+%d"."%m"."%Y %T"): ${LCYAN} $1 ${WHITE} | tee -a $LOGFILE
}

function check {
	dpkg -s $1 > /dev/null >> $LOGFILE 2>&1
	if [ $? -eq 0 ];then
		printlog $1" is already installed, skipping "$1"..."
	else
		printlog $1" is not installed."
		install_$1
	fi
}

function uninstall {
	dpkg -s $1 > /dev/null >> $LOGFILE 2>&1
	if [ $? -eq 0 ];then
		printlog "Uninstalling "$1"..."
		apt-get purge ${1,,} -y >> $LOGFILE 2>&1
	else
		printlog $1" is not installed. Skipping "$1"..."
	fi
}

	#hf documenting this
function status {
	if [ $1 -ge 1 ];then #Error gefunden
		if [ -z $2 ];then #Normaler error
			errorcode $?
		else #Dependency error
			sudo apt-get upgrade -y >> $LOGFILE 2>&1
			if [ $? -ge 1 ];then
					printlog ${RED}"Dependency error detected, installing dependencies..."${WHITE}
					apt-get update >> $LOGFILE 2>&1
					apt-get -f install -y >> $LOGFILE 2>&1
				else
					errorcode $?
			fi
		fi
	else #Kein error
		printlog "Done."
	fi
}

# Program installations #

# Update
function update {
	printlog "Checking dependencies..."
	apt-get -f install -y >> $LOGFILE 2>&1
	printlog "Starting update..."
	apt-get update >> $LOGFILE 2>&1
	status $?
}

# Upgrade
function upgrade {
	printlog "Starting upgrade..."
	apt-get upgrade -y >> $LOGFILE 2>&1
	status $?
}

# Raspicast
function install_libjpeg8-dev {
	printlog "Installing libjpeg8-dev..."
	apt-get install libjpeg8-dev -y >> $LOGFILE 2>&1
	status $? libjpeg8-dev
	#git clone https://github.com/HaarigerHarald/omxiv >> $LOGFILE 2>&1
}

function install_libpng12-dev {
	printlog "Installing libpng12-dev..."
	apt-get install libpng12-dev -y >> $LOGFILE 2>&1
	status $? libpng12-dev
	#git clone https://github.com/HaarigerHarald/omxiv >> $LOGFILE 2>&1
}

# Parsec
function install_Parsec {
	printlog "Downloading Parsec..."
	wget -nv -a $LOGFILE https://s3.amazonaws.com/parsec-build/package/parsec-linux.deb -O parsec-rpi.deb # For Linux Ubuntu
	#wget -nv -a $LOGFILE https://s3.amazonaws.com/parsec-build/package/parsec-rpi.deb -O parsec-rpi.deb # For RasPi
	status $?
	printlog "Installing Parsec..."
	dpkg -i parsec-rpi.deb >> $LOGFILE 2>&1
	status $? Parsec
}

# TeamViewer
function install_TeamViewer-Host {
	printlog "Downloading TeamViewer..."
	wget -nv -a $LOGFILE https://download.teamviewer.com/download/linux/teamviewer-host_amd64.deb -O teamviewer-rpi.deb # for Linux Ubuntu
	#wget -nv -a $LOGFILE https://download.teamviewer.com/download/linux/teamviewer-host_armhf.deb -O teamviewer-rpi.deb # for RasPi
	printlog "Installing TeamViewer..."
	dpkg -i teamviewer-rpi.deb >> $LOGFILE 2>&1
	status $? TeamViewer-Host
}

function errorcode {
	printlog $(date "+%d"."%m"."%Y %T"): ${RED} "An error has occured. (ERROR CODE: $1)"${WHITE} | tee -a $LOGFILE



	if [ $LOGFILE != '/dev/null' ];then
		printlog "Check the logfile in $LOGFILE or the error code for more information."
	fi
	exit $1
}

startscript
