#!/bin/bash
#
# VIGILIA PROJECT - Tcpping poller
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

cat /etc/vigilia/target.cfg | while read LINE
do
	SITE=`echo $LINE | awk '{print $1}'`
	METHOD=`echo $LINE | awk '{print $3}'`
	if [ "$METHOD" = "tcp" -a "$SITE" = "$1" ]
	then
		TCP_PORT=`echo $LINE | awk '{print $4}'`
		${TCPPING_BIN} -c5 -p ${TCP_PORT} ${SITE} > ${VIGILIA_SPOOL}/tcpping/${SITE} &
	fi
done
