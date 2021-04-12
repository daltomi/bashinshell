#!/bin/bash
# Author: daltomi

function notify 
{
    notify-send -a "micrecord" -i "media-record" "$1" 
}

if [ "$(pidof rec)" ]; then
    killall rec 
    notify "Terminada"
    exit
fi

notify "Iniciada"

dir=/tmp                     # Trabajo
name=$dir/${1:-$RANDOM}.ogg  # Nombre final

rec --channels 1 --no-show-progress $name

if [ $? != 0 ]; then
    notify "Error inicio de grabación"
#    printf "Error de inicio de grabación\n"
fi
