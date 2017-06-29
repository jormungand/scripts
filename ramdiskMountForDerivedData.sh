#!/usr/bin/env -S -P/usr/local/bin:/bin bash

############################################################
## settings
##

_sizeMB=2048
_mountPoint="${HOME}/Library/Developer/Xcode/DerivedData"
_volumeName="DerivedData"



############################################################
## parse options
##

_forceMode=
_shouldUnmount=
_shouldRemount=

while getopts "ufr" opt; do
	case "$opt" in
		"u")
			_shouldUnmount=1
			;;
		"f")
			_forceMode=1
			;;
		"r")
			_shouldUnmount=1
			_shouldRemount=1
			;;
		"?")
			echo "Unknown option: $opt"
			echo
			echo "Usage: $0 [-f] [-u] [-r]"
			echo -e "\t -f 	force clean the ramdisk"
			echo -e "\t -u	unmount ramdisk"
			echo -e "\t -r	unmount and re-mount ramdisk"
			exit 1
			;;
	esac
done

############################################################
## check if Xcode is running, kill if needed
##

_appsToRestart=()
_pidsToKill=()

[[ -z "${_forceMode}" ]] && {
	while read _line; do
		_fields=( ${_line} )
		
		_pidsToKill+=("${_fields[0]}")
		
		_app="${_fields[1]%%.app*}"
		_app="${_app##*/}"
		_appsToRestart+=( ${_app} )

	done < <(ps -eo pid,comm | grep -E '/Contents/MacOS/Xcode$')
	
	[[ -n "${_pidsToKill[@]}" ]] && {
		echo -n "Xcode(s) running (${_appsToRestart[@]}) --> terminating ... "
		kill -1 ${_pidsToKill[@]}
		sleep 2
		echo "done"
	}	
}

############################################################
## ramdisk routines
##

allocateAndFormatDisk() {
	local _diskSizeMB="$1"
	local _volumeName="$2"
	local _blockCount=$(( ${_diskSizeMB} * 1024 * 1024 / 512 ))

	## allocate new ram disk
    echo -n "Allocating new RAM disk of size = [${_diskSizeMB}MB] ... " >&2
    
    local _diskName="$(echo $( hdid -nomount ram://${_blockCount} ))"
    echo "done // disk = [${_diskName}]" >&2

	formatDisk ${_diskName} ${_volumeName} >&2
	
	echo ${_diskName}
	return
}

############################################################

formatDisk() {
	local _diskName="$1"
	local _volumeName="$2"
	
	echo "Formatting [${_diskName}] // volume name = [${_volumeName}]" >&2
	newfs_hfs -J 32M -v "${_volumeName}" "${_diskName}" >&2	
}

############################################################

mountDisk() {
	local _diskName="$1"
	local _mountPoint="$2"
	
	echo "Mounting [${_diskName}] at [${_mountPoint}]" >&2
	mkdir -p ${_mountPoint} >&2
#	diskutil mount -mountPoint "${_mountPoint}" "${_diskName}" >&2
	mount -t hfs -o nodev -o noatime "${_diskName}" "${_mountPoint}"
}

############################################################

unmountDisk() {
	local _diskName="$1"
	local _attempt="${2:-1}"
	
	[[ "${_attempt}" > 3 ]] && {
		echo "Attempt limit exceeded" >&2
		exit 1;
	}

	echo -n "Unmount attempt #${_attempt}... " >&2
	
	## unmount
	_res="$( diskutil unmount "${_diskName}" 2>&1 )"
	_status="$( [[ "$?" == "0" ]] && echo "done" || echo "ERROR" )";
	echo "${_status} // ${_res}" >&2

	## retry if needed
	[[ "${_status}" == "ERROR" ]] && {
		for _pid in "$( echo "${_res}" | perl -ne 's/PID=(\d+)/ print "$1\n"; /ge' )"; do
			echo "--> killing PID=${_pid}" >&2
			kill "${_pid}";
		done

		sleep 1
		unmountDisk "${_diskName}" "$(( ${_attempt} + 1 ))"
		return
	}

	
	echo -n "Ejecting ... " >&2
	echo "done // $( diskutil eject ${_diskName} )" >&2
}


############################################################
## check if disk is already mounted
##

_diskName="$( mount | grep " on ${_mountPoint} " | awk '{ print $1 }' )"

[[ -n "${_diskName}" ]] && {
	echo "RAM disk [${_diskName}] is found"
	
	## unmount mode :: unmount and eject
    [[ -n "${_shouldUnmount}" ]] && {
		unmountDisk ${_diskName}
		
		[[ -n "${_shouldRemount}" ]] && {
			_diskName="$( allocateAndFormatDisk ${_sizeMB} ${_volumeName} )"
			mountDisk ${_diskName} ${_mountPoint}
		}

		## restart Xcode(s)
		for _app in ${_appsToRestart[@]}; do
			echo "Restarting ${_app}"
			open -a ${_app}
		done

		exit
	}
	
	## force clean disk
    [[ -n "${_forceMode}" ]] && {
		formatDisk ${_diskName} ${_volumeName}
		rm -rf ${_mountPoint}/*
		exit
	}
	
	## otherwise
	echo " ==> use '-f' option to force cleanup"
	echo
	exit 1
	
} || {
	## not mounted

	[[ -n "${_shouldUnmount}" ]] && {
		echo "RAM disk is not found"
		
		[[ -n "${_shouldRemount}" ]] || {
			exit 1
		}
	}
	
	_diskName="$( allocateAndFormatDisk ${_sizeMB} ${_volumeName} )"
	mountDisk ${_diskName} ${_mountPoint}
}

############################################################

echo
echo "done"
echo




