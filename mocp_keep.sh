#!/usr/bin/env bash
# Author: daltomi

ROJO='\e[0;31m'
NORMAL='\e[0m'

FIRST_RUN=0

EPAUSE=0
EPLAY=1
ESTOP=2
EPAUSE_FIRST_RUN=3
EEXIT_OK=0
EEXIT_ERR=1

is_execute() {
	if [[ -z $(pidof mocp) ]];  then
		echo "---------------------------------------------------------------------------"
		echo -e "${ROJO} MOC is not running. Exit.${NORMAL}"
		echo "---------------------------------------------------------------------------"
		exit "$EEXIT_ERR"
	fi
}

error_params() {
	echo "---------------------------------------------------------------------------"
	echo -e "${ROJO} Error.${NORMAL}"
	echo " Indicate the beginning and end of the range, in percentages."
	echo
	echo " mocp_keep.sh BEGIN END"
	echo
	echo " BEGIN must be less than END."
	echo
	echo " Ex: mocp_keep.sh 34 50"
	echo "---------------------------------------------------------------------------"
	exit "$EEXIT_ERR"
}


is_playing() {
	PLAYING=$(mocp --info | grep State: | awk '{print $2}')

	if [[ "$PLAYING" == "PLAY" ]]; then
		return "$EPLAY"
	fi

	if [[ "$PLAYING" == "STOP" ]]; then
		return "$ESTOP"
	fi

	if [[ "$FIRST_RUN" == 0 ]]; then
		FIRST_RUN=1
		return "$EPAUSE_FIRST_RUN"
	fi

	return "$EPAUSE"
}

if [[ $# -ne 2 ]]; then
	error_params
fi

BEGIN="$1"
END="$2"


if [[ "$BEGIN" -gt "$END" ]]; then
	error_params
fi

is_execute
is_playing

PLAYING="$?"

if [[ "$PLAYING" == "$EPAUSE_FIRST_RUN" ]]; then
	echo "---------------------------------------------------------------------------"
	echo -e "${ROJO} MOC state PAUSE. First run script. Exit. ${NORMAL}"
	echo "---------------------------------------------------------------------------"
	exit "$EEXIT_ERR"

fi

mocp --jump "$BEGIN%"

while [ 1 ]
do
	is_execute
	is_playing

	PLAYING="$?"

	if [[ "$PLAYING" == "$EPLAY" ]]; then

		INFO=$(mocp --info)
		SEC=$(echo "$INFO" | grep CurrentSec: | awk '{print $2}')
		TSEC=$(echo "$INFO" | grep TotalSec: | awk '{print $2}')
		PERCENT=$(( SEC * 100 / TSEC ))

		if  [[ "$PERCENT" -eq "$END" ]] || [[ "$PERCENT" -gt "$END" ]]; then
			mocp --jump "$BEGIN%"
		fi
	fi

	if [[ "$PLAYING" == "$EPAUSE" ]]; then
		echo "---------------------------------------------------------------------------"
		echo -e "${ROJO} MOC state PAUSE. Wait ... ${NORMAL}"
		echo "---------------------------------------------------------------------------"
	fi

	if [[ "$PLAYING" == "$ESTOP" ]]; then
		echo "---------------------------------------------------------------------------"
		echo -e "${ROJO} MOC state STOP. Exit. ${NORMAL}"
		echo "---------------------------------------------------------------------------"
		exit "$EEXIT_ERR"
	fi

	sleep 2
done

exit "$EEXIT_OK"
