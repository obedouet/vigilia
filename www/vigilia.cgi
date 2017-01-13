#!/bin/bash
#
# VIGILIA PROJECT - Interface Web de Visualisation
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

DOTD=`date +%Y%m%d`

#
# charge environnement VIGILIA
. /etc/vigilia/base.cfg

VIGILIA_DIR=${VIGILIA_BIN}
WWW_REP=${VIGILIA_DIR}/www

# 
# Parse les arguments
#
. ${WWW_REP}/urlcoder.sh
cgi_getvars BOTH ALL

#
# Fonctions
. ${WWW_REP}/rrd_func.sh

if [ -n "$img" ]
then
	echo 'Content-type:image/png';
	echo '';
	case $period in
	"H24") start=86400
	;;
	"J7") start=7d
	;;
	"J30") start=30d
	;;
	*) start=86400
	esac
	if [ "$type" = "http_time" ]
	then
		http_time_graph pouet $img/http_time.rrd "${img} - HTTP Latency - Periode = ${period}" $start
	elif [ "$type" = "http6_time" ]
	then
		http_time_graph pouet $img/http6_time.rrd "${img} - HTTP IPv6 Latency - Periode = ${period}" $start
	elif [ "$type" = "http_speed" ]
	then
		http_speed_graph - $img/http_speed.rrd "${img} - HTTP Speed - Periode = ${period}" $start
	elif [ "$type" = "dns_time" ]
	then
		dns_time_graph "-" $img/dns_time.rrd "${img} - DNS Latency - Periode = $period" $start
	elif [ "$type" = "mtr_hops" ]
	then
		mtr_hops_graph - $img/path_nb_hop.rrd "${img} - MTR Hops - Periode = ${period}" $start
	elif [ "$type" = "netstat_errors" ]
	then
		netstat_errors_graph - $img/netstat_error.rrd "${img} - TCP errors - Periode = $period" $start
	elif [ "$type" = "resume_netstat" ]
	then
		make_graph_resume titre $start errors
	elif [ "$type" = "resume_http" ]
	then
		make_graph_resume titre $start http_time
	else
		echo 'unsupported type';
	fi
else
#
# En-tete
#
echo 'Content-type:text/html';
echo '';
cat ${VIGILIA_DIR}/html/head

# Corps
#
echo " <BODY bgcolor=\"#efefef\">";
echo " <TABLE border=\"0\" cellpadding=\"10\" cellspacing=\"0\"> ";
echo " <TR> ";
echo "  <TD class=\"menubar\" align=\"left\" width=\"130\" valign=\"top\"> ";
echo "  <P></P> ";

# Menu
#
echo " <P><B><a href=\"vigilia.cgi\">Graphes VIGILIA :</a></B>&nbsp;&nbsp;</P> ";
echo " <table width=\"100%\" class=\"menu\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\"> ";

#
# Liste des sites
cat /etc/vigilia/target.cfg | while read LINE
do
        SITE=`echo $LINE | awk '{print $1}'`

	echo -n " <tr><td class=\"menuitem\" colspan=\"2\">&nbsp;-&nbsp;<a class=\"menulink\" HREF=\"?target="; 

	echo -n $SITE

	echo -n "\">";

	echo -n $SITE

	echo " </a></td></tr> ";

done

echo " </table></p>";
echo " </td>";

#
# Graphes
echo " <TD rowspan=\"2\"></TD> ";
echo " <TD rowspan=\"2\" valign=\"top\"> ";

