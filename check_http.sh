#!/bin/bash
#
# VIGILIA PROJECT - Analyseur des resultats HTTP & DNS
#
# Copyright 2014-2015 - Olivier BEDOUET
#
# ------------------------------------------------------------------------
#    This file is part of VIGILIA.
#
#    VIGILIA is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    VIGILIA is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with VIGILIA.  If not, see <http://www.gnu.org/licenses/>.
# ------------------------------------------------------------------------
#

. /etc/vigilia/base.cfg

DOTD=`date +%Y%m%d%H%M`

cat /etc/vigilia/target.cfg | while read LINE
do
	SITE=`echo $LINE | awk '{print $1}'`

	# Verifie si un resultat DNS est disponible
	if [ -f ${VIGILIA_SPOOL}/dns/${SITE} ]
	then
		# Commence le traitement
		[ ! -d ${VIGILIA_BASE}/analyse/$SITE ] && mkdir ${VIGILIA_BASE}/analyse/$SITE

		# Cree les bases RRDTOOL si necessaire
		if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/dns_time.rrd ]
		then
			${VIGILIA_BIN}/rrd_create.sh $SITE dns_time 600 60 >> /tmp/vigilia.log
		fi

		IS_TIMEOUT=`grep timed ${VIGILIA_SPOOL}/dns/${SITE}`
		if [ -n "$IS_TIMEOUT" ]
		then
			${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/dns_time.rrd N:0 >> /tmp/vigilia.log
		else
			TIME_VALUE=`grep real ${VIGILIA_SPOOL}/dns/${SITE} | awk -Fm '{print $2}' | awk -Fs '{print $1}'`
			${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/dns_time.rrd N:${TIME_VALUE} >> /tmp/vigilia.log
		fi
	fi

	# Verifie si un resultat HTTP est disponible
	if [ -f ${VIGILIA_SPOOL}/http/${SITE} -a ! -f ${VIGILIA_SPOOL}/http/${SITE}.lck ]
	then

		# Commence le traitement
		[ ! -d ${VIGILIA_BASE}/analyse/$SITE ] && mkdir ${VIGILIA_BASE}/analyse/$SITE

		# Cree les bases RRDTOOL si necessaire
		if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd ]
		then
			${VIGILIA_BIN}/rrd_create.sh $SITE netstat_error 86400 10 >> /tmp/vigilia.log
		fi
		
		if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/http_time.rrd ]
		then
			${VIGILIA_BIN}/rrd_create.sh $SITE http_time 600 100000000000 >> /tmp/vigilia.log
		fi

		if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/http_speed.rrd ]
		then
			${VIGILIA_BIN}/rrd_create.sh $SITE http_speed 600 100000000000 >> /tmp/vigilia.log
		fi

		# Recupere le debit calcule par wget RAW_SPEED=(vitesse unite)
		# Cas 1: download multiple
		RAW_SPEED=`cat ${VIGILIA_SPOOL}/http/${SITE} | grep Downloaded | awk '{print $7, $8}'`
		if [ -z "$RAW_SPEED" ]
		then
			# Cas 2: 1 seul download
			RAW_SPEED=`cat ${VIGILIA_SPOOL}/http/${SITE} | grep saved | awk '{print $3,$4}'`
		fi
		SPEED=`echo $RAW_SPEED | awk '{print $1}' | tr '(' ' '`
		UNIT=`echo $RAW_SPEED | grep KB`
		if [ -n "$UNIT" ]
		then
			# KB
			WGET_SPEED=`echo $SPEED*1024 | bc`
		else
			UNIT=`echo $RAW_SPEED | grep MB`
			if [ -n "$UNIT" ]
			then
				WGET_SPEED=`echo $SPEED*1048576 | bc`
			fi
		fi

		# Si un debit est dispo, on l'enregistre ainsi que son temps de chargement
		if [ -n "$WGET_SPEED" ]
		then
			${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_speed.rrd N:${WGET_SPEED} >> /tmp/vigilia.log

			# Temp de chargement
			if [ -f ${VIGILIA_SPOOL}/http/${SITE}.time ]
			then
				# Stocke le temps de chargement
				TIME_VALUE=`cat ${VIGILIA_SPOOL}/http/${SITE}.time`
				${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_time.rrd N:${TIME_VALUE} >> /tmp/vigilia.log
			fi
		else
			# Erreur sur download
			${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_speed.rrd N:0 >> /tmp/vigilia.log
			${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_time.rrd N:0 >> /tmp/vigilia.log
		fi

		if [ -f ${VIGILIA_SPOOL}/http6/${SITE}.time ]
		then
			# IPv6
			if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/http6_time.rrd ]
			then
				${VIGILIA_BIN}/rrd_create.sh $SITE http6_time 600 100000000000 >> /tmp/vigilia.log
			fi

			# Stocke le temps de chargement
			TIME_VALUE=`cat ${VIGILIA_SPOOL}/http6/${SITE}.time`
			${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http6_time.rrd N:${TIME_VALUE} >> /tmp/vigilia.log

			rm -f ${VIGILIA_SPOOL}/http6/${SITE}.time
		fi
		
		# Erreurs TCP
		if [ -f ${VIGILIA_SPOOL}/http/${SITE}.netstat ]
		then
			# Cherche les erreurs TCP
			grep 'timeout' ${VIGILIA_SPOOL}/http/${SITE}.netstat  > /tmp/http.$$
			grep 'retr' ${VIGILIA_SPOOL}/http/${SITE}.netstat  >> /tmp/http.$$
			grep 'Drop' ${VIGILIA_SPOOL}/http/${SITE}.netstat  >> /tmp/http.$$
			if [ `wc -l /tmp/http.$$ | awk '{print $1}'` -gt 0 ]
			then
				NB_ERR=`wc -l /tmp/http.$$ | awk '{print $1}'`
				NB_ERR=`expr $NB_ERR / 2`
				rm -f /tmp/http.$$
				${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd N:$NB_ERR >> /tmp/vigilia.log
			else
				${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd N:0 >> /tmp/vigilia.log
				rm -f /tmp/http.$$
			fi
		fi
	elif [ -f ${VIGILIA_SPOOL}/http/${SITE}.lck ]
	then
		# Timeout
		kill `ps auxw | grep ${SITE} | grep -v grep | awk '{print $2}'`
		rm -f ${VIGILIA_SPOOL}/http/${SITE}.lck
		[ ! -d ${VIGILIA_BASE}/analyse/$SITE ] && mkdir ${VIGILIA_BASE}/analyse/$SITE
		cat ${VIGILIA_SPOOL}/mtr/$SITE > ${VIGILIA_BASE}/analyse/$SITE/http.timeout.$DOTD

		if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/http_time.rrd ]
		then
			${VIGILIA_BIN}/rrd_create.sh $SITE http_time 600 100000000000 >> /tmp/vigilia.log
		fi

		# Value = 0
		${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_time.rrd N:0 >> /tmp/vigilia.log
		${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_speed.rrd N:0 >> /tmp/vigilia.log
	elif [ -f ${VIGILIA_SPOOL}/http6/${SITE}.lck ]
	then
		# Timeout
		kill `ps auxw | grep ${SITE} | grep -v grep | awk '{print $2}'`
		rm -f ${VIGILIA_SPOOL}/http6/${SITE}.lck
		[ ! -d ${VIGILIA_BASE}/analyse/$SITE ] && mkdir ${VIGILIA_BASE}/analyse/$SITE
		echo timeout > ${VIGILIA_BASE}/analyse/$SITE/http6.timeout.$DOTD

		if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/http6_time.rrd ]
		then
			${VIGILIA_BIN}/rrd_create.sh $SITE http6_time 600 100000000000 >> /tmp/vigilia.log
		fi

		# Value = 0
		${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http6_time.rrd N:0 >> /tmp/vigilia.log

	fi
done

# Est-il 00h05 ?
if [ ${DOTD} -gt `date +%Y%m%d`0000 -a ${DOTD} -lt `date +%Y%m%d`0010 ]
then
	# Traitement journalier
	[ ! -d ${VIGILIA_BASE}/analyse/global ] && mkdir ${VIGILIA_BASE}/analyse/global
	find ${VIGILIA_BASE}/analyse/ -name "http.timeout.*" > ${VIGILIA_BASE}/analyse/global/http_all_timeout.`date +%Y%m%d`
	find ${VIGILIA_BASE}/analyse/ -name "http.timeout.*" -exec rm -f {} \;
	find ${VIGILIA_BASE}/analyse/ -name "http6.timeout.*" -exec rm -f {} \;
fi
