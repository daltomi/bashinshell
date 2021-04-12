#!/bin/bash
# Author: daltomi

# Crea un archivo contenedor de formato MKV con el mismo formato del
# archivo de video de entrada agregando además archivos de subtítulos.

# Requisitos:
# 1. Archivo de video de cualquier formato.
# 2. Archivo de subtitulo SRT.

# Resumen:
# 1. Convierte un subtítulo SRT al formato unix (LF + UTF-8): dos2unix + recode.
# 2. Crea un nuevo subtitulo de formato ASS desde uno SRT: ffmpeg
# 3. Copia ambos subtítulos al nuevo contenedor MKV: mkvmerge.

# Dependencias:
#	dos2unix
#	recode
#	ffmpeg
#	mkvmerge

if [[ ! $# -eq 3 ]]; then
	echo "Faltan parámetros:"
	echo "video2mkv.sh Salida.mkv Entrada{.mp4,.avi} Archivo.srt"
	exit
fi

OUT="$1"
IN="$2"
SUB="$3"

if [[ -e "$OUT" ]]; then
	echo "El archivo "$OUT" ya existe."
	echo -n "¿Desea sobrescribirlo? s/n: "
	read  SINO
	if [[ $SINO == "n" ]]; then
		echo "No se convirtió ningun archivo."
		exit
	fi
fi

echo;

if [[ ! -e "$IN" ]] || [[ ! -e "$SUB" ]]; then 
	echo "No existe uno de los siguientes archivos:"
	echo "@video_in	= "$IN""
	echo "@subtitle_in	= "$SUB""
	exit
fi

function OkOrBad ()
{
	if [[ $1 == 0 ]]; then 
		echo "OK"
	else
		echo "BAD"
		exit
	fi
	echo;
}

dos2unix "$SUB"
OkOrBad $?

echo  "[*] Convirtiendo a UTF-8":
ENC="$(file --mime-encoding $SUB | grep -c utf-8)"
if [[ $ENC -ne 1 ]]; then
	recode l9..utf-8 "$SUB"
	OkOrBad $?
else
	echo "No es necesario."
	echo;
fi

echo "[*] Creando un nuevo subtitulo tipo ASS:"
ffmpeg -loglevel 8 -i "$SUB" "${SUB%.*}.ass"
OkOrBad $?

echo "[*] Multiplexando hacia MKV:"
mkvmerge -o "$OUT" "$IN" *.{ass,srt} # El orden importa.
OkOrBad $?

echo "[*] Limpieza:"
echo "Entrada: $IN";
echo -n "Subtítulos: "; ls *.{ass,srt}
echo -n "¿Desea eliminar los archivos? s/n: "
read SINO
if [[ $SINO == "s" ]]; then
	rm "$IN" *.{ass,srt}
	exit
fi

# vim: set ts=4 sw=4 tw=500 noet :
