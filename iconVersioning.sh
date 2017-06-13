#!/bin/bash

_scriptVersion="1.1.0"
_debug=

echo "------------------------------------------------------------------------------------------------------"
echo "🌇  App Icon Annotating script v${_scriptVersion} // Created by 👉  Ilya Stroganov [https://github.com/jormungand]"
echo "➜  Created under inspiration of the similar script by Krzysztof Zabłocki [http://merowing.info/]"
echo "------------------------------------------------------------------------------------------------------"


##############################################################################################################
##############################################################################################################
##############################################################################################################
## API
##

DEBUG() {
	[[ -n "${_debug}" ]] && echo $@
}

##############################################################################################################

annotateIcon() {
	_file="${1}"
	_caption="${2}"

	[[ -f "${_file}" ]] || {
		echo "⚠️  File not found: ${_file} --> skipped"
		return;
	}

	echo "✅  Processing file: ${_file}"

	_name="$( basename "${_file}" )"
	_tmpDir="$( mktemp -d )"

	xcrun pngcrush -revert-iphone-optimizations -q "${_file}" "${_tmpDir}/${_name}" >/dev/null 2>&1

    _width="$(  identify -format %w "${_tmpDir}/${_name}" )"
    _height="$( identify -format %h "${_tmpDir}/${_name}" )"

	_bandOffset="+0+$(( (${_height} / 6) * 5 ))"
	_bandSize="${_width}x$(( ${_height} / 6 ))"
	_labelSize="$(( (${_width} / 6) * 5 ))x$(( ${_height} / 6 ))"

	## TODO: save as "${_tmpDir}/${_name}-annotated.png", then run re-optimize using pngcrush 

	convert "${_tmpDir}/${_name}" -region "${_bandSize}${_bandOffset}" -blur "10x10" +region \
		-fill "#0004" -draw "rectangle 0,$(( (${_height} / 6) * 5 )),${_width},${_height}" \
		\( -background "#fff0" -fill "#ffff" -gravity "center" -font "ArialB" -size "${_labelSize}" caption:"${_caption}" \) \
		-gravity "south" -composite "${_file}" 	

	rm -rf "${_tmpDir}"
}

##############################################################################################################
##############################################################################################################
##############################################################################################################
## prerequisites: ImageMagick & Ghostscript
##

export PATH="/usr/local/bin:/usr/libexec:$PATH"

_convert="$( which convert )"
_gs="$( which gs )"

[[ -x "${_convert}" && -x "${_gs}" ]] || {
	echo "⛔️  ERROR: Install dependencies first:"
	echo -e "\tbrew install imagemagick ghostscript"
	echo -e "\n\n----------------------------\n👎  CANCELLED\n"
	exit 0;
}

## PlistBuddy

[[ -x "$( which PlistBuddy )" ]] || {
	echo "⛔️  ERROR: Couldn't find PlistBuddy"
	echo -e "PATH = (\n$( echo $PATH | tr ':' '\n' | awk '{ print "\t"$1 }' | sort -ru )\n)"
	echo -e "\n\n----------------------------\n👎  CANCELLED\n"
	exit 0;
}

##############################################################################################################
## Get build params
##

echo -e "🛠  Reading configuration:\n---"

_infoPlist="${CONFIGURATION_BUILD_DIR}/${INFOPLIST_PATH}"

[[ -f "${_infoPlist}" ]] || {
	echo "⛔️  ERROR: Info plist is not found: INFOPLIST_PATH = [${INFOPLIST_PATH}], CONFIGURATION_BUILD_DIR = [${CONFIGURATION_BUILD_DIR}]"
	echo -e "\n\n----------------------------\n👎  CANCELLED\n"
	exit;
}

_version="$(	PlistBuddy -c "Print CFBundleShortVersionString" 	"${_infoPlist}" )"
_buildNum="$(	PlistBuddy -c "Print CFBundleVersion" 				"${_infoPlist}" )"
_bundleID="$( 	PlistBuddy -c "Print CFBundleIdentifier" 			"${_infoPlist}" )"

echo "🔹  Version   = [${_version}]"
echo "🔹  BuildNum  = [${_buildNum}]"
echo "🔹  BundleID  = [${_bundleID}]"

## Git status

git rev-parse --git-dir >/dev/null 2>&1 || {
	echo "⛔️  ERROR: Git dir is not found: PWD = [${PWD}]"
	echo -e "\n\n----------------------------\n👎  CANCELLED\n"
	exit 0;
}

_commit="$( git rev-parse --short HEAD )"
_branch="$( git rev-parse --abbrev-ref HEAD )"

echo "🔹  Commit    = [${_commit}]"
echo "🔹  Branch    = [${_branch}]"

_caption="${_version} (${_buildNum})"
echo -e "---\n✅  Icon badge caption string = [${_caption}]"

##############################################################################################################

pushd "$( dirname "${_infoPlist}" )" >/dev/null

echo "------------------------------------------------------------------------------------------------------"
echo -e "🔍  Searching for icons:\n---"

for _key in "CFBundleIcons" "CFBundleIcons~ipad"; do
	_icons+="$( PlistBuddy -c "Print '${_key}:CFBundlePrimaryIcon:CFBundleIconFiles'" "${_infoPlist}" | grep -vE '[{}]' )"
	_icons="$( echo "${_icons[@]}" | tr ' ' "\n" | sort -u )"
done

for _i in ${_icons[@]}; do
	echo -e "🔸  ${_i}"
done

## Enumerating through exact files

echo "------------------------------------------------------------------------------------------------------"
for _i in ${_icons[@]}; do
	echo "➜  [${_i}*.png]"
	
	for _f in $( find ${PWD} -iname "${_i}*.png" ); do
		annotateIcon "${_f}" "${_caption}"
	done
	echo "---"
done


popd >/dev/null
echo -e "\n\n----------------------------\n👍  DONE\n----------------------------\n"



