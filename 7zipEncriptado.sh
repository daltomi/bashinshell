#!/usr/bin/env bash
# Author: daltomi

################################################################################
# @ 7zipEncriptado:
# - Permite, mediante el menú contextual, sobre un archivo o carpeta, encriptar
#   dichos archivos mediante una clave ingresada por el usuario. El resultado es
#   un archivo con nombre de la carpeta o archivo más la extensión de 
#   formato .7z
# - También permite desencriptar un archivo .7z
#
# @ Resumen:
# - Si se crea un nuevo archivo, se ingresa la clave para encriptar.
# - Si el archivo ya existe, se actualizará dicho archivo; la clave debe ser la
#   del archivo ya encriptado.

# @ Dependencias:
# - p7zip
# - Zenity

# @ Importante:
# - No es una aplicación para terminal, debe utilizarse desde un
#   explorador de archivos (Thunar, PCManFM, etc)
# - Cuando se elije sobrescribir un archivo comprimido ya existente, éste se elimina
#   con el comando 'rm'.

# @ Platillas:

#--------------------------------------- 
# $Id: Thunar, SendTo 
# ~/.local/share/Thunar/sendto/7zipEncriptado.desktop
# Depende de $PATH para encontrar éste script.
#--------------------------------------- 
#  [Desktop Entry]
#  Type=Application
#  ToolbarLabel=7zip Encriptado
#  Name=7zip Encriptado
#  Profiles=profile-zero;
#  Icon=gtk-orientation-landscape
#  MimeTypes=*;
#  Exec=7zipEncriptado.sh %F
#---------------------------------------


#---------------------------------------
# $Id: PCManFM
# ~/.local/share/file-manager/actions/7zipEncriptado.desktop
# Depende de $PATH para encontrar éste script.
#---------------------------------------
#  [Desktop Entry]
#  Type=Action
#  ToolbarLabel=7zip Encriptado
#  Name=7zip Encriptado
#  Profiles=profile-zero;
#  Icon=gtk-orientation-landscape
#  
#  [X-Action-Profile profile-zero]
#  MimeTypes=*;
#  Exec=7zipEncriptado.sh %F
#  Name=Default profile
#  SelectionCount==1
#---------------------------------------
################################################################################

function ObtenerClave ()
{
    pass=`zenity --entry \
        --text="$TEXT"    \
        --title="$TITLE" \
        --hide-text`

    if [[ -z $pass ]]; then
        exit
    fi
}


function Desencriptar ()
{
    local dir="${FILE%/*}/"

    cd "$dir"

    if [[ $? -ne 0 ]]; then
        zenity --error --text="No se pudo acceder al directorio $dir"
        exit
    fi

    7zip 'x'
}

function 7zipInformacion ()
{
    case $1 in
        'a') TEXT="Ingrese la clave para encriptar:";;
        'u') TEXT="Ingrese la clave para\ndesencriptar y actualizar:";;
        'x' | 'e') TEXT="Ingrese la clave para desencriptar:";;
    esac
}


function esPosibleDescomprimir ()
{
    local ES_DIR=`7za l -p$pass $FILE | awk '{print $3,$6}' |  grep "^D[+.]" | \
        awk '{print $1}' | head -n 1`

    if ! [[ -z "$ES_DIR" ]]; then

        local NAME=`7za l -p$pass $FILE | awk '{print $3,$6}' |  grep "^D[+.]" | \
            awk '{print $2}' | head -n 1`

        if [[ -e "$NAME" ]]; then

            zenity --question --text="Ya existe el directorio $NAME\n¿Desea sobreescribirlo?"
            return $?

        fi
    else

        local NAME=`7za l -p$pass $FILE | awk '{print $3,$6}' |  grep "[+.]A" | \
            awk '{print $2}' | head -n 1`

        if [[ -e "$NAME" ]]; then

            zenity --question --text="Ya existe el archivo $NAME\n¿Desea sobreescribirlo?"
            return $?
        fi

    fi

    return 0
}


function 7zip ()
{
    local func="$1"

    7zipInformacion $func

    ObtenerClave

    (
        if [[ $func == 'u' ]] || [[ $func == 'a' ]];  then

            LOG=`7za $func -y -mhe=on -p$pass "$NAME_ZIP" "$FILE"` || \
                zenity --info --title="$TITLE" --text="$LOG"

        else if [[ $func == 'x' ]] || [[ $func == 'e' ]]; then

            esPosibleDescomprimir

            if [[ $? -eq 1 ]]; then
                exit
            fi

            LOG=`7za $func -y -p$pass "$FILE"` || \
                zenity --info --title="$TITLE" --text="$LOG"
       fi
       fi
    ) | zenity --progress --title="$TITLE" --text="En progreso..." --pulsate --width=250
}


function Encriptar ()
{
    if [[ -e $NAME_ZIP ]]; then

        ACTION=`zenity --list \
            --title="$TITLE" \
            --text="El archivo \"${NAME_ZIP##*/}\" ya existe.\n¿Que desea hacer?" \
            --column="Acción" \
            --print-column=1 \
            Actualizar Sobrescribir`

        if [[ -z $ACTION ]]; then
            exit
        fi

        if [[ $ACTION == "Actualizar" ]]; then
            func=u # Actualizar.
        fi
    fi

    if [[ $func == "a" ]]; then
        rm "$NAME_ZIP"
    fi

    7zip $func
}

###############################################################################
TITLE='7zip encriptado'

if (( $# == 0 )); then
    zenity --error --title="$TITLE" --text="Ningún archivo o directorio seleccionado."
    exit
fi


if (( $# > 1 )); then 
    zenity --error --title="$TITLE" --text="Demasiados archivos contenedores."
    exit
 
fi

##############################################################################
FILE="$1"
NAME_ZIP=${FILE%/}.7z
func=a # Por defecto, crear.

if ! [[ -e $FILE ]]; then
    zenity --error --title="$TITLE" --text="El archivo/directorio \"$FILE\" no existe!"
    exit
fi

if [[ ${FILE: -3} == ".7z" ]]; then
    Desencriptar
else
    Encriptar
fi

exit
