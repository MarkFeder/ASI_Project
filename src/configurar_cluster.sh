#!/bin/bash


# Some global variables
FILE_CONF=$1
N_PARAM=$#
NERRORS=0
SERVICES=(mount raid lvm nis_server nis_client nfs_server nfs_client backup_server backup_client)
SERVICESCPY=()
USER_SSH="root" # it would be root

# load other scripts
source useful_functions.sh
source error_functions.sh


########################################################################################################################
########################################################################################################################
########################################## CONFIGURATION FILE CHECKING #################################################
########################################################################################################################
########################################################################################################################


function checkConfFile {

	# $1 = machine
	# $2 = service
	# $3 = configuration file name
	case $2 in

		"mount")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -eq 2 ]] ;then
				mountError 1 $3
			fi

			# check conf file
			currLine=1
			while IFS='' read -r line || [[ -n "$line" ]] ;do

				arr=($(echo $line | cut -d ' ' -f 1))

				arrlen=${#arr[@]}

				# check if mount device exists
				if [[ "$currLine" -eq 1 ]] ;then
					ssh $USER_SSH@$1 test -b ${arr[0]} >/dev/null
					result=$?

					# if it doesn't exist, display error
					if ! [[ "$result" -eq 0 ]] ;then
						mountError 4 $3
					fi
				fi


				# we don't know why, but the loop stops at second step, so
				# we needed to make this fix in order to check dir

				local dir=$(sed '2q;d' $3 | cut -d ' ' -f 1)

				ssh $USER_SSH@$1 test -d $dir >/dev/null  #${arr[0]}
				result=$?

				# if it doesn't exist, make the directory
				if ! [[ "$result" -eq 0 ]] ;then
						ssh $USER_SSH@$1  mkdir $dir >/dev/null #${arr[0]}
				# if it exists, check if it's empty
				elif [[ "$result" -eq 0 ]] ;then
					result=$(checkDirEmpty $dir $1)
					if ! [[ "$result" -eq 0 ]] ;then
						mountError 3 $3
					fi
				fi

			# next line
			currLine=$(($currLine + 1))
			done < "$3"

			passedFilters $3

			;;

		"raid")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -eq 3 ]] ;then
				raidError 1 $3
			fi

			# check conf file
			for ((i=1; i<=${nlines}; i++)) ;do

				# fix: -f 1-10
				arr=($(sed ''$i'q;d' $3 | cut -d ' ' -f 1-10))
				arrlen=${#arr[@]}

				# check raid number
				if [[ "$i" -eq 2 ]] ;then

					if [[ "${arr[0]}" -lt 0 ]] || [[ "${arr[0]}" -gt 7 ]] ;then
						raidError 2 $3
					fi
				# check devices
				elif [[ "$i" -eq 3 ]] ;then

					# check for each device
					for ((j=0; j<=${arrlen}; j++)) ;do
						ssh $USER_SSH@$1 test -b ${arr[$j]} >/dev/null
						result=$?

						# if it doesn't exist, display error
						if ! [[ "$result" -eq 0 ]] ;then
							raidError 3 $3 ${arr[$j]}
						fi
					done
				fi

			done

			passedFilters $3

			;;

		"lvm")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -ge 2 ]] ;then
				nisClientError 1 $3
			fi

			# check conf file
			for ((i=1; i<=${nlines}; i++)) ;do

				# fix: -f 1-10
				arr=($(sed ''$i'q;d' $3 | cut -d ' ' -f 1-10))
				arrlen=${#arr[@]}

				if [[ "$i" -eq 2 ]] ;then
					# check for each device
					for ((j=0; j<${arrlen}; j++)) ;do
						ssh $USER_SSH@$1 test -b ${arr[$j]} >/dev/null
						result=$?

						# if it doesn't exist, display error
						if ! [[ "$result" -eq 0 ]] ;then
							lvmError 2 $3 ${arr[$j]}
						fi
					done
				fi
			done

			passedFilters $3

			;;

		"nis_server")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -eq 1 ]] ;then
				nisServerError 1 $3
			fi

			# get domain name
			line=$(head -n 1 $3)

			# check domain name
			if ! [[ $line =~ ^[A-Za-z0-9]+$ ]] ;then
				nisServerError 2 $3
			fi

			passedFilters $3

			;;

		"nis_client")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -eq 2 ]] ;then
				nisClientError 1 $3
			fi

			# check conf file
			for ((i=1; i<=${nlines}; i++)) ;do

				arr=($(sed ''$i'q;d' $3 | cut -d ' ' -f 1))
				arrlen=${#arr[@]}

				# check if host is a valid_ip
				if [[ "$i" -eq 2 ]] ;then
					result=$(valid_ip ${arr[0]})

					if ! [[ "$result" -eq 0 ]] ;then
						nisClientError 2 $3
					fi
				fi

			done

			passedFilters $3

			;;

		"nfs_server")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -ge 1 ]] ;then
				nfsServerError 1 $3
			fi

			# TODO: ERROR 2
			# check conf file
			for ((i=1; i<=${nlines}; i++)) ;do
				dir=$(sed ''$i'q;d' $3 | cut -d ' ' -f 1)

				ssh $USER_SSH@$1 test -d $dir >/dev/null
				result=$?

				# if it doesn't exist, display error
				if ! [[ "$result" -eq 0 ]] ;then
					nfsServerError 3 $3 $line
				fi
			done

			passedFilters $3

			;;

		"nfs_client")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -ge 1 ]] ;then
				nfsClientError 1 $3
			fi

			# TODO : CHECK HOST NAME/IP ??
			# check conf file
			currLine=1
			for ((i=1; i<=${nlines}; i++)) ;do

				# fix: -f 1-10
				arr=($(sed ''$i'q;d' $3 | cut -d ' ' -f 1-10))
				arrlen=${#arr[@]}

				if ! [[ "$arrlen" -eq 3 ]] ;then
					nfsClientError 3 $3 $currLine
				fi

				# check if remote directory exists
				ssh $USER_SSH@${arr[0]} test -d ${arr[1]} >/dev/null
				result=$?

				# if it doesn't exist, display error
				if ! [[ "$result" -eq 0 ]] ;then
					nfsClientError 2 $3 ${arr[1]}
				fi

				# check if local directory exists
				ssh $USER_SSH@$1 test -d ${arr[2]} >/dev/null
				result=$?

				# if it doesn't exist, display error
				if ! [[ "$result" -eq 0 ]] ;then
					nfsClientError 4 $3 ${arr[2]}
				fi

			# next line
			currLine=$(($currLine + 1))
			done

			passedFilters $3

			;;

		"backup_server")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -eq 1 ]] ;then
				backupServerError 1 $3
			fi

			line=$(head -1 $3)
			ssh $USER_SSH@$1 test -d $line >/dev/null
			result=$?

			# if it doesn't exist, display error
			if ! [[ "$result" -eq 0 ]] ;then
				backupServerError 2 $3 $line
			fi

			passedFilters $3

			;;

		"backup_client")
			nlines=$(wc -l < $3)

			# check lines in file
			if ! [[ "$nlines" -eq 4 ]] ;then
				backupClientError 1 $3
			fi

			# fix for getting the 2nd line: useful for checking remote dir
			backup_host=$(sed '2q;d' $3)

			# check conf file
			currLine=1
			for ((i=1; i<=${nlines}; i++)) ;do

				arr=($(sed ''$i'q;d' $3 | cut -d ' ' -f 1))
				arrlen=${#arr[@]}

				# check dir to be backed up
				if [[ "$currLine" -eq 1 ]] ;then
					test -d ${arr[0]}
					result=$?
					if ! [[ "$result" -eq 0 ]]; then
						backupClientError 2 $3 ${arr[0]}
					fi
				elif [[ "$currLine" -eq 2 ]] ;then
					result=$(valid_ip ${arr[0]})

					if ! [[ "$result" -eq 0 ]] ;then
						backupClientError 3 $3
					fi
				# check remote dir where backup will be allocated
				elif [[ "$currLine" -eq 3 ]] ;then
					ssh $USER_SSH@$backup_host test -d ${arr[0]} >/dev/null
					result=$?

					if ! [[ "$result" -eq 0 ]] ;then
						backupClientError 4 $3 ${arr[0]}
					# if remote dir exits, check if it's empty
					elif [[ "$result" -eq 0 ]] ;then
						result=$(checkDirEmpty ${arr[0]} $backup_host)
						if ! [[ "$result" -eq 0 ]] ;then
							backupClientError 5 $3
						fi
					fi
				fi

			# next line
			currLine=$(($currLine + 1))
			done

			passedFilters $3

			;;

		*)
			usage
			;;

		esac
}


