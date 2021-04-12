#!/usr/bin/bash
# Author: daltomi

ROJO='\e[0;31m'
AZUL='\e[44m'
NORMAL='\e[0m'

EXIT_FAILURE=1

if [[ 2 -gt $# ]]; then
	echo -e "${ROJO} Error: ${NORMAL} Faltan parámetros."
	echo cpmkd DIR ARCHIVOS
	exit $EXIT_FAILURE
fi

DIR="$1"

ARCHIVOS="${@:2}"

if [[ -f "$DIR" ]]; then
	echo -e "${ROJO} Error: ${NORMAL} se esperaba un directorio."
	exit $EXIT_FAILURE
fi

echo -e ${AZUL} "Copiando..." ${NORMAL}

mkdir -p "$DIR" && cp -vi $ARCHIVOS "$_"

exit $?

