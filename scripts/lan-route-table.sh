#!/bin/sh

source /jffs/scripts/mylib.sh

# -----------------------------------------
## Check route for external LANs
#echo "zt lan route:"
addRoute "172.24.0.0/24" "10.147.17.128"
#addRoute "192.168.108.0/24" "10.147.17.64"

# -----------------------------------------
# route for this LAN
#echo "zt iptables:"
baseZTRoute "10.147.17.0/24"

# -----------------------------------------
# Redirect TCP/UDP IPv6 11111 to IPv4 192.168.9.5:3389
#psCHK "socat TCP6-LISTEN:11111,fork TCP4:192.168.9.5:3389"
#psCHK "socat UDP6-RECVFROM:11111,fork UDP4-SENDTO:192.168.9.5:3389"

# ip4/6tables for RDP
#ip6tablesINS "INPUT -i ppp+ -p tcp --dport 11111 -j ACCEPT"
#ip6tablesINS "INPUT -i ppp+ -p udp --dport 11111 -j ACCEPT"

#ip6tablesINS "INPUT -i eth+ -p tcp --dport 11111 -j ACCEPT"
#ip6tablesINS "INPUT -i eth+ -p udp --dport 11111 -j ACCEPT"

# job's RDP
#iptablesINS "PREROUTING -t nat -s 192.168.9.0/24,10.9.8.0/24 -p tcp --dport 13389 -j DNAT --to-destination 192.168.102.204:3389"
