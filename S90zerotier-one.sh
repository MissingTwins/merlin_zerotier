#! /bin/sh

source /jffs/scripts/mylib.sh

# -----------------------------------------
# Example : baseRoute
# Args    : None
# Input   : None
# Return  : None
function baseRoute() {

    # Allow LAN via zerotier
    /jffs/scripts/lan-route-table.sh  
}

# -----------------------------------------
# Example : initCheck
# Args    : None
# Input   : None
# Return  : None
function initCheck() {

    ZT_ONLINE=$(zerotier-cli info| grep -i "online")
    if [ -z "$ZT_ONLINE" ];then
        sysLOG "ZT OFFLINE! restarting" warning ;
        /opt/etc/init.d/S91zerotier-one restart
        return 0;
    fi
    
    ZT_INTERFACE=$(ip -o link show | grep -oP '\d{1,2}:\s\Kzt[\w]+' | head -n1);
    # fallback
    if [ -z "$ZT_INTERFACE" ];then 
        echo "get zt interface empty, trying another way";
        ZT_INTERFACE=$(ip -o link show | awk -F': ' '{print $2}'|grep "^zt");
    fi
    echo "Is zt empty: $ZT_INTERFACE";
    
    # sometimes dev zt0 would disappeared until you restarted zerotier
    if [ -z "$ZT_INTERFACE" ];then 
        sysLOG "zt+ dev disappeared! Restarting" warning ;
        /opt/etc/init.d/S91zerotier-one restart
    fi
    
    # zerotier http not working when system started, restart zerotier is essential
    if [ -f "/tmp/first-start.flag" ];then
        echo "found zerotier first launch"
        tmpup=$(uptime | cut -c 14- )
        tmpup=${tmpup%% load*}
        is_long_enough=""
        echo $tmpup | grep -i "days" && is_long_enough=1
        echo $tmpup | grep -i ":" && is_long_enough=1
        echo $tmpup | grep -i "min,"
        if [ "$?" -eq 0 ]; then
            tmpup=${tmpup%%min*}
            # greater than 2 minutes
            [ "$tmpup" -gt 2 ] && is_long_enough=1
        fi
        if [ "$is_long_enough" -gt 0 ];then
            sysLOG "due to first launch, restart zerotier" info ;
            /opt/etc/init.d/S91zerotier-one restart
            rm /tmp/first-start.flag
        fi
    fi
    
    # MTU is causing lots of problems
    if [ ! -z "$ZT_INTERFACE" ];then ifconfig "$ZT_INTERFACE" mtu 1388; fi

    # add base route tables
    if [ ! -z "$ZT_INTERFACE" ];then baseRoute; fi
}

# -----------------------------------------

case "$1" in
  start)
    # -------
    if lsmod | grep -q tun ;
    then echo "mod tun ready" ;
    else 
        modprobe tun; 
        sysLOG "starting modprobe tun, zerotier should start in one minute" notice ;
        exit 0;
    fi
    # -------
    if ( pidof zerotier-one )
    then 
		echo "ZeroTier-One is already running.";
        initCheck ;
    else
        echo "Starting ZeroTier-One" ;
        /opt/bin/zerotier-one -d ;
        sysLOG "Zerotier Started" notice ;
        initCheck ;
    fi
    ;;
  stop)
    # -------
    if ( pidof zerotier-one )
    then
        echo "Stopping ZeroTier-One";
        killall zerotier-one
        sysLOG "Zerotier Stopped" notice ;
    else
        echo "ZeroTier-One was not running" ;
    fi
    ;;
  status)
    # -------
    if ( pidof zerotier-one )
    then echo "ZeroTier-One is running."
    else echo "ZeroTier-One is NOT running"
    fi
    ;;
  *)
    echo "Usage: /etc/init.d/zerotier-one {start|stop|status}"
    exit 1
    ;;
esac

# -----------------------------------------
exit 0
