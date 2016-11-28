#!/bin/bash

. /etc/vigilia/base.cfg

cat /etc/vigilia/target.cfg | while read LINE
do
        SITE=`echo $LINE | awk '{print $1}'`
	echo "SITE=$SITE"

	if [ -n "$1" -a "$SITE" != "$1" ]
	then
		continue
	fi

	rm -f ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd

	if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd ]
	then
		/outils/vigilia/rrd_create.sh $SITE netstat_error 86400 10
	fi

	NB_DATA=0
	NB_FILE=100
	ls ${VIGILIA_BASE}/analyse/$SITE/netstat.errors.* | sort | awk -F/ '{print $7}' | awk -F. '{print $3}' | while read ERR_DATE
	#while read ERR_DATE
	do
		#CONV_DATE=`echo $ERR_DATE | awk -F/ '{print $7}' | awk -F. '{print $3}'`
		#OLD_DATE=`/projets/date2int $CONV_DATE`
		OLD_DATE=`/projets/date2int $ERR_DATE`
		#${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd $OLD_DATE:1
		#echo rm -f ${VIGILIA_BASE}/analyse/$SITE/netstat.errors.$ERR_DATE
		echo $OLD_DATE:1 >> /tmp/data
		NB_DATA=`expr $NB_DATA + 1`
		if [ $NB_DATA -gt 8 ]
		then
			mv /tmp/data /tmp/data.$NB_FILE
			NB_FILE=`expr $NB_FILE + 1`
			NB_DATA=0
		fi

	#done < <(ls ${VIGILIA_BASE}/analyse/$SITE/netstat.errors.* | sort | awk -F/ '{print $7}' | awk -F. '{print $3}' )
	done 

	ls /tmp/data.* | while read DATA_FILE
	do
		echo ${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd `cat $DATA_FILE`
		${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd `cat $DATA_FILE`
	done
	echo ${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd `cat /tmp/data`
	${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd `cat /tmp/data`

	chown vigilia:users ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd

	rm -f /tmp/data
	rm -f /tmp/data.*
done
