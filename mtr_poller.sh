#!/bin/bash
#
# VIGILIA PROJECT - Poller MTR
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

[ ! -d ${VIGILIA_SPOOL}/mtr ] && mkdir ${VIGILIA_SPOOL}/mtr

if [ -z "$1" ]
then
	echo "ERREUR: argument manquant"
	exit 1
else
	SITE=$1
	echo $$ > ${VIGILIA_SPOOL}/mtr/${SITE}.lck
	${MTR_BIN} ${MTR_OPT} $1 > ${VIGILIA_SPOOL}/mtr/${SITE}
	rm -f ${VIGILIA_SPOOL}/mtr/${SITE}.lck
fi
