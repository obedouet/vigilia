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

# Fonctions
function http_time_graph {
_graph=$1
_rrd_source=$2
_title=$3
_start=$4
#${RRD_BIN}/rrdtool graph ${WWW_REP}/img/${_graph} --title="$_title" \
${RRD_BIN}/rrdtool graph - --title="$_title" \
	--start -$_start --height 137 --width 900 --lower-limit=0 --step 300 \
	--imgformat=PNG \
	--alt-autoscale-max \
	--vertical-label='seconds' \
	DEF:http_time=${VIGILIA_BASE}/analyse/${_rrd_source}:data:AVERAGE \
	CDEF:time=http_time,1000000000,/ \
	CDEF:zero=time,0,EQ,INF,UNKN,IF \
	CDEF:noValue=time,UN,INF,UNKN,IF \
	GPRINT:time:LAST:"Current\:%2.3lf"  \
	GPRINT:time:AVERAGE:"Average\:%2.3lf"  \
	GPRINT:time:MAX:"Max\:%2.3lf"  \
	AREA:noValue#ddccaa:"Pas de valeurs\n" \
	AREA:zero#ff0000:"Coupure\n" \
	AREA:time#0000ee:"HTTP response time\n"
	#AREA:time#0000ee:"HTTP response time\n" >> /tmp/vigilia_rrdtool.log 2>&1
}

function http_speed_graph {
if [ "$1" = "-" ]
then
	_graph=$1
else
	_graph=${WWW_REP}/img/$1
fi
_rrd_source=$2
_title=$3
_start=$4
${RRD_BIN}/rrdtool graph ${_graph} --title="${_title}" \
	--start -$_start --height 137 --width 900 --lower-limit=0 --step 300 \
	--imgformat=PNG \
	--alt-autoscale-max \
	--vertical-label='bits/second' \
	DEF:http_speed=${VIGILIA_BASE}/analyse/$_rrd_source:data:AVERAGE \
	CDEF:http_speed_bits=http_speed,8,* \
	CDEF:zero=http_speed,0,EQ,INF,UNKN,IF \
	CDEF:noValue=http_speed,UN,INF,UNKN,IF \
	GPRINT:http_speed_bits:LAST:"Current\:%2.3lf"  \
	GPRINT:http_speed_bits:AVERAGE:"Average\:%2.3lf"  \
	GPRINT:http_speed_bits:MAX:"Max\:%2.3lf"  \
	AREA:noValue#ddccaa:"Pas de valeurs\n" \
	AREA:zero#ff0000:"Coupure\n" \
	AREA:http_speed_bits#0000ee:"HTTP speed\n"
}

function dns_time_graph {
if [ "$1" = "-" ]
then
	_graph=$1
else
	_graph=${WWW_REP}/img/$1
fi
_rrd_source=$2
_title=$3
_start=$4
${RRD_BIN}/rrdtool graph ${_graph} --title="${_title}" \
	--start -$_start --height 137 --width 900 --lower-limit=0 --step 300 \
	--imgformat=PNG \
	--alt-autoscale-max \
	--vertical-label='seconds' \
	DEF:time=${VIGILIA_BASE}/analyse/$_rrd_source:data:AVERAGE \
	CDEF:zero=time,0,EQ,INF,UNKN,IF \
	GPRINT:time:LAST:"Current\:%2.3lf"  \
	GPRINT:time:AVERAGE:"Average\:%2.3lf"  \
	GPRINT:time:MAX:"Max\:%2.3lf"  \
	AREA:zero#ff0000:"Coupure\n" \
	AREA:time#0000ee:"DNS response time\n"
}

function netstat_errors_graph {
if [ "$1" = "-" ]
then
	_graph=$1
else
	_graph=${WWW_REP}/img/$1
fi
_rrd_source=$2
_title=$3
_start=$4
${RRD_BIN}/rrdtool graph ${_graph} --title="${_title}" \
	--start -$_start --height 137 --width 900 --lower-limit=0 --step 300 \
	--imgformat=PNG \
	--alt-autoscale-max \
	DEF:errors=${VIGILIA_BASE}/analyse/$_rrd_source:data:AVERAGE \
	GPRINT:errors:LAST:"Current\:%3.0lf"  \
	GPRINT:errors:AVERAGE:"Average\:%3.0lf"  \
	GPRINT:errors:MAX:"Max\:%3.0lf"  \
	LINE1:errors#0000ee:"Erreurs\n"
}

