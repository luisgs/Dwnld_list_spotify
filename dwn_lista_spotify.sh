#!/bin/bash
#===============================================================================
#
#          FILE:  dwn_lista_spotify.sh
# 
#         USAGE:  ./dwn_lista_spotify.sh 
# 
#   DESCRIPTION:  Descarga las canciones (de Dilandau)de listas de Spotify (de 
#			listasSpotify.com).
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  curl, grep, wget command
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  luisGS 
#       COMPANY:  --- 
#       VERSION:  1.5
#       CREATED:  27/06/11 09:10:27 CEST
#      REVISION:  20/11/11
#===============================================================================
# URL de la lista Spotify
url=$1
cut1=`echo $1 | cut -c1-16`;
cut2=`echo $1 | cut -c8-23`;
fich="lista.html";
aux='aux';
#dirbase="/tmp/"
songs="songs.txt";
links="links.txt";
repro='lista_reproducion.m3u';

if [ -z $1 ]; # Cadena con valor nulo
then
	echo "############################################";
	echo "Por favor incluye una direccion de listasSpotify.es para descargar.";
	echo "############################################";
	exit;
elif [ $cut1 == "listasspotify.es" ] ||	[ $cut2 == "listasspotify.es"  ] #listasSpoti#Dentro de una cadena, palabra
then
	echo "############################################";
	echo "Direccion de Spotify correcta.";
	echo "############################################";
	outdir=`echo $1 | sed 's/.*\///g'`; # nombre del dir=URl pasada!
	outdir=$outdir/;
else
	echo "############################################";
	echo "Argumento erroneo, por favor, direccion listasSpotify.es correcta.";
	echo "############################################";
	exit;
fi

#Nos ha pasado un 2º argumento?
if [ $2 ]
then
	#Comprobamos directorio valido
	if test -d $2	# Es direcotior¿?
	then	# Directorio valido
        	#dirbase=$1; # Mas comprobaciones!
		# Ultimo char='/' ¿?
		long=`echo $2 | wc -m`;	# Longitud caracteres+1
                long=`expr $long`;	# resto el desfase
		lchar=`echo $2 | cut -c $long`;	# Cojo el ultimo char
		if [ "$lchar" = "/" ]
                then
			dirbase=$2; # Esta correcto y como queremos le dir
		else	# anadimos el '/' al final
			dirbase=`echo $2"/"`;
                fi
		echo "############################################";
	        echo "Directorio de salida: "$dirbase"Nombre_lista/";
		echo "############################################";
	else	# Directorio no valido->salimos!
		echo "############################################";
		echo "Directorio pasado como argumento:"$2", no valido.";
		echo "############################################";
		exit;
	fi
else
	echo "############################################";
	echo "Directorio de salida por defecto: /tmp/Nombre_lista/";
	echo "############################################";
        dirbase='/tmp/';
fi
# Ahora tenemos en $dirbase el directorio de salida donde se copiara
# toda la lista con las canciones


echo "############################################";
echo "Ahora pasamos a descargar las canciones (directorio:$dirbase$outdir)"
echo "############################################";
# Si existe directorio no lo crea. e.o.c SI
mkdir -p $dirbase$outdir;

# URL pasado como argumento ok # descargamos la pagina
echo "############################################"
echo "Descargando la pagina para analizarla.";
echo "############################################";
curl $1 > $dirbase$outdir$fich
echo "Descargada en $dirbase$outdir$fich"

# Tiene la lista de canciones publicada¿?
if [ `grep -c "listacanciones" $dirbase$outdir/$fich` ];
then
	echo "############################################";
	echo "Se pueden descargar las canciones, hay lista publicada!!"
	echo "############################################";
else
	echo "############################################";
	echo "Lo siento NO hay lista de canciones publicadas"
	echo "############################################";
	exit;
fi

# Extraemos las canciones a un fichero externo
grep "<li>" $dirbase$outdir$fich | sed "s/^<li>//g" | sed "s/<\/li>//g" | sed "s/ /_/g" > $dirbase$outdir$songs;
# Posibilidades de ficheros URL
if [ ! -s $dirbase$outdir$songs ];
then
	echo "############################################";
	echo "Opcion 2..."
	echo "############################################";
	grep "<br />" $dirbase$outdir$fich | tr -s ' ' | sed "s/<br \/>//g" | sed "s/ <p>//g" | sed "s/ – /-/g" | sed "s/ - /-/g" | sed "s/ /_/g" > $dirbase$outdir$songs
else 
	echo "############################################";
	echo "No hay una Opcion para este caso.!!";
	echo "############################################";
	break;
fi

echo "############################################";
echo "Estas son las canciones de la lista enviada:"
echo "############################################";
cat $dirbase$outdir$songs
echo "############################################";
touch $dirbase$outdir"lincos"
cat /dev/null > $dirbase$outdir"lincos"

while read line
do
	## Ya han sido descargados?
	if [ -f "$dirbase$outdir$line.mp3" ];
	then
		echo "Cancion $line YA descargada!!!!" 
	else	#No ha sido descargada
		echo "############################################";
		echo -e "# Descargando $line"
		echo "############################################";
		# Descargamos la pagina de Dilandau para una cancion espacifica
		`curl http://es.dilandau.eu/descargar-mp3/$line-1.html > $dirbase$outdir$fich`;
		# Guardamos todos los links de descargas
		`sed -e 's/.*file : "//' -e 's/".*//' $dirbase$outdir$fich > $dirbase$outdir$links`;

		echo "####!!!$line:" >> $dirbase$outdir"lincos"
		`sed -e 's/.*file : "//' -e 's/".*//' $dirbase$outdir$fich >> $dirbase$outdir"lincos"`;
		echo "####!!!!\n" >> $dirbase$outdir"lincos"

		while read linea
		do
			echo "############################################";
			echo "La canción $line tiene por link a descargar:$linea";
			echo "############################################";
			# wget -t -> numero de reintentos
			wget -O"$dirbase$outdir$line.mp3" -t 3 -T 10 "$linea" > /dev/null
			echo "$dirbase$outdir$line.mp3" >> "$dirbase$outdir$repro"
			echo "############################################";
			break;	# con la primera nos vale
		done < $dirbase$outdir$links
	fi
done < $dirbase$outdir$songs

echo "############################################";
echo "Eliminamos ficheros temporales..."
echo "############################################";
#rm $dirbase$outdir$fich
#rm $dirbase$outdir$aux
#rm $dirbase$outdir$links
