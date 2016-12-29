#!/bin/bash

echo "Xcode:"

XCODEUUID=`defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID`
for f in ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/*; do 
	echo -e "\t${f}";
	defaults write "$f/Contents/Info" DVTPlugInCompatibilityUUIDs -array-add $XCODEUUID; 
done

[[ -e /Applications/Xcode-beta.app ]] && {
	echo -e "\n\nXcode-beta:"
	XCODEUUID=`defaults read /Applications/Xcode-beta.app/Contents/Info DVTPlugInCompatibilityUUID`\
	
	for f in ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/*; do 
		echo -e "\t${f}";
		defaults write "$f/Contents/Info" DVTPlugInCompatibilityUUIDs -array-add $XCODEUUID;
	done
}

echo -e "\n\n"