#!/bin/sh

source /jffs/scripts/mylib.sh

# -----------------------------------------
## Check route for external LANs
#echo "zt lan route:"
#addRoute "172.24.0.0/24" "10.147.17.128"
#addRoute "192.168.108.0/24" "10.147.17.64"

# -----------------------------------------
# Set this to "yes" to enable this router to be
# the gateway for full tunnel mode.
FULL_TUNNEL="no"


# -----------------------------------------
# route for this LAN
#echo "zt iptables:"
baseZTRoute "10.147.17.0/24"
