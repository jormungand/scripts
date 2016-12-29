#!/bin/bash

############################################################
## settings
##

_sizeMB=2048
_blockCount=$(( ${_sizeMB} * 1024 * 1024 / 512 ))

_mountPoint="${HOME}/Library/Developer/Xcode/DerivedData"
_volumeName="DerivedData"

_forceMode=
_unmountMode=




############################################################
## parse options
##

while getopts "uf" opt; do
	case "$opt" in
		"u")
			_unmountMode=1
			;;
		"f")
			_forceMode=1
			;;
		"?")
			echo "Unknown option: $OPTARG"
			echo
			echo "Usage: $0 [-f] [-u]"
			exit 1
			;;
	esac
done




############################################################
## check if Xcode is running, kill if needed
##

_procList="$( ps -ef | grep 'Contents/MacOS/Xcode' | grep -v grep )"
	
[[ -n "${_procList}" ]] && {
	echo -n "Xcode is running --> terminating ... "
	killall Xcode
	sleep 2
	echo "done"
}




############################################################
## check if disk is already mounted
## 

_diskName="$( mount | grep " on ${_mountPoint} " | awk '{ print $1 }' )"
	
[[ -n "${_diskName}" ]] && {
	echo "RAM disk [${_diskName}] is found"

	## unmount mode :: unmount and eject
	[[ -n "${_unmountMode}" ]] && {
		
		echo -n "Unmounting ... "
		echo "done // $( diskutil unmount ${_diskName} )"
		
		echo -n "Ejecting ... "
		echo "done // $( diskutil eject ${_diskName} )"
		
		echo
		exit
	}

	## proceed with new mount
	## check if 'force' flag specified
	
	[[ -n "${_forceMode}" ]] || {
		echo " - use '-f' option to force cleanup"
		echo
		exit 1
	}

} || {
	## not mounted
	[[ -n "${_unmountMode}" ]] && {
		echo "RAM disk is not found"
		echo
		exit 1
	}	
	
	## allocate new ram disk
	echo -n "Allocating new RAM disk of size = [${_sizeMB}MB] ... ";

	_diskName="$(echo $( hdid -nomount ram://${_blockCount} ))"
	echo "done // disk = [${_diskName}]"
}




############################################################
## formatting and mounting
##

echo "Formatting [${_diskName}] // volume name = [${_volumeName}]"
newfs_hfs -v ${_volumeName} ${_diskName}

echo "Mounting [${_diskName}] at [${_mountPoint}]"
diskutil mount -mountPoint ${_mountPoint} ${_diskName}

echo "Done"
echo

