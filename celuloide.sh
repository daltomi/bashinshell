#!/bin/bash
# Author: daltomi

# ATENCIÓN:
#   Éste script elimina archivos permanentemente.
#
# Sinopsis:
#   Visualiza imágenes con el programa 'feh' y luego, al salir el programa, elimina
#   permanentemente (con 'shred') dichas imágenes. Se ejecuta mediante el explorador de archivo vía
#   menú contextual.


#---------------------------------------
# celuloide.desktop
# Depende de $PATH para encontrar éste script.
#---------------------------------------
# PCManFM
# ~/.local/share/file-manager/actions
#---------------------------------------
# [Desktop Entry]
# Type=Action
# ToolbarLabel=Celuloide
# Name=Celuloide
# Profiles=profile-zero;
# Icon=gtk-zoom-out
#
# [X-Action-Profile profile-zero]
# MimeTypes=image/*;
# Exec=celuloide.sh %F
# Name=Default profile
#---------------------------------------


if [[ $# -eq 0 ]]; then
	zenity --error --text="Sin parámetros.\nIndique al menos un archivo de imagen." --title="Celuloide"
	exit 1
fi

zenity --question --text="¿Está seguro de continuar?" --title="Celuloide"

if [[ $? -ne 0 ]]; then
	exit $?
fi

pkill pcmanfm 	# XXX: 	cierra todo proceso pcmanfm, deberia solo cerrarse
		#	el proceso pcmanfm llamante.

feh --auto-zoom --fullscreen "$@"

dir=${@%/*} 	# quita los nombres de archivos.
dir=${dir##* }	# deja el path absoluto del directorio.

$(shred --force --remove "$@"; rmdir $dir) &

exit $?
