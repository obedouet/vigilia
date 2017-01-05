#!/bin/bash
#
# Projet VIGILIA - Installer
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

# Emplacement des donnees de travail
VIGILIA_BASE=/var/spool/vigilia
VIGILIA_BIN=/home/vigilia
# Emplacement de la distrib
URL=http://baddy.free.fr/vigilia/distrib.tgz
URL_TARGET=http://baddy.free.fr/vigilia/target.cfg
URL_AGENT=http://baddy.free.fr/vigilia/useragent.parm

echo "Verifie pre-requis..."
if [[ $(id -u) -ne 0 ]]
then
	echo "Desole il faut etre root pour lancer ce script :("
	exit 1
fi

echo -n "rrdtool: "
RRDTOOL_BIN=`which rrdtool 2>&1`
if [ -z "${RRDTOOL_BIN}" -o "`echo ${RRDTOOL_BIN} | awk '{print $2}'`" = "no" ]
then
	echo "introuvable"
	echo -n "Indiquez le chemin (exemple: /usr/bin): "
	read RRD_BIN
	if [ -z "$RRD_BIN" -o ! -d '${RRD_BIN}' -o ! -x ${RRD_BIN}/rrdtool ]
	then
		echo "Chemin non valable"
		exit 1
	fi
else
	RRD_BIN=`echo $RRDTOOL_BIN | awk -F/ '{for (i=2;i<NF;i++){printf("/%s",$i)}}'`
	echo "ok ($RRD_BIN)"
fi

echo -n "tcpping (optionnel): "
TCPPING_BIN=`which tcpping 2>&1`
if [ -z "${TCPPING_BIN}" -o "`echo ${TCPPING_BIN} | awk '{print $2}'`" = "no" ]
then
	echo "introuvable"
else
	echo "ok ($TCPPING_BIN)"
fi

echo -n "mtr: "
MTR_BIN=`which mtr 2>&1`
if [ -z "${MTR_BIN}" -o "`echo ${MTR_BIN} | awk '{print $2}'`" = "no" ]
then
	echo "introuvable"
	echo -n "Indiquez le chemin complet (exemple: /usr/bin/mtr): "
	read MTR_BIN
	if [ -z "$MTR_BIN" -o ! -x ${MTR_BIN} ]
	then
		echo "Chemin non valable"
		exit 1
	fi
else
	echo "ok ($MTR_BIN)"
fi

echo -n "wget: "
WGET_BIN=`which mtr 2>&1`
if [ -z "${WGET_BIN}" -o "`echo ${WGET_BIN} | awk '{print $2}'`" = "no" ]
then
	echo "introuvable"
else
	echo "OK"
fi

echo "Pre-requis OK."

echo "Recapitulatif configuration: "
echo "Donnees: ${VIGILIA_BASE}"
echo "Scripts: ${VIGILIA_BIN}"
echo "MTR: ${MTR_BIN}"
echo "rrdtool: ${RRD_BIN}"
[ -n "$TCPPING_BIN" ] && echo "tcpping: $TCPPING_BIN"

echo "Confirmez (O/n):"
read REP
if [ "$REP" = "n" ]
then
	echo "Abandon."
	exit 1
fi

#
# DEBUT TACHES
#

# Verifie si le user n'existe pas (exemple: relance du script)
if [ ! -d /home/vigilia ]
then
	echo -n "Creation user vigilia: "
	useradd -d /home/vigilia -m vigilia
	if [ ! -d /home/vigilia ]
	then
		echo "Erreur creation home dir :( "
		exit 1
	fi
	echo "OK"
fi

if [ ! -d ${VIGILIA_BASE} ]
then
	echo -n "Creation ${VIGILIA_BASE}: "
	mkdir ${VIGILIA_BASE}
	if [ ! -d ${VIGILIA_BASE} ]
	then
		echo "Erreur creation ${VIGILIA_BASE} :'("
		exit 1
	else
		mkdir ${VIGILIA_BASE}/spooler
		mkdir ${VIGILIA_BASE}/analyse
		chown -R vigilia ${VIGILIA_BASE}
		echo "OK"
	fi
