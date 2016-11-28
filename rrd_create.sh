#!/bin/bash
#
# VIGILIA PROJECT - Creation des fichiers RRD
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

_STEP=300
_HEARTBEAT=900
_MAX=256

. /etc/vigilia/base.cfg

if [ -z "$1" -a -z "$2" ]
then
	echo "Usage: $0 <site> <database> [heartbeat] [max value]"
	exit 1
fi

if [ -n "$3" ]
then
	_HEARTBEAT=$3
fi
if [ -n "$4" ]
then
	_MAX=$4
fi

${RRD_BIN}/rrdtool create ${RRD_REP}/$1/$2.rrd --start 1416000000 --step ${_STEP} \
DS:data:GAUGE:${_HEARTBEAT}:0:${_MAX} \
RRA:AVERAGE:0.5:1:600 \
RRA:AVERAGE:0.5:6:700 \
RRA:AVERAGE:0.5:24:775 \
RRA:AVERAGE:0.5:288:797 \
RRA:MAX:0.5:1:600 \
RRA:MAX:0.5:6:700 \
RRA:MAX:0.5:24:775 \
RRA:MAX:0.5:288:797

