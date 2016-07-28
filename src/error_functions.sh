#!/bin/bash

########################################################################################################################
########################################################################################################################
##########################################  ERROR FUNCTIONS ############################################################
########################################################################################################################
########################################################################################################################


function generalError {

	# $1 = error's number
	# $2 = wherever element to display error's message
	case $1 in
		-1)
			echo "General error nº$1: the global \"$2\" file doesn't exist or it doesn't have read permissions."
			usage
			exit -1
			;;

		-2)
			echo "General error nº$1: the number of parameters is incorrect."
			usage
			exit -2
			;;

		1)
			echo "General error nº$1 in $2th line: the line doesn't have the correct format."
			exit 1
			;;

		2)
			echo "General error nº$1 in $2th line: the file \"$3\" doesn't exist or it doesn't have read permissions."
			exit 2
			;;

		3)
			echo "General error nº$1 in $2th line: the service is unrecognized."
			exit 3
			;;

		4)
			echo "General error nº$1 in $2th line: can't connect to ip or host."
			exit 4
			;;

		0)
			;;
	esac
}

function mountError {

	# $1 = error's number
	# $2 = wherever element to display error's message
	case $1 in

		1)
			echo "Mount error nº$1 in file \"$2\": mount configuration file doesn't have proper lines."
			exit 1
			;;

		2)
			echo "Mount error nº$1 in file \"$2\": device doesn't exist."
			exit 2
			;;
		3)
			echo "Mount error nº$1 in file \"$2\": mount directory is not empty."
			exit 3
			;;

		4)
			echo "Mount error nº$1 in file \"$2\": mount device doesn't exist."
			exit 4
			;;
	esac
}

function raidError {

		# $1 = error's number
		# $2 = wherever element to display error's message
		case $1 in

			1)
				echo "Raid error nº$1 in file \"$2\": raid configuration file doesn't have proper lines."
				exit 1
				;;

			2)
				echo "Raid error nº$1 in file \"$2\": raid number is not correct."
				exit 2
				;;

			3)
				echo "Raid error nº$1 in file \"$2\": device \"$3\" doesn't exist."
				exit 2
				;;
		esac
}

function lvmError {

		# $1 = error's number
		# $2 = wherever element to display error's message
		case $1 in

			1)
				echo "lvm error nº$1 in file \"$2\": lvm configuration file doesn't have proper lines."
				exit 1
				;;

			2)
				echo "lvm error nº$1 in file \"$2\": device \"$3\" doesn't exist."
				exit 2
				;;

			3)
				echo "lvm error nº$1 in file \"$2\": vol size is bigger than it should be."
				exit 3
				;;
		esac
}

function nisClientError {

	# $1 = error's number
	# $2 = wherever element to display error's message
	case $1 in

		1)
			echo "nis_client error nº$1 in file \"$2\": lvm configuration file doesn't have proper lines."
			exit 1
			;;

		2)
			echo "nis_client error nº$1 in file \"$2\": ip is not correct."
			exit 2
			;;
	esac
}

function nisServerError {

	# $1 = error's number
	# $2 = wherever element to display error's message
	case $1 in

		1)
			echo "nis_server error nº$1 in file \"$2\": nis_server configuration file doesn't have proper lines."
			exit 1
			;;

		2)
			echo "nis_server error nº$1 in file \"$2\": domain is not correct."
			exit 2
			;;
	esac
}

function nfsServerError {

	# $1 = error's number
	# $2,$3 = wherever element to display error's message
	case $1 in

		1)
			echo "nfs_server error nº$1 in file \"$2\": nfs_server configuration file doesn't have proper lines."
			exit 1
			;;

		2)
			echo "nfs_server error nº$1 in file \"$2\": you can't have more than one directory for each line."
			exit 2
			;;
		3)
			echo "nfs_server error nº$1 in file \"$2\": file \"$3\" doesn't exist"
			exit 3
			;;
	esac
}

function nfsClientError {
	# $1 = error's number
	# $2 = wherever element to display error's message
	# $3 = line's number or file
	case $1 in

		1)
			echo "nfs_client error nº$1 in file \"$2\": nfs_client configuration file doesn't have proper lines."
			exit 1
			;;

		2)
			echo "nfs_client error nº$1 in file \"$2\": directory \"$3\" doesn't exist in host machine. It can't be mounted."
			exit 2
			;;
		3)
			echo "nfs_client error nº$1 in file \"$2\": $3th line needs more parameters to end configuration."
			exit 3
			;;
		4)
			echo "nfs_client error nº$1 in file \"$2\": file \"$3\" doesn't exist in local machine. It can't be mounted."
			exit 4
			;;
	esac
}

function backupServerError {

	# $1 = error's number
	# $2 = wherever element to display error's message
	# $3 = directory
	case $1 in

		1)
			echo "backup_server error nº$1 in file \"$2\": backup_server configuration file doesn't have proper lines."
			exit 1
			;;

		2)
			echo "backup_server error nº$1 in file \"$2\": directory \"$3\" doesn't exist in host machine."
			exit 2
			;;
	esac
}

function backupClientError {

	# $1 = error's number
	# $2 = wherever element to display error's message
	# $3 = directory
	case $1 in

		1)
			echo "backup_client error nº$1 in file \"$2\": backup_client configuration file doesn't have proper lines."
			exit 1
			;;

		2)
			echo "backup_client error nº$1 in file \"$2\": directory \"$3\" doesn't exist in local machine."
			exit 2
			;;
		3)
			echo "backup_client error nº$1 in file \"$2\": ip is not correct."
			exit 3
			;;
		4)
			echo "backup_client error nº$1 in file \"$2\": backup directory \"$3\" doesn't exist."
			exit 3
			;;
		5)
			echo "backup_client error nº$1 in file \"$2\": backup directory isn't empty."
			exit 4
			;;
	esac
}