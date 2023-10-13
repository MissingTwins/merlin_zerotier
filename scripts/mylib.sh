#!/bin/sh

MY_BASE=$(echo $0)
#Avoid sourcing scripts multiple times echo $0 = -sh
[[ "${_NAME_OF_THIS_LIBSCRIPT:-""}" == "yes" ]] && return 0
[[ "${MY_BASE:0:1}" != "-" ]] && _NAME_OF_THIS_LIBSCRIPT=yes

# Log Tag
#[[ "${LOG_TAG:-""}" ]] && return 0
LOG_TAG=`basename "$0"`
LOG_TAG="DarthTwins $LOG_TAG"
printf "\n\n$(date '+%m/%d %T') LOG_TAG=$LOG_TAG\n"

$(sh -c ": > /dev/tty" )
[ $? != 0 ] || { IS_CONSOLE=1; echo "This is a console"; }

# -----------------------------------------
# Example : sysLOG "We have a problem!" error
# Argu    : $1 logs
#           $2 error/notice/warning
# Input   : $IS_CONSOLE
# Return  : None
function sysLOG() {
    if [ -n "$IS_CONSOLE" ]; then
        echo "$1" | tee /dev/tty | tr -d '\n' | logger -t $LOG_TAG -p user.$2;
    else
        echo "$1" | tr -d '\n' | logger -t $LOG_TAG -p user.$2;
    fi
}

# -----------------------------------------
# Example : iptablesINS "INPUT -i ppp+ -p tcp --dport 11111 -j ACCEPT"
# Argu    : $1 iptables-rules
# Input   : None
# Return  : None
function iptablesINS() {

	local reRAW RECODE CMD_STR
    CMD_STR="iptables -I $1"
    reRAW=$( iptables -C $1 2>&1 )
	RECODE=$?
	reRAW=$( echo -n "$reRAW" | head -n 1  )
	if [ $RECODE -ge 2 ]; then
		sysLOG "ip6tables -I $1 Err=$reRAW" error
    elif [ $RECODE -eq 1 ]; then
        reRAW=$( eval $CMD_STR 2>&1 )
        [ $? != 0 ] && sysLOG "Error $CMD_STR" error || sysLOG "Success $CMD_STR" notice
	else
		echo "Existed $CMD_STR"
    fi
}

# -----------------------------------------
# Example : ip6tablesINS "INPUT -i ppp+ -p tcp --dport 11111 -j ACCEPT"
# Argu    : $1 ip6tables-rules
# Input   : None
# Return  : None
function ip6tablesINS() {

	local reRAW RECODE CMD_STR
	CMD_STR="ip6tables -I $1"
    reRAW=$( ip6tables -C $1 2>&1 )
	RECODE=$?
	reRAW=$( echo -n "$reRAW" | head -n 1  )
	# echo "=$RECODE |$1 | RE="$reRAW
    if [ $RECODE -ge 2 ]; then
        sysLOG "ip6tables -I $1 Err=$reRAW" error
    elif [ $RECODE -eq 1 ]; then
        reRAW=$( eval $CMD_STR 2>&1 )
        [ $? != 0 ] && sysLOG "Error $CMD_STR" error || sysLOG "Success $CMD_STR" notice
	else
		echo "Existed $CMD_STR"
    fi
}


# -----------------------------------------
# Example : addRoute "192.168.8.0/24" "10.9.8.5"
# Argu    : $1 net
# Argu    : $2 gate
# Input   : None
# Return  : None
function addRoute() {
    local TEST_ARGS msg CMD_STR
    CMD_STR="ip route replace $1 via $2 "
    TEST_ARGS=$(ip route show "$1" | wc -l)
    if [ $TEST_ARGS -eq 0 ]; then
        msg=$( eval $CMD_STR 2>&1 )
        [ $? != 0 ] && sysLOG "Failed $CMD_STR err=$msg" error || sysLOG "Success $CMD_STR" notice
    fi
}

