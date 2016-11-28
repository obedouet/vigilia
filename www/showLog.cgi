#!/bin/bash
#
# VIGILIA PROJECT - Fonction d'affichage des logs
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
###################################################################"
#
# charge environnement VIGILIA
. /etc/vigilia/base.cfg

# Chargement des variables d'env ---------------------------------------
VIGILIA_DIR=${VIGILIA_BIN}
DOTD=`date +%Y%m%d`

WWW_REP=${VIGILIA_DIR}/www

#
# 
# Parse les arguments
#
# Methode sur binaire externe
#if [ "${REQUEST_METHOD}" = "GET" ];
#then
#	eval `echo "${QUERY_STRING}" | ${WWW_REP}/parse`;
#fi
#if [ "${REQUEST_METHOD}" = "POST" ];
#then
#	eval `${WWW_REP}/parse "${CONTENT_LENGTH}"`;
#fi
# Methode bash
. ${WWW_REP}/urlcoder.sh
cgi_getvars BOTH ALL


if [ -n "${TYPE}" ]
then
	# En-tete
	#
	echo 'Content-type:text/html';
	echo '';
	cat ${VIGILIA_DIR}/html/head

	if [ "${TYPE}" = "MTR" ]
	then
		echo " <table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" width=\"100%\" id=\"main_table\" class=\"display\">";
		echo " <thead><tr><th>Path Num</th>";
		echo " <th>Node</th>";
		echo " <th>Drop Rate</th>";
		echo " <th>Sent</th>";
		echo " <th>Last</th>";
		echo " <th>Avg</th>";
		echo " <th>Best</th>";
		echo " <th>Wrst</th>";
		echo " <th>StDev</th>";
		echo " </thead><tbody>";
		cat ${VIGILIA_BASE}/analyse/global/path_drop_worst_cumul.${DOTD} | while read LINE
		do
		       echo "<tr>";
		       echo $LINE | awk '{printf("<td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td>\n",$1,$2,$3,$4,$5,$6,$7,$8,$9)}'
		       echo "</tr>";
		done
		echo " </tbody></table>";
	elif [ "${TYPE}" = "MTR_ERR" ]
	then
		if [ -n "${SITE}" -a `echo $SITE | grep ${VIGILIA_BASE}` ]
		then
			echo "<pre>";
			cat ${SITE} 
			echo "</pre>";
		fi
	elif [ "${TYPE}" = "WGET_LOG" ]
	then
		if [ -n "${SITE}" ]
		then
			echo "<pre>";
			cat ${VIGILIA_SPOOL}/http/${SITE}
			echo "</pre>";
		fi
	fi

	echo " </BODY> ";
	echo " </HTML>";
elif [ -n "${REQUEST}" ]
then
	# En-tete
	#
	echo 'Content-type:text/html';
	echo '';
	echo "<pre>";
	host $REQUEST
	echo "<ul>";
	whois $REQUEST
	echo "</pre>";
fi

