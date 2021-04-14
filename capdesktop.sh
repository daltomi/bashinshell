#!/usr/bin/env bash
#------------------------------------------------
# * capdesktop - Screenshot of virtual desktops.
#
# * Author: https://github.com/daltomi
#
# * Shell: bash
#
# * Dependencies:
#     External tools:
#         - scrot
#         - xdotool
#         - convert (ImageMagick)
#     Base tools:
#         - mktemp
#         - whereis
#         - grep
#         - basename
#         - echo
#         - rm
#
#
#------------------------------------------------
SCRIPT_NAME="$(basename "$0")"

NDESKTOPS=`xdotool get_num_desktops`

CURRENT_DESKTOP=`xdotool get_desktop`

TMPFILE="$(mktemp --dry-run)_capdesktop"

JOIN_IMAGE=`mktemp --dry-run capdesktop-XXXX.png`

JOIN_MODE="v"

PRINT_LOG=0

ID_DESKTOPS="-1"

SCROT_DELAY=1

SCROT_QUALITY=100

SCROT_STACK=0

SCROT_MOUSE=0

SCROT_OPTIONS=""

CONVERT_OPTIONS="-append"

#------------------------------------------------

function usage() {
    echo "Syntax: $SCRIPT_NAME [options]"
    echo "  Options:"
    echo "  -h          help"
    echo "  -jv         join vertical (default)"
    echo "  -jh         join horizontal"
    echo "  -d [num]    delay (default: 1 seg.)"
    echo "  -s          stack windows"
    echo "  -p          capture mouse pointer"
    echo "  -i [num]    desktops ids, start at 0 (default:-1 == all)"
    echo "  -l          print script log"
    echo
    echo "  Example:"
    echo "   $SCRIPT_NAME              (capture all desktops)"
    echo "   $SCRIPT_NAME -i \"0 2 4\"   (capture desktop 0,2 and 4)"
    echo "   $SCRIPT_NAME -i 2         (capture only desktop 2)"
    exit
}

function set_options() {
    if [[ "$JOIN_MODE" == "h" ]]; then
        CONVERT_OPTIONS="+append"
    fi

    if [[ "$SCROT_STACK" -eq 1 ]]; then
        SCROT_OPTIONS=" --stack "
    fi

    if [[ "$SCROT_MOUSE" -eq 1 ]]; then
        SCROT_OPTIONS="$SCROT_OPTIONS --pointer "
    fi
}

function capture() {
    scrot -d "$SCROT_DELAY" -q "$SCROT_QUALITY" $SCROT_OPTIONS $TMPFILE$n.png
    tool_check_error $? "scrot"
}

function join() {
    convert "$CONVERT_OPTIONS" $TMPFILE*.png "$JOIN_IMAGE"
    tool_check_error $? "convert"
}

function log() {
    echo "Log options:"
    echo "------------"
    echo Script:
    echo "   SCRIPT_NAME    : $SCRIPT_NAME"
    echo "   NDESKTOPS      : $NDESKTOPS"
    echo "   CURRENT_DESKTOP: $CURRENT_DESKTOP"
    echo "   JOIN_MODE      : $JOIN_MODE"
    echo "   PRINT_LOG      : $PRINT_LOG"
    echo "   ID_DESKTOPS    : $ID_DESKTOPS"
    echo "   SCROT_DELAY    : $SCROT_DELAY"
    echo "   SCROT_QUALITY  : $SCROT_QUALITY"
    echo "   SCROT_STACK    : $SCROT_STACK"
    echo "   SCROT_MOUSE    : $SCROT_MOUSE"
    echo "   SCROT_OPTIONS  : $SCROT_OPTIONS"
    echo "   CONVERT_OPTIONS: $CONVERT_OPTIONS"
}

function tool_check_if_exist() {
    local SUCCESS=0

    whereis -b "$1" | grep /bin/ >/dev/null

    if [[ $? -ne $SUCCESS ]]; then
        echo "$SCRIPT_NAME: Error, tool not found: $1"
        exit
    fi
}

function tool_check_error() {
    local SUCCESS=0

    if [[ $1 -ne $SUCCESS ]]; then
        tool_print_error "$2"
    fi
}

function tool_print_error() {
        echo "$SCRIPT_NAME: Error, failed tool: $1"
        exit
}

function param_print_error() {
        echo "$SCRIPT_NAME: Error, invalid option for $1"
        usage
}

function param_is_number() {
    [[ $1 == ?(-)+([0-9]) ]] && return 1
    return 0
}

function param_validate() {

    if [[ "$JOIN_MODE" != "h" &&  "$JOIN_MODE" != "v" ]]; then
        param_print_error "-j"
    fi

    if ! [[ "$SCROT_DELAY" -ge 0 ]]; then
        param_print_error "-d"
    fi

    if [[ "$SCROT_STACK" -ne 0 && "$SCROT_STACK" -ne 1 ]]; then
        param_print_error "-s"
    fi

    for n in $ID_DESKTOPS; do
        param_is_number "$n"
        if [[ "$?" -ne 1 ]]; then
            param_print_error "-i"
        fi
    done
}

#------------------------------------------------
#                    MAIN
#------------------------------------------------
while getopts "j:d:spi:l" option
do
    case $option in
        h   ) usage;;
        j   ) JOIN_MODE="$OPTARG";;
        d   ) SCROT_DELAY="$OPTARG";;
        s   ) SCROT_STACK=1;;
        p   ) SCROT_MOUSE=1;;
        i   ) ID_DESKTOPS="$OPTARG";;
        l   ) PRINT_LOG=1;;
        ?   ) usage;;
    esac
done

tool_check_if_exist "scrot"
tool_check_if_exist "xdotool"
tool_check_if_exist "convert"
param_validate
set_options

echo "Capturing with delay of $SCROT_DELAY seg. ..."

if [[ "$ID_DESKTOPS" == "-1" ]]; then
    for ((n=0; n < "$NDESKTOPS"; n++)); do
        xdotool set_desktop "$n"
        tool_check_error $? "xdotool"
        capture
    done
else
    for n in $ID_DESKTOPS; do
        xdotool set_desktop "$n"
        tool_check_error $? "xdotool"
        capture
    done
fi

xdotool set_desktop "$CURRENT_DESKTOP"
tool_check_error $? "xdotool"

echo Join images to file \""$PWD"/"$JOIN_IMAGE"\", please wait...
join

[[ "$PRINT_LOG" -eq 1 ]] && log

echo "Cleaning temporary files in /tmp ..."
rm $TMPFILE*.png
tool_check_error $? "rm"

echo "Done."

