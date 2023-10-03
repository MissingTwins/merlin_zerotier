#!/bin/sh

echo "Starting script myservices.sh" 
logger -t "myservices.sh" -c "Enter" -p user.notice

#----------------------------------
cru a ZeroTierDaemon  "*/1 * * * * /opt/etc/init.d/S90zerotier-one.sh start"

#----------------------------------
# remove double quote in zerotier task. Bug?
cru a cruGuard1 "*/2 * * * * /jffs/scripts/cru_guard.sh"
cru a cruGuard2 "*/3 * * * * /jffs/scripts/cru_guard.sh"

echo "after myservices.sh" 
logger -t "myservices.sh" -c "Leaving" -p user.notice
