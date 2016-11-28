#!/bin/bash
#
# VIGILIA PROJECT - Global poller
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


. /etc/vigilia/base.cfg

DOTD=`date +%Y%m%d%H%M`
TOTD=`date +%H%M`
MIN_NOW=`date +%M`

cat /etc/vigilia/target.cfg | while read LINE
do
	SITE=`echo $LINE | awk '{print $1}'`
	METHOD=`echo $LINE | awk '{print $3}'`
	if [ "$METHOD" = "tcp" -a -n "${TCPPING_BIN}" ]
	then
		# tcpping on specified port
		[ ! -d ${VIGILIA_SPOOL}/tcpping ] && mkdir ${VIGILIA_SPOOL}/tcpping
		TCP_PORT=`echo $LINE | awk '{print $4}'`
		${TCPPING_BIN} -c5 -p ${TCP_PORT} ${SITE} > ${VIGILIA_SPOOL}/tcpping/${SITE} &
	elif [ "$METHOD" = "dns" ]
	then
		# DNS request
		QRY_DOMAIN=`echo $LINE | awk '{print $4}'`
		[ ! -d ${VIGILIA_SPOOL}/dns ] && mkdir ${VIGILIA_SPOOL}/dns

		if [ -f ${VIGILIA_SPOOL}/dns/${SITE}.lck ]
		then
			kill `ps auxw | grep ${SITE} | grep -v grep | awk '{print $2}'`
			rm -f ${VIGILIA_SPOOL}/dns/${SITE}.lck
		fi
		${VIGILIA_BIN}/dns_poller.sh $SITE ${QRY_DOMAIN} > ${VIGILIA_SPOOL}/dns/${SITE} 2>&1 &
	elif [ "$METHOD" = "http" ]
	then
		if [ -f ${VIGILIA_SPOOL}/http/${SITE}.lck ]
		then
			kill `ps auxw | grep ${SITE} | grep -v grep | awk '{print $2}'`
			rm -f ${VIGILIA_SPOOL}/http/${SITE}.lck
			touch ${VIGILIA_BASE}/analyse/${SITE}/http.timeout.${DOTD}
			${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_speed.rrd N:0 >> /tmp/vigilia.log
                        ${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http_time.rrd N:0 >> /tmp/vigilia.log
		fi
		if [ -f ${VIGILIA_SPOOL}/http6/${SITE}.lck ]
		then
			kill `ps auxw | grep ${SITE} | grep -v grep | awk '{print $2}'`
			rm -f ${VIGILIA_SPOOL}/http6/${SITE}.lck
			touch ${VIGILIA_BASE}/analyse/${SITE}/http6.timeout.${DOTD}
                        ${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/http6_time.rrd N:0 >> /tmp/vigilia.log
		fi

		# HTTP request
		${VIGILIA_BIN}/http_poller.sh ${SITE} &

		IPV6=`host -t aaaa $SITE 2>/dev/null`
		if [ `echo $IPV6 | grep IPv6 | wc -l` -eq 1 ]
		then
			${VIGILIA_BIN}/http_poller.sh ${SITE} v6 &
		fi

		sleep 1
	fi

	# Every 15 minutes
	if [ ${MIN_NOW} -eq 0 -o ${MIN_NOW} -eq 15 -o ${MIN_NOW} -eq 30 -o ${MIN_NOW} -eq 45 ]
	then
		if [ "$METHOD" = "youtube" ]
		then
			# Youtube-dl
			${VIGILIA_BIN}/youtube_poller.sh ${SITE} &
		else
			# Perform a traceroute
			[ ! -d ${VIGILIA_SPOOL}/mtr ] && mkdir ${VIGILIA_SPOOL}/mtr
			${VIGILIA_BIN}/mtr_poller.sh ${SITE} &
		fi
	fi

done

