#!/bin/bash
#
# VIGILIA PROJECT - Poller HTTP
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


HTTPS_OPT='--no-check-certificate'
WGET_OPT='-4 -O /dev/null'
#REPORT_OPT='--report-speed=bits --progress=dot:mega'
REPORT_OPT='--progress=dot:mega'
MODE=http

# Pour utiliser un proxy
#export http_proxy=http://10.1.6.1:8080
#export https_proxy=http://10.1.6.1:8080

[ -n "$LANG" ] && unset LANG

. /etc/vigilia/base.cfg

if [ -z "$1" ]
then
	echo "ERROR: $0 <site>"
	exit 1
else
	SITE=$1
fi

if [ -n "$2" ]
then
	if [ "$2" = "v6" ]
	then
		MODE=http6
		WGET_OPT='-6 -O /dev/null'
	fi
fi

HTTP_OPT=`grep $SITE /etc/vigilia/target.cfg | awk '{print $4}'`
if [ "$HTTP_OPT" = "load_all" ]
then
	RECUR_OPT='-P /tmp/www -H -p --exclude-domains xiti.com,nexus.ensighten.com,doubleclick.net,webtrendslive.com,google-analytics.com'
	WGET_OPT='-4'
	[ ! -d /tmp/www ] && mkdir /tmp/www
fi

_useragt=`cat /etc/vigilia/useragent.parm`

# Creation d'un verrou
[ ! -d ${VIGILIA_SPOOL}/${MODE} ] && mkdir ${VIGILIA_SPOOL}/${MODE}
[ -f ${VIGILIA_SPOOL}/${MODE}/${SITE}.lck ] && exit 1
touch ${VIGILIA_SPOOL}/${MODE}/${SITE}.lck
echo $$ > ${VIGILIA_SPOOL}/${MODE}/${SITE}.lck

# Stats TCP
netstat -s --tcp > ${VIGILIA_SPOOL}/${MODE}/${SITE}.netstat1

# Heure avant execution
START_TIME=`date +%s%N`

wget ${WGET_OPT} ${RECUR_OPT} ${REPORT_OPT} ${HTTPS_OPT} -U "${_useragt}" http://${SITE} > ${VIGILIA_SPOOL}/${MODE}/${SITE} 2>&1

# Heure post execution
STOP_TIME=`date +%s%N`

# Stats TCP
netstat -s --tcp > ${VIGILIA_SPOOL}/${MODE}/${SITE}.netstat2

# Enregistre les differences
diff ${VIGILIA_SPOOL}/${MODE}/${SITE}.netstat1 ${VIGILIA_SPOOL}/${MODE}/${SITE}.netstat2 > ${VIGILIA_SPOOL}/${MODE}/${SITE}.netstat
rm -f ${VIGILIA_SPOOL}/${MODE}/${SITE}.netstat1
rm -f ${VIGILIA_SPOOL}/${MODE}/${SITE}.netstat2

# Libere le verrou
rm -f ${VIGILIA_SPOOL}/${MODE}/${SITE}.lck

if [ "$HTTP_OPT" = "load_all" ]
then
	rm -fr /tmp/www/*
fi

# Calcule le temps total
total_time=`expr ${STOP_TIME} - ${START_TIME}`
echo $total_time > ${VIGILIA_SPOOL}/${MODE}/${SITE}.time


