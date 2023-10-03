#!/bin/sh

echo "Starting script myservices.sh" 
logger -t "myservices.sh" -c "Enter" -p user.notice

#----------------------------------
cru a ZeroTierDaemon  "*/1 * * * * /opt/etc/init.d/S90zerotier-one.sh start"

echo "after myservices.sh" 
logger -t "myservices.sh" -c "Leaving" -p user.notice
