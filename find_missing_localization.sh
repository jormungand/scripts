#!/usr/local/bin/bash


[[ "${BASH_VERSINFO}" == "4" ]] || {
	echo -e "Error: bash v4 required\nUpdate bash to v4 via:\n\n\t\$ brew update && brew install bash\n"
	exit 1
}

[[ "x$1" == "x-e" ]] && {
	_EXT_MODE="1"
}



_PATH="<project root>"
_LANG="Base.lproj"
_STRINGS="Localizable.strings"


## dictionary<key, value>
##

declare -A loc
export loc

while read f; do

	_key="${f%%-=!=-*}"
	_value="${f##*-=!=-}"
	
	# echo "<${_key}> ==> <${_value}>"
	loc[${_key}]="${_value}"	

done < <(cat ${_PATH}/${_LANG}/${_STRINGS} | perl -ne 's/"([^""]+?)".*=.*"([^""]+?)"/ print "$1-=!=-$2\n" /ge' | sort -u)



## find usages of L(...) and L_FORM(...) macroses in the code
##

echo -e	"\n\n--------------------------------------------------------------------------"
echo -e "---[Checking code]--------------------------------------------------------\n"

while read f; do
	
	[[ 0 && -n "${loc[$f]}" ]] || {
		echo -e "\t@\"$f\""

		[[ -n "${_EXT_MODE}" ]] && {
			echo -e "\tFound in:"
			grep -ol "\Q$f\E" -R --include '*.h' --include '*.m' ${_PATH} | sort -u
			echo -e "\n\n"
		}
	}
	
done < <(grep -oE '(L|L_FORM)\(.*?@".+?"\)' -R ${_PATH} | perl -ne 's/:.+?@"(.+?)"/ print "$1\n" /ge' | sort -u)



## find text in UILabels
##

echo -e	"\n\n--------------------------------------------------------------------------"
echo -e "---[Checking UILabels in xibs]--------------------------------------------\n"

while read f; do
	
	[[ -n "${loc[$f]}" ]] || {
		echo -e "\t@\"$f\""

		[[ -n "${_EXT_MODE}" ]] && {
			echo -e "\tFound in:"
			grep -ol "\Qtext=\"$f\"\E" -R --include '*.xib' ${_PATH} | sort -u
			echo -e "\n\n"
		}
	}
	
done < <(grep -oE '<label.+?text="(.+?)".+?>' -R --include '*.xib' ${_PATH} | perl -ne 's/ text="([^""]+?)"/ print "$1\n" /ge;' | sort -u)




## find text in UIButtons
##

echo -e	"\n\n--------------------------------------------------------------------------"
echo -e "---[Checking UIButtons in xibs]-------------------------------------------\n"

while read f; do
	
	[[ -n "${loc[$f]}" ]] || {
		echo -e "\t@\"$f\""

		[[ -n "${_EXT_MODE}" ]] && {
			echo -e "\tFound in:"
			grep -ol "\Qtitle=\"$f\"\E" -R --include '*.xib' ${_PATH} | sort -u
			echo -e "\n\n"
		}
	}
	
done < <(grep -oE '<state.+?title="(.+?)".*?>' -R --include '*.xib' ${_PATH} | perl -ne 's/title="([^""]+?)"/ print "$1\n" /ge' | sort -u)





