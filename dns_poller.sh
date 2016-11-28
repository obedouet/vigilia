#!/bin/bash
#
# VIGILIA PROJECT
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

if [ -n "$1" ]
then
	# $1 is the SITE aka DNS to test

	# Lock
	[ -f ${VIGILIA_SPOOL}/dns/$1.lck ] && exit 1
	touch ${VIGILIA_SPOOL}/dns/$1.lck
	echo $$ > ${VIGILIA_SPOOL}/dns/$1.lck

	if [ -n "$2" ]
	then
		# Ask DNS the domain specified
		time host $2 $1
	else
		# Ask DNS it own name
		time host $1 $1
	fi
fi
