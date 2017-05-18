#!/bin/bash

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
_shouldRestartXcode=

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

[[ -n "$( ps -ceo comm | grep -E '\bXcode$' )" && -z "${_forceMode}" ]] && {
	echo -n "Xcode is running --> terminating ... "
	killall Xcode
	sleep 2
	_shouldRestartXcode=1
	echo "done"
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


formatDisk() {
	local _diskName="$1"
	local _volumeName="$2"
	
	echo "Formatting [${_diskName}] // volume name = [${_volumeName}]" >&2
	newfs_hfs -J 32M -v "${_volumeName}" "${_diskName}" >&2	
}


mountDisk() {
	local _diskName="$1"
	local _mountPoint="$2"
	
	echo "Mounting [${_diskName}] at [${_mountPoint}]" >&2
	mkdir -p ${_mountPoint} >&2
#	diskutil mount -mountPoint "${_mountPoint}" "${_diskName}" >&2
	mount -t hfs -o nodev -o noatime "${_diskName}" "${_mountPoint}"
}


unmountDisk() {
	local _diskName="$1"
	
	echo -n "Unmounting ... " >&2
	echo "done // $( diskutil unmount ${_diskName} )" >&2
	
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

		## restart Xcode
		[[ -n "${_shouldRestartXcode}" ]] && {
			open -a xcode
		}

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

echo
echo "done"
echo