#
# Si pas de site, affiche le resume
if [ -z "$target" ]
then
	if [ -n "$RESUME" ]
	then
		# Il est possible de deactiver l'affichage des graphes RRD
		# en supprimant la variable RESUME dans /etc/vigilia/base.cfg

		make_resume

		if [ "$history" = "errors" ]
		then
			# Graphe de la somme des erreurs TCP
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_netstat&period=J1\"></img> ";
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_netstat&period=J7\"></img> ";
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_netstat&period=J30\"></img> ";
		elif [ "$history" = "http_time" ]
		then
			# Graphe de la somme des temps de reponse HTTP
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_http&period=J1\"></img> ";
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_http&period=J7\"></img> ";
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_http&period=J30\"></img> ";
		else
			# Graphe de la somme des erreurs TCP
			echo "<a href=\"vigilia.cgi?history=errors\"> ";
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_netstat&period=J1\"></img> ";
			echo "</a>";

			# Graphe de la somme des temps de reponse HTTP
			echo "<a href=\"vigilia.cgi?history=http_time\"> ";
			echo "<img src=\"vigilia.cgi?img=resume&type=resume_http&period=J1\"></img> ";
			echo "</a>";

			# Affiche les worst
			echo " <pre><table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" bgcolor=\"#E1E1E1\" width=\"25%\">";
			echo " <tr bgcolor=\"#00438C\"><td align=\"center\"><font color=\"ffffff\"><strong>TOP 5 des plus mauvais sites</strong></font></td>";
			echo "<tr><td><pre>"
			cat /etc/vigilia/target.cfg | while read LINE
			do
				SITE=`echo $LINE | awk '{print $1}'`
				if [ -f ${VIGILIA_SPOOL}/http/${SITE}.time ]
				then
					SITE_TIME=`cat ${VIGILIA_SPOOL}/http/${SITE}.time`
					expr $SITE_TIME / 1000000  | tr -s '\n' ' '
					echo $SITE
				fi
			done | sort -n | tail -5
			echo "</pre></td></tr>";
			echo "</table></pre>";

			# Affiche les sites en IPv6
			echo " <pre><table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" bgcolor=\"#E1E1E1\" width=\"25%\">";
			echo " <tr bgcolor=\"#00438C\"><td align=\"center\"><font color=\"ffffff\"><strong>SITES en IPv6</strong></font></td>";
			echo "<tr><td><pre>"
			cat /etc/vigilia/target.cfg | while read LINE
			do
				SITE=`echo $LINE | awk '{print $1}'`
				if [ -f ${VIGILIA_BASE}/analyse/$SITE/http6_time.rrd ]
				then
					echo -n "<a href=\"./vigilia.cgi?target="
					echo -n $SITE
					echo -n "\">"
					echo -n $SITE
					echo "</a>"
				fi
			done
			echo "</pre></td></tr>";
			echo "</table></pre>";
		fi


		# For DEBUG
		#echo "<pre>";
		#cat /tmp/rrd_http_def
		#cat /tmp/rrd_http_cdef
		#echo "</pre>";

		#rm -f /tmp/rrd_def
		#rm -f /tmp/rrd_cdef
		#rm -f /tmp/rrd_http_def
		#rm -f /tmp/rrd_http_cdef
	fi

	# Affiche les hops avec le plus de drop
	echo " <pre><table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" bgcolor=\"#E1E1E1\" width=\"50%\">";
	echo " <tr bgcolor=\"#00438C\"><td align=\"center\"><font color=\"ffffff\"><strong>Drop</strong></font></td>";
	echo "<td align=\"center\"><font color=\"ffffff\"><strong>HOPs</strong></td>";
	echo "<td align=\"center\"><font color=\"ffffff\"><strong>SITEs impactes</strong></td></tr>";
	#echo "<tr><td><pre>";
	echo "<pre>";
	[ -f ${VIGILIA_BASE}/analyse/global/path_drop_cumul ] && cat ${VIGILIA_BASE}/analyse/global/path_drop_cumul | while read LINE
	do
		echo "<tr><td align=\"center\">";
		echo $LINE | awk '{print $1}'
		echo "</td>";

		IP=`echo $LINE | awk '{print $2}'`
		echo "<td>";
		echo "<a href=\"javascript:affichage_popup('./showLog.cgi?REQUEST=";
		#echo $LINE | awk '{print $2}'
		echo $IP
		echo "','popup_log');\">"
		#echo $LINE | awk '{print $2}'
		echo $IP
		echo "</a>";
		echo "</td>";

		echo "<td>";
		grep $IP ${VIGILIA_SPOOL}/mtr/* | awk -F: '{print $1}' | awk -F/ '{print $NF}'
		echo "</td></tr>";


	done
	#echo "</pre></td></tr>";
	echo "</pre>";
	echo "</table></pre>";
	echo " <p><font size=\"-2\"><i>Cliquez sur l adresse IP pour le nom reverse et le Whois</i></font></p>";

	echo " <p><a href=\"javascript:affichage_popup('./showLog.cgi?TYPE=MTR','popup_log');\">Resultats d'analyse path MTR</a>";

	echo "<hr>";
	echo "<H2>Status des services testes</h2>";

	# Status global
	cat /etc/vigilia/target.cfg | while read LINE
	do
		SITE=`echo $LINE | awk '{print $1}'`
		METHOD=`echo $LINE | awk '{print $3}'`

		if [ "$METHOD" = "dns" ]
		then
			echo "<tr><td>" >> /tmp/dns.html
			echo $SITE >>/tmp/dns.html
			echo "</td><td>" >> /tmp/dns.html
			grep real ${VIGILIA_SPOOL}/dns/$SITE >> /tmp/dns.html
			echo "</td></tr>" >> /tmp/dns.html
		elif [ "$METHOD" = "tcp" ]
		then
			echo "<tr><td>" >> /tmp/tcp.html
			echo $SITE >>/tmp/tcp.html
			echo "</td><td>" >> /tmp/tcp.html
			grep packet ${VIGILIA_SPOOL}/tcpping/$SITE >> /tmp/tcp.html
			echo "</td></tr>" >> /tmp/tcp.html
		elif [ "$METHOD" = "http" ]
		then
			echo -n "<tr><td>" >> /tmp/http.html
			echo -n "<a href='./showLog.cgi?TYPE=WGET_LOG&SITE=" >> /tmp/http.html
			echo -n $SITE >>/tmp/http.html
			echo -n "'>$SITE</a>" >> /tmp/http.html
			echo -n "</td><td><pre>" >> /tmp/http.html
			grep saved ${VIGILIA_SPOOL}/http/${SITE} >> /tmp/http.html
			echo "</pre></td></tr>" >> /tmp/http.html
		fi
	done

	if [ `cat /tmp/dns.html | wc -l` -gt 0 ]
	then
		# DNS Summary
		echo "<pre>"
		echo " <table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" bgcolor=\"#E1E1E1\" width=\"50%\">";
		echo " <tr bgcolor=\"#00438C\"><td align=\"center\"><font color=\"ffffff\"><strong>DNS</strong></font></td><td><font color=\"ffffff\"><strong>Temps de reponse</strong></font></td>";
		cat /tmp/dns.html
		echo " </table>";
		echo "</pre>"
		#echo "&nbsp";

		rm /tmp/dns.html
	fi

	if [ `cat /tmp/tcp.html | wc -l` -gt 0 ]
	then
		# tcpping summary
		echo "<pre>"
		echo " <table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" bgcolor=\"#E1E1E1\" width=\"70%\">";
		echo " <tr bgcolor=\"#00438C\"><td align=\"center\"><font color=\"ffffff\"><strong>SITE</strong></font></td><td align=\"center\"><font color=\"ffffff\"><strong>TCPping result</strong></font></td>";
		cat /tmp/tcp.html
		echo " </table>";
		echo "</pre>"
		#echo "&nbsp";

		rm /tmp/tcp.html
	fi

	if [ `cat /tmp/http.html | wc -l` -gt 0 ]
	then
		# http summary
		echo "<pre>"
		echo " <table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" bgcolor=\"#E1E1E1\" width=\"100%\" class=\"display\">";
		#echo " <table border=\"1\" cellpadding=\"0\" cellspacing=\"1\" bgcolor=\"#E1E1E1\" width=\"100%\" id=\"main_table\" class=\"display\">";
		echo " <tr bgcolor=\"#00438C\"><td align=\"center\"><font color=\"ffffff\"><strong>SITE</strong></font></td><td align=\"center\"><font color=\"ffffff\"><strong>wget result</strong></font></td>";
		#echo " <thead><tr><th>SITE</th><th>wget result</th></thead><tbody>";
		cat /tmp/http.html
		#echo " </tbody></table>";
		echo " </table>";
		echo "</pre>"

		rm /tmp/http.html
	fi
else
	# Status d'un site

	# Affichage des stats

	# NB Hop du path
	if [ -f ${VIGILIA_BASE}/analyse/$target/path_nb_hop.rrd -a -z "$history" ]
	then
		# H-24
		#_graph=${target}-nb_hop-H24.png
		#mtr_hops_graph $_graph $target/path_nb_hop.rrd "${target} - MTR Hops - Periode = H-24" 1d
		echo "<a href=\"vigilia.cgi?target=${target}&history=nb_hop\"> ";
		#echo "<img src=\"/img/${target}-nb_hop-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=mtr_hops&period=H24\"></img> ";
		echo "</a>";

	elif [ "$history" = "nb_hop" ]
	then
		# H-24
		#_graph=${target}-nb_hop-H24.png
		#mtr_hops_graph $_graph $target/path_nb_hop.rrd "${target} - MTR Hops - Periode = H-24" 1d
		#echo "<img src=\"/img/${target}-nb_hop-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=mtr_hops&period=H24\"></img> ";

		# J-7
		#_graph=${target}-nb_hop-J7.png
		#mtr_hops_graph $_graph $target/path_nb_hop.rrd "${target} - MTR Hops - Periode = J-7" 7d
		#echo "<img src=\"/img/${target}-nb_hop-J7.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=mtr_hops&period=J7\"></img> ";

		# J-30
		#_graph=${target}-nb_hop-J30.png
		#mtr_hops_graph $_graph $target/path_nb_hop.rrd "${target} - MTR Hops - Periode = J-30" 30d
		#echo "<img src=\"/img/${target}-nb_hop-J30.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=mtr_hops&period=J30\"></img> ";
	fi

	# Netstat error
	if [ -f ${VIGILIA_BASE}/analyse/$target/netstat_error.rrd -a -z "$history" ]
	then
		# H-24
		#_graph=${target}-errors-H24.png
		#netstat_errors_graph $_graph $target/netstat_error.rrd "${target} - TCP errors - Periode = H-24" 86400

		echo "<a href=\"vigilia.cgi?target=${target}&history=netstat\"> ";
		#echo "<img src=\"/img/${target}-errors-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=netstat_errors&period=H24\"></img> ";
		echo "</a>";
	elif [ "$history" = "netstat" ]
	then
		# H-24
		#_graph=${target}-errors-H24.png
		#netstat_errors_graph $_graph $target/netstat_error.rrd "${target} - TCP errors - Periode = H-24" 86400
		#echo "<img src=\"/img/${target}-errors-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=netstat_errors&period=H24\"></img> ";

		# J-7
		#_graph=${target}-errors-J7.png
		#netstat_errors_graph $_graph $target/netstat_error.rrd "${target} - TCP errors - Periode = J-7" 7d
		#echo "<img src=\"/img/${target}-errors-J7.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=netstat_errors&period=J7\"></img> ";

		# J-30
		#_graph=${target}-errors-J30.png
		#netstat_errors_graph $_graph $target/netstat_error.rrd "${target} - TCP errors - Periode = J-30" 30d
		#echo "<img src=\"/img/${target}-errors-J30.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=netstat_errors&period=J30\"></img> ";

	fi

	# DNS response time
	if [ -f ${VIGILIA_BASE}/analyse/$target/dns_time.rrd -a -z "$history" ]
	then
		# H-24
		_graph=${target}-dns-H24.png
		#dns_time_graph $_graph $target/dns_time.rrd "${target} - DNS Latency - Periode = H-24" 86400
		echo "<a href=\"vigilia.cgi?target=${target}&history=dns_time\"> ";
		#echo "<img src=\"/img/${target}-dns-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=dns_time&period=H24\"></img> ";
		echo "</a>";
	elif [ "$history" = "dns_time" ]
	then
		# H-24
		#_graph=${target}-dns-H24.png
		#dns_time_graph $_graph $target/dns_time.rrd "${target} - DNS Latency - Periode = H-24" 86400
		#echo "<img src=\"/img/${target}-dns-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=dns_time&period=H24\"></img> ";

		# J-7
		#_graph=${target}-dns-J7.png
		#dns_time_graph $_graph $target/dns_time.rrd "${target} - DNS Latency - Periode = J-7" 7d
		#echo "<img src=\"/img/${target}-dns-J7.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=dns_time&period=J7\"></img> ";

		# J-30
		#_graph=${target}-dns-J30.png
		#dns_time_graph $_graph $target/dns_time.rrd "${target} - DNS Latency - Periode = J-30" 30d
		#echo "<img src=\"/img/${target}-dns-J30.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=dns_time&period=J30\"></img> ";
	fi

	# HTTP response time
	if [ -f ${VIGILIA_BASE}/analyse/$target/http_time.rrd -a -z "$history" ]
	then
		# H-24
		_graph=${target}-http_time-H24.png
		#http_time_graph $_graph $target/http_time.rrd "${target} - HTTP Latency - Periode = H-24" 86400
		echo "<a href=\"vigilia.cgi?target=${target}&history=http_time\"> ";
		#echo "<img src=\"/img/${target}-http_time-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_time&period=H24\"></img> ";
		echo "</a>";
	elif [ "$history" = "http_time" ]
	then
		# H-24
		_graph=${target}-http_time-H24.png
		#http_time_graph $_graph $target/http_time.rrd "${target} - HTTP Latency - Periode = H-24" 86400
		#echo "<img src=\"/img/${target}-http_time-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_time&period=H24\"></img> ";

		# J-7
		_graph=${target}-http_time-J7.png
		#http_time_graph $_graph $target/http_time.rrd "${target} - HTTP Latency - Periode = J-7" 7d
		#echo "<img src=\"/img/${target}-http_time-J7.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_time&period=J7\"></img> ";

		# J-30
		_graph=${target}-http_time-J30.png
		#http_time_graph $_graph $target/http_time.rrd "${target} - HTTP Latency - Periode = J-30" 30d
		#echo "<img src=\"/img/${target}-http_time-J30.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_time&period=J30\"></img> ";
	fi

	# HTTP IPv6 response time
	if [ -f ${VIGILIA_BASE}/analyse/$target/http6_time.rrd -a -z "$history" ]
	then
		# H-24
		_graph=${target}-http6_time-H24.png
		#http_time_graph $_graph $target/http6_time.rrd "${target} - HTTP IPv6 Latency - Periode = H-24" 86400
		echo "<a href=\"vigilia.cgi?target=${target}&history=http6_time\"> ";
		#echo "<img src=\"/img/${target}-http6_time-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http6_time&period=H24\"></img> ";
		echo "</a>";
	elif [ "$history" = "http6_time" ]
	then
		# H-24
		_graph=${target}-http6_time-H24.png
		#http_time_graph $_graph $target/http6_time.rrd "${target} - HTTP IPv6 Latency - Periode = H-24" 86400
		#echo "<img src=\"/img/${target}-http6_time-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http6_time&period=H24\"></img> ";

		# J-7
		#_graph=${target}-http6_time-J7.png
		#http_time_graph $_graph $target/http6_time.rrd "${target} - HTTP IPv6 Latency - Periode = J-7" 7d
		#echo "<img src=\"/img/${target}-http6_time-J7.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http6_time&period=J7\"></img> ";

		# J-30
		#_graph=${target}-http6_time-J30.png
		#http_time_graph $_graph $target/http6_time.rrd "${target} - HTTP IPv6 Latency - Periode = J-30" 30d
		#echo "<img src=\"/img/${target}-http6_time-J30.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http6_time&period=J30\"></img> ";
	fi

	# HTTP Speed
	if [ -f ${VIGILIA_BASE}/analyse/$target/http_speed.rrd -a -z "$history" ]
	then
		# H-24
		#_graph=${target}-http_speed-H24.png
		#http_speed_graph $_graph $target/http_speed.rrd "${target} - HTTP Speed - Periode = H-24" 1d
		echo "<a href=\"vigilia.cgi?target=${target}&history=http_speed\"> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_speed&period=H24\"></img> ";
		#echo "<img src=\"/img/${target}-http_speed-H24.png\"></img> ";
		echo "</a>";
	elif [ "$history" = "http_speed" ]
	then
		# H-24
		#_graph=${target}-http_speed-H24.png
		#http_speed_graph $_graph $target/http_speed.rrd "${target} - HTTP Speed - Periode = H-24" 1d
		#echo "<img src=\"/img/${target}-http_speed-H24.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_speed&period=H24\"></img> ";

		# J-7
		#_graph=${target}-http_speed-J7.png
		#http_speed_graph $_graph $target/http_speed.rrd "${target} - HTTP Speed - Periode = J-7" 7d
		#echo "<img src=\"/img/${target}-http_speed-J7.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_speed&period=J7\"></img> ";

		# J-30
		#_graph=${target}-http_speed-J30.png
		#http_speed_graph $_graph $target/http_speed.rrd "${target} - HTTP Speed - Periode = J-30" 30d
		#echo "<img src=\"/img/${target}-http_speed-J30.png\"></img> ";
		echo "<img src=\"vigilia.cgi?img=${target}&type=http_speed&period=J30\"></img> ";
	fi

	# Affichage des logs

	echo "<table>"

	if [ -f ${VIGILIA_SPOOL}/mtr/$target ]
	then
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "<tr bgcolor=\"\#bbbbbb\"><td>"
		echo "<PRE>"
		cat ${VIGILIA_SPOOL}/mtr/$target
		echo "</PRE>"
		echo "</td></tr>"
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "</td></tr>"
		echo "<tr bgcolor=\"\#bbbbbb\"><td>"
		echo "<PRE>"
		ls ${VIGILIA_BASE}/analyse/$target/mtr_error.* | while read LINE
		do
			echo "<a href=\"javascript:affichage_popup('./showLog.cgi?TYPE=MTR_ERR&SITE=";
			echo $LINE
			echo "','popup_log');\">";
			echo $LINE
			echo "</a>";
		done
		echo "</PRE>"
		echo "</td></tr>"
	fi

	if [ -f ${VIGILIA_SPOOL}/http/$target ]
	then
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "<tr bgcolor=\"\#bbbbbb\"><td>"
		echo "<PRE>"
		cat ${VIGILIA_SPOOL}/http/$target
		echo "</PRE>"
		echo "</td></tr>"
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "</td></tr>"
		echo "<tr bgcolor=\"\#bbbbbb\"><td><pre>"
		find ${VIGILIA_BASE}/analyse/$target -name "http.timeout.*" | while read LINE
                do
                        echo "<a href=\"javascript:affichage_popup('./showLog.cgi?TYPE=MTR_ERR&SITE=";
                        echo -n $LINE
                        echo -n "','popup_log');\">";
                        echo -n $LINE
                        echo "</a>";
                done
		echo "</pre></td></tr>"
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "</td></tr>"
	elif [ -f ${VIGILIA_SPOOL}/dns/$target ]
	then
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "<tr bgcolor=\"\#bbbbbb\"><td>"
		echo "<PRE>"
		cat ${VIGILIA_SPOOL}/dns/$target
		echo "</PRE>"
		echo "</td></tr>"
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "</td></tr>"
	elif [ -f ${VIGILIA_SPOOL}/tcpping/$target ]
	then
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "<tr bgcolor=\"\#bbbbbb\"><td>"
		echo "<PRE>"
		cat ${VIGILIA_SPOOL}/dns/$target
		echo "</PRE>"
		echo "</td></tr>"
		echo "<tr bgcolor=\"\#555555\"><td> "
		echo "</td></tr>"
	fi

	echo "</table>"


fi


echo " </table> ";
echo " </BODY> ";
echo " </HTML>";

fi