else
	echo "Base VIGILIA deja presente"
	chown -R vigilia ${VIGILIA_BASE}
fi

if [ ! -d /etc/vigilia ]
then
	echo -n "Creation /etc/vigilia: "
	mkdir /etc/vigilia
	if [ ! -d /etc/vigilia ]
	then
		echo "Erreur :'("
		exit 1
	fi
	echo "OK"
else
	echo "Vigilia semble deja present, souhaitez-vous conserver les reglages ?"
	echo -n "(O/n):"
	read REP
	if [ "$REP" = "n" ]
	then
		echo "Suppression des reglages"
		rm -fr /etc/vigilia
		mkdir /etc/vigilia
	fi
fi

if [ ! -f /etc/vigilia/base.cfg ]
then
	# Creation du fichier de preference
	echo "VIGILIA_BASE=${VIGILIA_BASE}" > /etc/vigilia/base.cfg
	echo "VIGILIA_SPOOL=${VIGILIA_BASE}/spooler" >> /etc/vigilia/base.cfg
	echo "VIGILIA_BIN=${VIGILIA_BIN}" >> /etc/vigilia/base.cfg
	echo "MTR_BIN=${MTR_BIN}" >> /etc/vigilia/base.cfg
	echo "MTR_OPT=\"-4rwnc 10\"" >> /etc/vigilia/base.cfg
	[ -n "$TCPPING_BIN" ] && echo "TCPPING_BIN=${TCPPING_BIN}" >> /etc/vigilia/base.cfg
	echo "RRD_BIN=${RRD_BIN}" >> /etc/vigilia/base.cfg
	echo "RRD_REP=${VIGILIA_BASE}/analyse" >> /etc/vigilia/base.cfg
	echo "RESUME=yes" >> /etc/vigilia/base.cfg
fi

if [ ! -f COPYING ]
then
	echo "Download de la distrib: ${URL}"
	cd /home/vigilia
	[ -f distrib.tgz ] && rm -f distrib.tgz
	wget -q ${URL}
	if [ ! -f distrib.tgz ]
	then
		echo "Arg le telechargement de distrib.tgz a plante :("
		exit 1
	fi
	echo -e "\033[0;32mOK\033[0m on detargz !"
	tar xfz distrib.tgz
	if [ ! -f COPYING ]
	then
		echo "Mais euuuh detar distrib.tgz pas marche !"
		exit 1
	fi
	chmod 777 www/img
fi

if [ ! -f /etc/vigilia/target.cfg ]
then
	echo "Download des sites web a poller: ${URL_TARGET}"
	wget -q -O /etc/vigilia/target.cfg ${URL_TARGET}
	if [ ! -f /etc/vigilia/target.cfg ]
	then
		echo "Mais euuuh le telechargement des sites a poller a rate !"
		exit 1
	fi
else
	echo "Mettre a jour la liste des sites Web ? (O/n)"
	read REP
	if [ "$REP" != "n" -o "$REP" = "o" -o "$REP" = "O" -o -z "$REP" ]
	then
		wget -q -O /etc/vigilia/target.cfg ${URL_TARGET}
	fi
fi

if [ ! -f /etc/vigilia/useragent.parm ]
then
	echo "Download du User-Agent: ${URL_AGENT}"
	wget -q -O /etc/vigilia/useragent.parm ${URL_AGENT}
	if [ ! -f /etc/vigilia/useragent.parm ]
	then
		echo "Mais euuuh le telechargement des user agent a rate !"
		exit 1
	fi
fi

echo -e "\033[0;31mTout est pret, ajoutez dans la crontab du user vigilia les lignes suivantes :\033[0m"
echo "*/5 * * * * ${VIGILIA_BIN}/vigilia_poller.sh && ${VIGILIA_BIN}/check_http.sh"
echo "2,17,32,47 * * * * ${VIGILIA_BIN}/check_mtr.sh"
echo
echo "Pour rajouter dans le cron de l'utilisateur vigilia, faire en root:"
echo "# crontab -e -u vigilia"
echo
echo "Dans le dossier apache, vous trouverez un exemple de configuration :)"