# -----------------------------------------
# Example : psCHK "socat TCP6-LISTEN:11111,fork TCP4:192.168.5.5:3389"
# Argu    : $1 command
# Input   : None
# Return  : None
function psCHK() {
    printf "\nEntering $1\n"
    local PS_CMD PS_LIST CMD_STR KEY_WORD
    CMD_STR=$1
    KEY_WORD=$1
   #KEY_WORD=$( printf "$1" | awk -F',' '{print $1}' )
    ps aux  &>/dev/null
    [ $? != 0 ] && PS_CMD="ps -w" || PS_CMD="ps aux"
   #PS_LIST=$( $PS_CMD 2>&1 )
   #echo "$PS_LIST" > /tmp/ps_list_`sed 's/[. ].*//' /proc/uptime`.txt
   #printf "KEY_WORD=$KEY_WORD PS_LIST=${#PS_LIST}\n"
   #printf "$PS_LIST"  | grep -Fi "$CMD_STR"
   #printf "$PS_LIST"  | grep -Fi "$KEY_WORD"
   #printf "$PS_LIST"  | awk '$0 ~ /awk/{next} $0 ~ /'"$KEY_WORD"'/{ print $0"<--awk"; err=0; exit} BEGIN{err=1} END{exit err}'
   #printf "$PS_LIST"  | awk '$0 ~ /awk/{next} $0 ~ /'"$KEY_WORD"'/{ print $0"<--awk-keyword"; err=0; exit} BEGIN{err=1} END{exit err}'
   #RE=$( printf "$PS_LIST"  | grep -Fi "$KEY_WORD"  )
    ( $PS_CMD  | grep -Fi "$CMD_STR" | grep -v grep )
    if [ $? != 0 ]; then
        sysLOG "Process not found $CMD_STR" warning
   #    ( $CMD_STR &  <&- >&- 2>&- & )
        ( $CMD_STR &  )
        sleep 1;
        ( $PS_CMD | grep -Fi "$CMD_STR" | grep -v grep )
        [ $? != 0 ] && sysLOG "Launch Failed $CMD_STR" error || sysLOG "Started $CMD_STR" notice
    fi
    printf "Exiting $1\n"
}

# -----------------------------------------
# Example : baseZTRoute "10.9.8.0/24"
# Argu    : none
# Input   : ZT_NETWORK
# Return  : None
function baseZTRoute() {
	local ZT_NETWORK
	ZT_NETWORK=$1
	iptables -C INPUT -i zt+ -j ACCEPT
	if [ $? != 0 ]; then
		iptables -I INPUT 1 -i zt+ -j ACCEPT
		iptables -t nat -I PREROUTING -i zt+ -d $ZT_NETWORK -p tcp -m multiport --dport 21,22,80 -j DNAT --to-destination `nvram get lan_ipaddr`
		#iptables -t nat -I PREROUTING -i zt+ -s 10.9.8.0/24 -d 10.9.8.0/24 -p tcp -m multiport --dport 21,22,80 -j DNAT --to-destination `nvram get lan_ipaddr`
		#iptables -I INPUT 1 -i `nvram get wan0_gw_ifname` -p icmp -j DROP
		#iptables -I INPUT 1 -i ztzlgf7vul -p icmp -j ACCEPT
		iptables -t nat -A POSTROUTING -o br0 -s $ZT_NETWORK -j SNAT --to-source `nvram get lan_ipaddr`
		iptables -I FORWARD -i zt+ -d `nvram get lan_ipaddr`/24 -j ACCEPT
		#iptables -I FORWARD -i zt+ -d 192.168.7.0/24 -j ACCEPT
		iptables -I FORWARD -i br0 -d $ZT_NETWORK -j ACCEPT
		sysLOG "zt+ rules added $ZT_NETWORK" notice
	else
		echo "Existed baseZTRoute $ZT_NETWORK"
	fi
}

