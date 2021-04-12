#!/usr/bin/env sh
# Author: daltomi
# Dependencias: amixer(alsa-utils)
# Opcional    : notify-osd 
#
# Parámetros:
#   $1 = 
#        -i   subir volumen (increment)
#        -d   bajar volumen (decrement)
#        -t   conmutar silencio (toggle)
#
#   $2 = valor del volumen, por defecto 3
#

# si amixer se encuentra en ejecución, salir
if [[ $(pidof amixer) -ne 0 ]];  then 
  exit 
fi


DEVICE="default" #"pulse" # or "default"

function get_current_volume()
{
  amixer get Master | grep 'Mono:' | sed -e 's/^[^\[]*//' -e 's/^.//' -e 's/%.*$//'
}

function get_current_mute()
{
  amixer get Master | grep 'Mono:' | grep '\[on]*$'
}

function unmute_mute()
{
  if [[ -z $(get_current_mute) ]]; then 
    amixer -D "$DEVICE" set 'Master' toggle
  fi
}

VOL=${2:-3}

if [ "$1" == "-i" ]; then
  unmute_mute
  amixer  set 'Master' "$VOL"+
  
elif  [ "$1" == "-d" ]; then
  unmute_mute
  amixer set 'Master' "$VOL"-

elif  [ "$1" == "-t" ]; then
  amixer -D "$DEVICE" set 'Master' toggle
else 
  echo "Parámetro desconocido."
fi

# Si existe algún servicio de notificación como
# notify-osd descomentar estas líneas:

VOL=$(get_current_volume)

if [[ $VOL -eq 0 || -z $(get_current_mute) ]]; then
 ICON=audio-volume-muted
else
 if [[ $VOL -lt 25 ]]; then
   ICON=audio-volume-low
 elif [[ $VOL -lt 80 ]]; then
   ICON=audio-volume-medium
 else
   ICON=audio-volume-high
 fi
fi

i3wm=`pidof i3`
notificar=1

if [ $i3wm -ne 0 ]; then
    notificar=0
fi


if [ $notificar -eq 1 ]; then

    #notify-send  "Volumen" -i $ICON -h int:value:$VOL -h string:x-canonical-private-synchronous:1
    dunstify -a "changeVolume" -u low -i "$ICON" -r 234839 "$VOL"

    #dbus-launch notify-send  "$VOL"  -i $ICON -h string:x-canonical-private-synchronous:1

    #dbus-launch notify-send  "Volume" -i $ICON -h int:value:$VOL -h string:x-canonical-private-synchronous:1
fi


# vim: set ts=2 sw=2 tw=500 et :