########################################################################################################################
########################################################################################################################
##########################################  MAIN POINT #################################################################
########################################################################################################################
########################################################################################################################

echo -e "** Start filtering $1 ... \n"

# First, check parameters
result=$(checkParameters)
generalError $result


# Second, check if file exists
result=$(checkGlobalFile $FILE_CONF)
generalError $result $FILE_CONF


# Third, start checking files' format
numberOflines=$(wc -l < $FILE_CONF)
for ((j=1; j<=${numberOflines}; j++)) ;do

	# Read each line
	arr=($(sed ''$j'q;d' $FILE_CONF | cut -d ' ' -f 1-4))

	# Get number of elements for each line
	arrlen=${#arr[@]}

	# check if first elem is '#' or empty space
	if [ "${arr[0]}" == "#" ] || [ "${arr[0]}" == "" ] ;then
		continue

	# check if number of elements is > 4
	elif [[ "$arrlen" -ge 4 ]] || [[ "$arrlen" -lt 3 ]] ;then
		generalError 1 $currLine

	else
		# make copy first
		SERVICESCPY=(${SERVICES[@]})
		# remove element if is encountered
		SERVICESRM=(${SERVICESCPY[@]#${arr[1]}})

		# check if service is recognized
		if [[ ${#SERVICESRM[@]} -eq ${#SERVICES[@]} ]] ;then
			generalError 3 $currLine
		fi

		# check if configuration file exits
		if ! [[ -r ${arr[2]} ]] ;then
			generalError 2 $currLine ${arr[2]}
		fi

		# check configuration file itself
		checkConfFile ${arr[0]} ${arr[1]} ${arr[2]} $currLine
	fi
done

echo -e "\n** All filters have been passed ... "
echo -e "\n** Start running services ... \n"


# Fourth, start running services ...
currLine=1
numberOflines=$(wc -l < $FILE_CONF)
for ((i=1; i<=${numberOflines}; i++)) ;do

	# Read each line
	arr=($(sed ''$i'q;d' $FILE_CONF | cut -d ' ' -f 1-4))
	# Get number of elements for each line
	arrlen=${#arr[@]}

	# Run each service
	# Ip/host: ${arr[0]}
	# Service: ${arr[1]}
	# Configuration file: ${arr[2]}

	IP_HOST=${arr[0]}
	SERVICE=${arr[1]}
	FILE=${arr[2]}

	case $SERVICE in

			"mount")
				logRunningService $SERVICE

				logCheckPackage $SERVICE
				if [[ "$(checkInstalledPackage $IP_HOST $SERVICE)" -eq 1 ]] ;then
					logInstallingPackage $SERVICE
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get install $SERVICE > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				DEVICE=`sed '1q;d' $FILE`
				POINTMOUNT=`sed '2q;d' $FILE`
				FORMATO=`ssh $USER_SSH@$IP_HOST  lsblk -no FSTYPE $DEVICE`

				# check if /etc/fstab contains this drive
				ssh $USER_SSH@$IP_HOST  grep -Fx \"$DEVICE $POINTMOUNT $FORMATO defaults 0 0\" /etc/fstab >/dev/null
				result=$?

				if [[ "$result" -ge 1 ]]; then

					ssh $USER_SSH@$IP_HOST  mount -t $FORMATO $DEVICE $POINTMOUNT >/dev/null
					# copy line to /etc/fstab to persistent
					ssh $USER_SSH@$IP_HOST " su -c \"echo '$DEVICE $POINTMOUNT $FORMATO defaults 0 0' >>/etc/fstab\"" >/dev/null
				fi

				logEndingService $SERVICE
				;;

			"raid")
				logRunningService $SERVICE

				logCheckPackage mdadm
				if [[ "$(checkInstalledPackage $IP_HOST mdadm)" -eq 1 ]] ;then
					# silent installation with default configuration
					logInstallingPackage mdadm
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get -q -y install mdadm > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				# perform service
				ssh $USER_SSH@$IP_HOST "echo yes |  mdadm --create `sed '1q;d' $FILE` --level=`sed '2q;d' $FILE` --raid-devices=`awk '{print NF}' $FILE | tail -n 1` `sed '3q;d' $FILE`" >/dev/null

				logEndingService $SERVICE
				;;

			"lvm")
				logRunningService $SERVICE

				logCheckPackage lvm
				if [[ "$(checkInstalledPackage $IP_HOST lvm2)" -eq 1 ]] ;then
					logInstallingPackage mdadm
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get install lvm2 >/dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				group=`sed '1q;d' $FILE`
				nlines=$(wc -l < $FILE)

				# init physics volumes
				ssh $USER_SSH@$IP_HOST  pvcreate `sed '2q;d' $FILE` >/dev/null

				# create group
				ssh $USER_SSH@$IP_HOST  vgcreate $group `sed '2q;d' $FILE` >/dev/null

				# create logic volumes
				for ((i=3; i<=${nlines}; i++)) ;do
					ssh $USER_SSH@$IP_HOST  lvcreate --name $(sed ''$i'q;d' $FILE | cut -d ' ' -f 1) --size $(sed ''$i'q;d' $FILE | cut -d ' ' -f 2) $group >/dev/null
					result=$?

					if ! [[ "$result" -eq 0 ]] ;then
						lvmError 3 $FILE
					fi
				done

				logEndingService $SERVICE
				;;

			"nis_server")
				logRunningService $SERVICE

				logCheckPackage nis
				if [[ "$(checkInstalledPackage $IP_HOST nis)" -eq 1 ]] ;then
					# silent installation with default configuration
					logInstallingPackage nis
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get -q -y install nis > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				# set up nis server
				nisdomainname=$(sed '1q;d' $FILE)
				currentdomainname=$(ssh $USER_SSH@$IP_HOST head -n 1 /etc/defaultdomain) >/dev/null

				# change nis domain name
				ssh $USER_SSH@$IP_HOST  nisdomainname $nisdomainname >/dev/null
				ssh $USER_SSH@$IP_HOST  sed -i s/"$currentdomainname"/"$nisdomainname"/g /etc/defaultdomain >/dev/null

				# change conf parameters
				ssh $USER_SSH@$IP_HOST  sed -i 's/$(grep NISSERVER < /etc/default/nis)/NISSERVER=master/g' /etc/default/nis >/dev/null
				ssh $USER_SSH@$IP_HOST  sed -i 's/$(grep NISCLIENT < /etc/default/nis)/NISCLIENT=false/g' /etc/default/nis >/dev/null

				# restart service
				ssh $USER_SSH@$IP_HOST  service nis restart >/dev/null

				# update database
				ssh $USER_SSH@$IP_HOST  make -C /var/yp >/dev/null

				logEndingService $SERVICE
				;;

			"nis_client")
				logRunningService $SERVICE

				logCheckPackage nis
				if [[ "$(checkInstalledPackage $IP_HOST nis)" -eq 1 ]] ;then
					# silent installation with default configuration
					logInstallingPackage nis
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get -q -y install nis > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				# set up nis client
				nisdomainname=$(sed '1q;d' $FILE)
				nishost=$(sed '2q;d' $FILE)
				currentdomainname=$(ssh $USER_SSH@$IP_HOST head -n 1 /etc/defaultdomain) >/dev/null

				# change nis domain name
				ssh $USER_SSH@$IP_HOST  nisdomainname $nisdomainname >/dev/null
				ssh $USER_SSH@$IP_HOST  sed -i s/"$currentdomainname"/"$nisdomainname"/g /etc/defaultdomain >/dev/null

				# change conf parameters
				ssh $USER_SSH@$IP_HOST  sed -i 's/$(grep NISSERVER < /etc/default/nis)/NISSERVER=false/g' /etc/default/nis >/dev/null
				ssh $USER_SSH@$IP_HOST  sed -i 's/$(grep NISCLIENT < /etc/default/nis)/NISCLIENT=true/g' /etc/default/nis >/dev/null

				# add nis server to /etc/yp.conf
				ssh $USER_SSH@$IP_HOST "echo ypserver $nishost >> /etc/yp.conf" >/dev/null

				# restart service
				ssh $USER_SSH@$IP_HOST service nis restart >/dev/null

				logEndingService $SERVICE
				;;

			"nfs_server")
				logRunningService $SERVICE

				logCheckPackage nfs-common
				if [[ "$(checkInstalledPackage $IP_HOST nfs-common)" -eq 1 ]] ;then
					logInstallingPackage nfs-common
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get install nfs_common > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				logCheckPackage nfs-kernel-server
				if [[ "$(checkInstalledPackage $IP_HOST nfs-kernel-server)" -eq 1 ]] ;then
					logInstallingPackage nfs-kernel-server
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get install nfs_kernel-server > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				# set up nfs_server
				nlines=$(wc -l < $FILE)

				# add each directory in /etc/exports file
				for ((i=1; i<=${nlines}; i++)) ;do
					ssh $USER_SSH@$IP_HOST " echo \"`sed ''$i'q;d' $FILE` $IP_HOST(rw,sync)\" >> /etc/exports" >/dev/null
				done

				ssh $USER_SSH@$IP_HOST  exportfs -ra >/dev/null

				logEndingService $SERVICE
				;;

			"nfs_client")
				logRunningService $SERVICE

				logCheckPackage nfs-common
				if [[ "$(checkInstalledPackage $IP_HOST nfs-common)" -eq 1 ]] ;then
					logInstallingPackage nfs_common
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get install nfs_common > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				# set up nfs_client
				nlines=$(wc -l < $FILE)

				# mount each directory
				for ((i=1; i<=${nlines}; i++)) ;do
					ssh $USER_SSH@$IP_HOST " mount -t nfs $( sed ''$i'q;d' $FILE | cut -d ' ' -f 1):$( sed ''$i'q;d' $FILE | cut -d ' ' -f 2) $( sed ''$i'q;d' $FILE | cut -d ' ' -f 3)" >/dev/null
				done

				logEndingService $SERVICE
				;;

			"backup_server")
				logRunningService $SERVICE

				# backup directory checked before
				# check if rsync is installed in server
				logCheckPackage rsync
				if [[ "$(checkInstalledPackage $IP_HOST rsync)" -eq 1 ]] ;then
					logInstallingPackage rsync
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get install rsync > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				logEndingService $SERVICE
				;;

			"backup_client")
				logRunningService $SERVICE

				logCheckPackage rsync
				if [[ "$(checkInstalledPackage $IP_HOST rsync)" -eq 1 ]] ;then
					logInstallingPackage rsync
					ssh $USER_SSH@$IP_HOST  DEBIAN_FRONTEND=noninteractive apt-get install rsync > /dev/null
					logInstalledPackage
				fi
				logAlreadyInstalled

				# use a temp file to update crontab
				ssh $USER_SSH@$IP_HOST " crontab -l > crontemp" >/dev/null
				ssh $USER_SSH@$IP_HOST " grep -Fx \"0 */$( sed '4q;d' $FILE ) * * * rsync --recursive $( sed '1q;d' $FILE ) $( sed '2q;d' $FILE ):$( sed '3q;d' $FILE )\" crontemp" >/dev/null
				result=$?

				# perform service
				if [[ "$result" -ge 1 ]]; then
					ssh $USER_SSH@$IP_HOST " echo \"0 */$( sed '4q;d' $FILE ) * * * rsync --recursive $( sed '1q;d' $FILE ) $( sed '2q;d' $FILE ):$( sed '3q;d' $FILE )\" >> crontemp" >/dev/null
					ssh $USER_SSH@$IP_HOST  crontab crontemp >/dev/null
				fi

				# remove temp file
				ssh $USER_SSH@$IP_HOST rm crontemp >/dev/null

				logEndingService $SERVICE
				;;
	esac

	# next line
	currLine=$(($currLine + 1))

done

echo -e "\n** All services have been run ..."
exit 0