# -----------------------------------------
# Example : ipv6Checker "2400:4153:9101:6200:7e10:c9ff:feb5:8a78/64"
# Argu    : none
# Input   : IPv6
# Return  : None
function ipv6Checker() {
	regex='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$'
	echo -n "$1" | awk '$0 !~ /'"$regex"'/{print "not an ipv6=>"$0;exit 1}'
}

# -----------------------------------------
# Example : ipChk 120.5.7.5
# Argu    : 4 or 6
#           IPv4/IPv6 Address
# Input   : $RE_IPV4
# Return  : $?, 0 OR 1
function ipChk()
{
	# ------------------------------
	# https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses

	RE_IPV4="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"

	SEG="[0-9a-fA-F]{1,4}"

	RE_IPV6="([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|"
	RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,7}:|"
	RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|"
	RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|"
	RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|"
	RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|"
	RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|"
	RE_IPV6="${RE_IPV6}[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|"
	RE_IPV6="${RE_IPV6}:((:[0-9a-fA-F]{1,4}){1,7}|:)|"
	RE_IPV6="${RE_IPV6}fe08:(:[0-9a-fA-F]{1,4}){2,2}%[0-9a-zA-Z]{1,}|"
	RE_IPV6="${RE_IPV6}::(ffff(:0{1,4}){0,1}:){0,1}${RE_IPV4}|"
	RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,4}:${RE_IPV4}"

    if [ "$1" == "6" ]; then
        echo -n "$2" | awk '$0 !~ /'"$RE_IPV6"'/{print "not an ipv6=>"$0; exit 1}'
    else
        local regexp4p='(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'
        echo -n "$2" | awk '$0 !~ /'$RE_IPV4'/{print "Not an ipv4=>"$0;err=1;exit}; $0 ~ /'$regexp4p'/{print "is a private ipv4=>"$0;err=1;exit} END {exit err}';
    fi
}

# -----------------------------------------
# Example : GetExtIP 4
# Argu    : 4 or 6
# Input   : None
# Return  : ip
function GetExtIP()
{
    if [ "$1" == 4 ]; then
        ip=$(curl -s -X GET https://checkip.amazonaws.com)
    else
        #ip=$(curl -s -X GET https://api6.my-ip.io/ip)
        ip=$(ip -6 addr | awk -F '[ \t]+|/'  '$3 == "::1" {next} $3 ~ /^fe80::/ {next} /inet6/ {print $3; exit 0}' )
    fi
}

# -----------------------------------------
# Example : getNSIP 4 sub.domain.com
# Argu    : 4 or 6
# Input   : $dnsrecord
#           $DNS_SERVER
#           $RE_IPV6
# Return  : nsIP
function getNSIP() {

    # make sure dns result is avail
     local nsRAW=$(nslookup $dnsrecord $DNS_SERVER)
    [ $? != 0 ] && {
        sysLOG "nslookup failed $nsRAW" notice;
        exit 1 ;
    }

    if [ "$1" == 4 ]; then
        local nsIPv4s=$(echo -n "$nsRAW" | awk 'tolower($0) ~ /name/{ while( getline ){ if(match($0, /'$RE_IPV4'/)){ print substr($0, RSTART, RLENGTH);  }}}') ;

        # filtering Private IPs and accept the first Public IP
        local regexp4p='(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'
        nsIP=$(echo -n "$nsIPv4s" | awk '$0 !~ /'$regexp4p'/{print $0;err=0; exit 0} BEGIN{err=1} END{exit err}');
    else
        local nsIPv6s=$(echo -n "$nsRAW" | awk 'tolower($0) ~ /name/{ while( getline ){ if(match($0, /'$RE_IPV6'/)){ print substr($0, RSTART, RLENGTH); }}}') ;

        # filtering Private IPs and accept the first Public IP
        nsIP=$(echo -n "$nsIPv6s" | awk '$0 == "::1" {next} $0 ~ /^fe80::/ {next} {print $0;err=0; exit 0} BEGIN{err=1} END{exit err}' )
    fi

}
