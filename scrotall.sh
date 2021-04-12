#!/bin/sh
#------------------------------------------------
# * Author: daltomi
#
# * Dependencies:
#  - scrot
#  - xdotool
#  - convert (ImageMagick)
#
#------------------------------------------------

function usage() {
    local script=${0##*/}
    echo "Syntax: $script [join] [select desktops]"
    echo " $script                (capture all desktops and join vertically, default)"
    echo " $script jv             (capture all desktops and join vertically, default)"
    echo " $script jh             (capture all desktops and join horizontally)"
    echo " $script jv \"0 2\"       (capture desktops 0,2 and join vertically)"
    echo " $script jv 2           (capture only desktop 2 and join vertically)"
}

if [[ "$1" == "h" || "$1" == "help" ]]; then
    usage
    exit
fi

#------------------------------------------------

NDESKTOPS=`xdotool get_num_desktops`

CURRENT_DESKTOP=`xdotool get_desktop`

TMPFILE=`mktemp --dry-run`

JOIN_IMAGE=`mktemp --dry-run scrotall-XXXX.png`

SCROT_DELAY=1

SCROT_QUALITY=100

#------------------------------------------------
function scrot_stack() {
    scrot --stack -d "$SCROT_DELAY" -q "$SCROT_QUALITY" "$TMPFILE"_scrotall"$n".png
}

function scrot_simple() {
    scrot -d "$SCROT_DELAY" -q "$SCROT_QUALITY" "$TMPFILE"_scrotall"$n".png
}

function scrot_with_mouse_pointer() {
    scrot -d "$SCROT_DELAY" "$SCROT_QUALITY" -p "$TMPFILE"_scrotall"$n".png
}

function join_vertical() {
    convert -append "$TMPFILE"_*scrotall*.png "$JOIN_IMAGE"
}

function join_horizontal() {
    convert +append "$TMPFILE"_*scrot*.png "$JOIN_IMAGE"
}

function log() {
    echo "Log options:"
    echo "------------"
    echo Script:
    echo "   NDESKTOPS      : $NDESKTOPS"
    echo "   CURRENT_DESKTOP: $CURRENT_DESKTOP"
    echo "   SCROT_DELAY    : $SCROT_DELAY"
    echo "   SCROT_QUALITY  : $SCROT_QUALITY"
    echo Paramaters:
    echo "   join           : ${1:-default}"
    echo "   select desktop : ${2:-default}"
}
#------------------------------------------------


echo "Capturing with delay of: $SCROT_DELAY ..."

scrot_call="scrot_simple"

if [[ "$2" != "" ]]; then
    for n in $(echo "$2"); do
        if [[ "$n" -ge "$NDESKTOPS" ]]; then
            break
        fi
        xdotool set_desktop "$n"
        eval "$scrot_call"
    done
else
    for ((n=0; n < "$NDESKTOPS"; n++)); do
        xdotool set_desktop "$n"
        eval "$scrot_call"
    done
fi

xdotool set_desktop "$CURRENT_DESKTOP"

echo Join images to file \""$PWD"/"$JOIN_IMAGE"\", wait...
if [[ "$1" == "jh" ]]; then
    join_horizontal
else
    join_vertical
fi

log "$1" "$2"

rm "$TMPFILE"_scrot*.png

