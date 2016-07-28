#!/bin/bash

########################################################################################################################
########################################################################################################################
##########################################  USEFUL FUNCTIONS ###########################################################
########################################################################################################################
########################################################################################################################

function checkInstalledPackage {
	# $1: name of the package
	ssh $USER_SSH@$1  dpkg -s $2 > /dev/null
	result=$?

	if [[ "$result" -eq 0 ]] ;then
		echo 0
	elif [[ "$result" -ge 1 ]];then
		echo 1
	fi
}

function checkDirEmpty {
	# $1: name of the directory
	result=$?
	if [ "$(ssh $USER_SSH@$2 ls -A $1)" ] ;then
		echo 1
	else
		echo 0
	fi
}

function logRunningService {
	# $1: name of the service
	echo -e " *Running service: \"$1\":"
}

function logEndingService {
	# $1: name of the service
	echo -e " *Service \"$1\" ended!\n"
}

function logCheckPackage {
	# $1: name of the package
	echo -e "\t*Checking installed package:\"$1\" ... "
}

function logAlreadyInstalled {
	echo -e "\t*Package already installed!"
}

function logInstallingPackage {
	# $1: name of the package
	echo -e "\t*Installing package:\"$1\" ... "
}

function logInstalledPackage {
	echo -e "\t*Package successfully installed!"
}

function passedFilters {
	echo -e "\t*The configuration file \"$1\" has passed all filters"
}

function checkGlobalFile {
	if [[ -r $1 ]] ;then
		echo 0
	else
		echo -1
	fi
}

function checkParameters {
	if [[ "$N_PARAM" -eq 1 ]] ;then
		echo 0
	else
		echo -2
	fi
}

function usage {
	echo -e "\nusage: $0 fichero_configuración"
	exit -1
}

function valid_ip() {
	local  ip=$1
	local  stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
			&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi

	echo $stat
}

function prepareSSH {
	SERVER=$1
	DIRECTORIO="$HOME/.ssh/id_rsa"
	if ! [ -f "$DIRECTORIO" ]; then
		ssh-keygen -q -f "$DIRECTORIO" -N $PASSPHRASE >/dev/null
	fi
	ssh-copy-id $USER_SSH@$SERVER
	eval `ssh-agent`
	ssh-add
}