function mtr_hops_graph {
if [ "$1" = "-" ]
then
	_graph=$1
else
	_graph=${WWW_REP}/img/$1
fi
_rrd_source=$2
_title=$3
_start=$4
${RRD_BIN}/rrdtool graph ${_graph} --title="${_title}" \
	--start -$_start --height 137 --width 900 --lower-limit=0 --step 900 \
	--rigid \
	--imgformat=PNG \
	--alt-autoscale-max \
	--vertical-label='nb hop in path' \
	--slope-mode \
	DEF:nb_hop=${VIGILIA_BASE}/analyse/$_rrd_source:data:AVERAGE \
	CDEF:zero=nb_hop,0,EQ,INF,UNKN,IF \
	CDEF:noValue=nb_hop,UN,INF,UNKN,IF \
	GPRINT:nb_hop:LAST:"Current\:%3.0lf"  \
	GPRINT:nb_hop:AVERAGE:"Average\:%3.0lf"  \
	GPRINT:nb_hop:MAX:"Max\:%3.0lf"  \
	AREA:noValue#ddccaa:"Pas de valeurs\n" \
	AREA:zero#ff0000:"Coupure\n" \
	AREA:nb_hop#0000ee:"Nombre de hops\n"
}

#
function make_resume {

	rm -f /tmp/rrd_def
	rm -f /tmp/rrd_cdef
	rm -f /tmp/rrd_http_def
	rm -f /tmp/rrd_http_cdef


	cat /etc/vigilia/target.cfg | while read LINE
	do
		SITE=`echo $LINE | awk '{print $1}'`
		METHOD=`echo $LINE | awk '{print $3}'`

		if [ "$METHOD" = "http" ]
		then
			# Effectue la somme de toutes les sources http et erreurs TCP
			VNAME=`echo ${SITE} | tr '.' '_'`

			if [ -f ${VIGILIA_BASE}/analyse/$SITE/http_time.rrd ]
			then
				echo "DEF:err_${VNAME}=${VIGILIA_BASE}/analyse/$SITE/netstat_error.rrd:data:AVERAGE " >> /tmp/rrd_def
				echo "DEF:http_${VNAME}=${VIGILIA_BASE}/analyse/$SITE/http_time.rrd:data:AVERAGE " >> /tmp/rrd_http_def
				if [ ! -f /tmp/rrd_cdef ]
				then
					echo -n "err_${VNAME},UN,0,err_${VNAME},IF" > /tmp/rrd_cdef 
				else
					echo -n ",err_${VNAME},UN,0,err_${VNAME},IF,+" >> /tmp/rrd_cdef 
				fi

				if [ ! -f /tmp/rrd_http_cdef ]
				then
					echo -n "http_${VNAME},UN,0,http_${VNAME},IF" > /tmp/rrd_http_cdef
				else
					echo -n ",http_${VNAME},UN,0,http_${VNAME},IF,+" >> /tmp/rrd_http_cdef
				fi
			fi
		fi

	done
}

function make_graph_resume {
_title=$1
_start=$2
_type=$3

	if [ "$_type" = "errors" ]
	then
		# Graphe de la somme des erreurs TCP
		${RRD_BIN}/rrdtool graph - --title="ALL TCP Errors - Periode = $_start" \
		--start -${_start} --height 137 --width 900 --lower-limit=0 --step 300 \
			--imgformat=PNG \
			--alt-autoscale-max \
			`cat /tmp/rrd_def` \
			CDEF:errors=`cat /tmp/rrd_cdef` \
			GPRINT:errors:LAST:"Current\:%3.0lf"  \
			GPRINT:errors:AVERAGE:"Average\:%3.0lf"  \
			GPRINT:errors:MAX:"Max\:%3.0lf"  \
			LINE1:errors#0000ee:"Erreurs TCP\n" 

	elif [ "$_type" = "http_time" ]
	then
		# Graphe de la somme des temps de reponse HTTP
		${RRD_BIN}/rrdtool graph - --title="ALL HTTP latency - Periode = $_start" \
			--start -${_start} --height 137 --width 900 --lower-limit=0 --step 300 \
			--imgformat=PNG \
			--alt-autoscale-max \
			`cat /tmp/rrd_http_def` \
			CDEF:http_time=`cat /tmp/rrd_http_cdef`,1000000000,/ \
			GPRINT:http_time:LAST:"Current\:%3.0lf"  \
			GPRINT:http_time:AVERAGE:"Average\:%3.0lf"  \
			GPRINT:http_time:MAX:"Max\:%3.0lf"  \
			AREA:http_time#0000ee:"HTTP response time\n"
	fi

}
