#!/bin/bash 
# Author: daltomi

if [ $# -ne 1 ] || [ "$1" == "." ]; then
  echo "Error: falta nombre del directorio."
  echo "Opcional: nombre del archivo de colección"
  echo "Archivo colección por defecto: Collection_SlowUsed.7z"
  exit
fi

COLLECTION_NAME=${2:-"Collection_SlowUsed.7z"}

function clean()
{
  find "$1" \( -regex '.*\.\(txt\|ini\|jpg\|jpeg\|JPG\|PNG\|png\|db\|m3u\|conf\|xml\|cue\|nfo\|sfv\|url\|sh \)' -or -empty \) -exec rm -rf '{}' '+'
}

function audio2ogg()
{
  cd "$1"

  find -type d -exec bash -c '
    process() {
        cd "$1"
        printf "\n\n[*] Cambiando al directorio : %s\n" "$1"
        for x in {*.mp3,*.Mp3,*.MP3,*.m4a,*.webm,*.wma,*.wav,*.flac}
        do 
            printf "[*] Convertir a ogg <- %s\n" "$x"
            if [ -e "$x" ]; then
			  OUT=${x%.*}.ogg
              sox -V1 "$x" "$OUT"
              if [ $? -eq 0 ]; then
              	printf "[*] Eliminado %s\n" "$x"
              	rm -f "$x" 
			  	printf "[*] Done\n\n"
              else
              	printf "[*] Error by SoX: %s\n\n"
              fi
            fi
        done
    }
    process "$@"
    ' find-bash {} \;

  cd ..
}

function audio2opus()
{
  cd "$1"

  find -type d -exec bash -c '
    process() {
        cd "$1"
        printf "\n\n[*] Cambiando al directorio : %s\n" "$1"
        for x in {*.ogg,*.oga,*.mp3,*.Mp3,*.MP3,*.m4a,*.webm,*.wma,*.wav,*.flac}
        do
            printf "[*] Convertir a opus <- %s\n" "$x"
            if [ -e "$x" ]; then
			  OUT=${x%.*}.opus
              ffmpeg -loglevel quiet -acodec copy -i "$x" "$OUT"
              if [ $? -eq 0 ]; then
                printf "[*] Eliminado %s\n" "$x"
                rm -f "$x"
                printf "[*] Done\n\n"
              else
                printf "[*] Error by FFMPEG: %s\n\n"
              fi
            fi
        done
    }
    process "$@"
    ' find-bash {} \;

  cd ..
}




function comprimir()
{
  printf "\n\n[*] Comprimiendo colección : %s\n" "$COLLECTION_NAME"
  
  7z u $COLLECTION_NAME -mx "$1"

  if [ $? -eq 0 ]; then
  	if [ "$RM_COLECTION" == "y" ]; then
  	  printf "\n\n[*] Elimando directorio : %s\n" "$1"
  	  rm -rf "$1"
  	fi
  fi
}


function renombrar() 
{
  cd "$1"

  find -type d -exec bash -c '
    process() {
        cd "$1"
        printf "\n\n[*] Directorio : %s\n" "$1"
        for x in {*.mp3,*.Mp3,*.MP3,*.wma,*.wav,*.flac}
        do 
            printf "[*] Corrigiendo nombres... %s\n"
            if [[ $x == *\\* ]]; then
			  OUT="${x##*\\}"
			  if [[ $OUT == *\-\ * ]]; then
			  	OUT="${x##*\\- }"
			  else  if [[ $OUT == *\-* ]]; then
			  	OUT="${x##*\\-}"
			  fi
			  fi
			  mv "$x" "$OUT"
              if [ $? -eq 0 ]; then
			  	printf "[*] Done\n\n"
              else
              	printf "[*] Error by mv: %s\n\n"
              fi
		  	fi
        done
    }
    process "$@"
    ' find-bash {} \;

  cd ..
}

##########################################
##########################################

echo "-------------------------"
echo "Configurando..."
echo "--------------------------"
read -r -p "[*] ¿Eliminar imágenes, archivos/direc. vacíos y otros archivos basura ? y/[n] :" CLEAN
read -r -p "[*] ¿Convertir archivos de audio a OGG ? y/[n] :" AUDIO2OGG
read -r -p "[*] ¿Convertir archivos de audio a OPUS ? y/[n] :" AUDIO2OPUS
read -r -p "[*] ¿Corregir nombres: \"\\C\\Archivo.ext\" a \"Archivo.ext\" ? y/[n] :" FIXNAME
read -r -p "[*] ¿Crear el archivo de colección $COLLECTION_NAME ? y/[n] :"  COLECTION

if [ "$COLECTION" == "y" ]; then
  read -r -p "Entonces... ¿ decea eliminar el directorio que se ha agregado a la colección ? y/[n]:" RM_COLECTION
fi

if [ "$CLEAN" == "y" ]; then
  	clean "$1"
fi

if [ "$FIXNAME" == "y" ]; then 
	renombrar "$1"
fi

if [ "$AUDIO2OGG" == "y" ]; then
  audio2ogg "$1"
fi

if [ "$AUDIO2OPUS" == "y" ]; then
  audio2opus "$1"
fi

if [ "$COLECTION" == "y" ]; then
  comprimir "$1"
fi

echo
echo "Opciones seleccionadas:"
echo  "-----------------------"
echo "AUDIO2OGG=$AUDIO2OGG, CLEAN=$CLEAN, FIXNAME=$FIXNAME, COLECTION=$COLECTION, RM_COLECTION=$RM_COLECTION"
exit

