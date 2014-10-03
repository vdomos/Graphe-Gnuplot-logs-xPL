#!/bin/bash
 
DEVICE="28.2CAED7010000"
TYPE="temp"
UNIT="°C"
GRAPHCOLOR="red"
TITLE="Température extérieure"
 
SENSORSLOG="/var/log/xpl/xpl-logger.log"
SENSORSDIR="/var/www"
SENSORGRAPH="${TYPE}_${DEVICE}.png"		# Fichier graphe généré temp_28.2CAED7010000.png
 
NBDATA="3000"					# Nombre de lignes de données
 
# ------------------------------------------------------------------------------
case "$TYPE" in
 temp)
	XTITLE="Température"
        ;;
 humidity)
	XTITLE="Humidité"
        ;;
 luminosity)
	XTITLE="Luminosité"
        ;;
 uv)
	XTITLE="Rayonnement solaire"
        ;;
 water)
	XTITLE="eau"
        ;;
 power)
	XTITLE="Puissance"
        ;;
 voltage)
	XTITLE="Tension"
        ;;
 *)
	XTITLE=$TYPE
        ;;
esac
 
 
# -----------------------------------------------------------------------------
IFS="\n"
DATA=$(grep $DEVICE $SENSORSLOG | grep $TYPE | tail -${NBDATA} | awk '{print $1, $2 ";" $13}' | sed 's/current=//g')
 
if [ -z "$DATA" ]
then
	echo "Pas de données valides !."
	exit 1
fi	
 
 
FIRSTDATETIME=$(echo $DATA | head -1 | awk -F',' '{print $1}' | awk -F';' '{print $1}')
CURDATETIME=$(echo $DATA  | tail -1 | awk -F',' '{print $(NF-1)}' | awk -F';' '{print $1}')
CURVALUE=$(echo $DATA | tail -1 | awk -F',' '{print $(NF-1)}' | awk -F';' '{print $2}')
CURTIME=$(echo $CURDATETIME | awk -F' ' '{print substr($2,1,5)}')
CURDATE=$(echo $CURDATETIME | awk -F' ' '{print $1}' | awk -F'-' '{printf "%d/%d/%d", $3, $2, $1}')		# 9/4/2014
MINVALUE=$(LANG=C; echo $DATA | sort -t';' -n -k2 -r | tail -1 | awk -F';' '{print $2}')
MAXVALUE=$(LANG=C; echo $DATA | sort -t';' -n -k2 | tail -1 | awk -F';' '{print $2}')
 
[ $(echo "$MAXVALUE > 20" | bc -l) -eq 1 ]  &&  LINE1=", 20 lc rgb \"purple\" title \"20°C\""
[ $(echo "$MAXVALUE > 10 && $MINVALUE < 10" | bc -l) -eq 1 ]  &&  LINE2=", 10 lc rgb \"blueviolet\" title \"10°C\""
[ $(echo "$MINVALUE < 0" | bc -l) -eq 1 ]  &&  LINE3=", 0 lc rgb \"blue\" title \"0°C\""
 
 
 
# echo "Start gnuplot ..."
/usr/bin/gnuplot <<_EOF
# gnuplot
set locale "fr_FR.UTF-8"
set terminal png size 800,400 enhanced font 'Verdana,8'
set output '$SENSORSDIR/$SENSORGRAPH'
set grid
set xdata time
set ydata
set datafile separator ";"
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%a\n%H:%M"
set format y "%.1f"
set mytics 5
set mxtics 6
set tics scale 3,1
set title "${TITLE}" font 'Verdana,12'
set key reverse left box
set xlabel "Courante: ${CURVALUE}${UNIT},   Min: ${MINVALUE}${UNIT},   Max: ${MAXVALUE}${UNIT}\nDernier relevé le  $CURDATE à $CURTIME" font 'Verdana,10'
set xrange [ "$FIRSTDATETIME" : "$CURDATETIME" ]
set ylabel "$DEVICE / $TYPE  ($UNIT) "
set autoscale y
set colorbox default
plot '-' using 1:2 with line lc rgb "$GRAPHCOLOR" title "$XTITLE" $LINE1 $LINE2 $LINE3
	$DATA
	EOF
_EOF
 
chmod 644 "$SENSORSDIR/$SENSORGRAPH"
exit 0