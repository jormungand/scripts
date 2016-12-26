#!/bin/bash

## settings
##

_repo="$( git remote get-url $(git remote) )"
_repo_name="MyPrivateSpecs"



## check private PodSpec repo, add if necessary
##

_found="$( pod repo list | perl -e '$_ = join "", <>; s/\n\- /|/gs; print' | grep "${_repo}" | cut -d "|" -f1 )"

[[ -z "${_found}" ]] && {
	echo "Private PodSpec repo not found, adding..."
	echo "--> pod repo add ${_repo_name} ${_repo}"
	
	pod repo add ${_repo_name} ${_repo}

} || {
	echo "Found private PodSpec repo: ${_found}"
}



## loop through all the podspecs
##

find . -name "*.podspec" | while read f; do
	pod spec lint --sources="${_repo_name},master" --allow-warnings $f
done