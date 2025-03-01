#!/bin/sh
#
# Grab details about the battery status and show them.
#
# inxi -B and upower -i /org/freedesktop/UPower/devices/DisplayDevice
# are great, but a little hard to read at a glance
#
# Designed for, and only tested with Linux.

VERSION="20250301"

# The values we want.
PERCENTAGE=""
UPDATE=""
STATE=""
TIME_LEFT=""

usage () {
	out="
Display details about the battery status in a terminal window.

There are no options. The script does one task only.

Version: ${VERSION}
"
	printf "%s\n" "${out}"
	exit
}

display () {
	# Need an int and inxi returns a float
	half=$((${PERCENTAGE%%.*} / 2))
	h=`seq ${half}`
	A=`printf "#%.0s" ${h}`
	if [ ${half} -lt 50 ]
	then
		h=`seq $((50 - ${half}))`
		B=`printf ".%.0s" ${h}`
	else
		B=""
	fi
	# Layout
	printf "\n Status: %s" "${STATE}"
	if [ -n "${TIME_LEFT}" ]
	then
		printf " - Time remaining: %s" "${TIME_LEFT}"
	fi
	printf "\n[%s%s] %s%%\n" "${A}" "${B}" "${PERCENTAGE}"
	if [ -n "${UPDATE}" ]
	then
		printf " Updated: %s\n" "${UPDATE}"
	fi
	printf "\n"
}

getDataUPower () {
	RAW=`upower -i /org/freedesktop/UPower/devices/DisplayDevice | grep -o "time to .*:.*\|state:.*\|percentage:.*\|updated:.*"`
	UPDATE=`printf "%s" "${RAW}" | grep -o "^updated:.*" | sed 's/^updated:[[:space:]]*//'`
	STATE=`printf "%s" "${RAW}" | grep -o "^state:.*" | sed 's/^state:[[:space:]]*//'`
	PERCENTAGE=`printf "%s" "${RAW}" | grep -o "^percentage:.*" | sed 's/^percentage:[[:space:]]*//; s/%//'`
	TIME_LEFT=`printf "%s" "${RAW}" | grep -o "^time to .*:.*" | sed 's/^time to .*:[[:space:]]*//'`
}

getDataInxi () {
	# Less details with inxi
	RAW=`inxi -x --battery`
	UPDATE=""
	STATE=`printf "%s" "${RAW}" | grep -o "status: .*" | sed 's/status: //'`
	PERCENTAGE=`printf "%s" "${RAW}" | grep "charge:" | awk -F'%' '{print $1}' | sed 's/.*(//'`
	TIME_LEFT=""
}

getData () {
	if [ -n "`command -v upower`" ]
	then
		getDataUPower
	elif [ -n "`command -v inxi`" ]
	then
		getDataInxi
	else
		printf "\nThis script requires either \"upower\" or \"inxi\" to obtain the needed details\nfrom the battery.\n\nThe script has been unable to locate either.\n\n"
		exit
	fi

}

if [ `uname` != "Linux" ]
then
	printf "\nThis has been designed to work with Linux only.\n\n"
	exit
fi

# There are no options, so show the usage.
if [ -n "${1}" ]
then
	usage
fi

getData
display
exit

