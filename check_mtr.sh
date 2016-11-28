#!/bin/bash
#
# VIGILIA PROJECT - Analyseur des resultats MTR
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

[ ! -d ${VIGILIA_BASE}/analyse/global ] && mkdir ${VIGILIA_BASE}/analyse/global

cat /dev/null > ${VIGILIA_BASE}/analyse/global/all_path_drop

cat /etc/vigilia/target.cfg | while read LINE
do
	SITE=`echo $LINE | awk '{print $1}'`

	# Verifie si un resultat est disponible
	if [ -f ${VIGILIA_SPOOL}/mtr/${SITE} -a ! -f ${VIGILIA_SPOOL}/mtr/${SITE}.lck ]
	then
		# Retire l'en-tete du nombre de ligne
		FILE_LINE=`cat ${VIGILIA_SPOOL}/mtr/${SITE} | wc -l`
		TGT_LINE=`expr ${FILE_LINE} - 2`
		if [ $TGT_LINE -gt 0 ]
		then
			cat ${VIGILIA_SPOOL}/mtr/${SITE} | tail -${TGT_LINE} > /tmp/mtr.$$
		else
			# Pour traiter les cas ou MTR a echoue
			echo "$0: mtr en defaut (SITE=$SITE, FILELINE=$FILELINE)" >> /tmp/vigilia.log
			touch /tmp/mtr.$$
		fi

		# Commence le traitement
		[ ! -d ${VIGILIA_BASE}/analyse/$SITE ] && mkdir ${VIGILIA_BASE}/analyse/$SITE
		
		# Analyse du path ====================================================================
		cat /tmp/mtr.$$ | awk '{print $2}' > ${VIGILIA_BASE}/analyse/$SITE/last_path

		[ ! -f ${VIGILIA_BASE}/analyse/$SITE/ref_path ] && cp ${VIGILIA_BASE}/analyse/$SITE/last_path ${VIGILIA_BASE}/analyse/$SITE/ref_path

		# Qualite du path ===============================================================
		cat /tmp/mtr.$$ | awk '{if ($3 !="0.0%" && $3 !="100.0" && $4 == 10){print $0}}' > ${VIGILIA_BASE}/analyse/$SITE/last_path_drop

		if [ ! -f ${VIGILIA_BASE}/analyse/$SITE/path_nb_hop.rrd ]
		then
			# Creation du fichier RRD
			${VIGILIA_BIN}/rrd_create.sh $SITE path_nb_hop 1800 >> /tmp/vigilia.log
		fi

		#PATH_NB_HOP=`wc -l ${VIGILIA_BASE}/analyse/$SITE/last_path | awk '{print $1}'`
		PATH_NB_HOP=`tail -1 ${VIGILIA_SPOOL}/mtr/${SITE} | awk -F. '{print $1}' | awk '{print $1}'`
		${RRD_BIN}/rrdtool update ${VIGILIA_BASE}/analyse/$SITE/path_nb_hop.rrd N:${PATH_NB_HOP} >> /tmp/vigilia.log

		if [ -n "${PATH_NB_HOP}" -a ${PATH_NB_HOP} -lt 4 -o -n "$TGT_LINE" -a $TGT_LINE -le 0 ]
		then
			mv ${VIGILIA_SPOOL}/mtr/${SITE} ${VIGILIA_BASE}/analyse/$SITE/mtr_error.${DOTD}
		fi

		cat ${VIGILIA_BASE}/analyse/$SITE/last_path_drop >> ${VIGILIA_BASE}/analyse/global/all_path_drop

		rm -f /tmp/mtr.$$
	elif [ -f ${VIGILIA_SPOOL}/mtr/${SITE}.lck ]
	then
		# MTR en erreur
		kill `ps auxw | grep ${SITE} | grep mtr | grep -v grep | awk '{print $2}'`
		if [ -f ${VIGILIA_SPOOL}/mtr/${SITE} ]
		then
			mv ${VIGILIA_SPOOL}/mtr/${SITE} ${VIGILIA_BASE}/analyse/$SITE/mtr_error.${DOTD}
		else
			echo timeout > ${VIGILIA_BASE}/analyse/$SITE/mtr_error.${DOTD}
		fi
		rm -f ${VIGILIA_SPOOL}/mtr/${SITE}.lck
	fi
done

# Traitement des drops vus par MTR --------------------------
# Tri 
cat ${VIGILIA_BASE}/analyse/global/all_path_drop | sort | uniq -c -w 15 > ${VIGILIA_BASE}/analyse/global/path_drop.${DOTD}

# Tri ceux entre 20% et 90%
cat ${VIGILIA_SPOOL}/mtr/* | awk '{if ($4==10){if ($3!="0.0%" && $3!="10.0%" && $3!="100.0"){print $0}}}' > ${VIGILIA_BASE}/analyse/global/path_drop_worst.`date +%Y%m%d%H%M`
cat ${VIGILIA_BASE}/analyse/global/path_drop_worst.* | sort > ${VIGILIA_BASE}/analyse/global/path_drop_worst_cumul

# Cumul des stats
cat ${VIGILIA_BASE}/analyse/global/path_drop.* | awk '{if ($1 > 1 && $4 != "100.0" && $5==10){print $3}}' | sort | uniq -c > ${VIGILIA_BASE}/analyse/global/path_drop_cumul
if [ ${DOTD} -gt `date +%Y%m%d`0000 -a ${DOTD} -lt `date +%Y%m%d`0010 ]
then
	# Archive journaliere
	mv ${VIGILIA_BASE}/analyse/global/path_drop_cumul ${VIGILIA_BASE}/analyse/global/path_drop_cumul.`date +%Y%m%d`
	# Efface les logs
	rm ${VIGILIA_BASE}/analyse/global/path_drop.*

	find ${VIGILIA_BASE}/analyse -name "mtr_error.*" -exec rm -f {} \;

	# Tri les pires cas
	cat ${VIGILIA_BASE}/analyse/global/path_drop_worst_cumul | awk '{print $2}' | uniq -c | awk '{if ($1 > 5){print $2}}' > ${VIGILIA_BASE}/analyse/global/path_drop_worst_best.`date +%Y%m%d`

	# Archive journaliere
	mv ${VIGILIA_BASE}/analyse/global/path_drop_worst_cumul ${VIGILIA_BASE}/analyse/global/path_drop_worst_cumul.`date +%Y%m%d`

	# Efface les logs
	rm ${VIGILIA_BASE}/analyse/global/path_drop_worst.*
	rm ${VIGILIA_SPOOL}/mtr/*
fi


