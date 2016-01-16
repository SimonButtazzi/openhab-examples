#!/bin/bash

# --- openHAB ---
# if you do not use openHAB, yust leave OPENHAB_ITEM_IP empty
# Base URL of openHAB service (protocol, IP/domain, port)
OPENHAB_URL=http://127.0.0.1:8080

# openhab user
# format user:password
OPENHAB_USER=system:<mySecret>

# item of current IP address
# leave empty to disable
# OPENHAB_ITEM_IP=
OPENHAB_ITEM_IP=Internet_Ip

# --- Dynamic Domain Name Service (DDNS) ---
# URL to notify when IP changes
# leave empty to disable update requests
#DDNS_UPDATEURL=
DDNS_UPDATEURL=http://freedns.afraid.org/dynamic/update.php?<myApiKey>

# domain to check , without protocol (http://)
DDNS_DOMAIN=<myDomainName>

# --- Debugging ---
# enabled [0/1]
DEBUG=0

# Logfile
# leave empty to disable logging
LOGFILE=/opt/openhab/logs/scripts.log




DATESTART=`date +'(%N/1000000000+%s)'`
STATUS=
# check if there is an internet connection
ping -c1 8.8.8.8 > /dev/null
if [ $? -ne 0 ]; then
	STATUS+="offline"
	IP="offline"
else
	STATUS+="online"
	# get current and registered IP
	#IP=$(/usr/bin/curl http://ipecho.net/plain)
	IP=$(/usr/bin/curl -s http://checkip.dyndns.org|sed s/[^0-9.]//g)
	STATUS+=", current IP: $IP"

	IP_REGISTERED=$(nslookup $DDNS_DOMAIN|tail -n2|grep A|sed s/[^0-9.]//g)

	# if IP has changed
	if [ "$IP" != "$IP_REGISTERED" ]; then
		STATUS+=", registered IP: $IP_REGISTERED"
		# is there a service to notify
		if [ -n "$DDNS_UPDATEURL" ]; then
			RESPONSE=$(/usr/bin/curl -s $DDNS_UPDATEURL)
			STATUS+=", updated DDNS: $RESPONSE"
		fi
	fi
fi
# is there an item to update
if [ -n "$OPENHAB_ITEM_IP" ]; then
	/usr/bin/curl -s --header "Content-Type: text/plain" --request POST -u $OPENHAB_USER --data $IP $OPENHAB_URL/rest/items/$OPENHAB_ITEM_IP
	STATUS+=", item $OPENHAB_ITEM_IP updated"
fi

# do some logging
DATE=`date +'%d.%m.%Y - %T'`
DATEEND=`date +'(%N/1000000000+%s)'`
DURATION=`echo "scale=2; $DATEEND-$DATESTART" | bc -l`
if [ -n "$LOGFILE" ]; then
	echo "$DATE - $0 - $DURATION sec: ($STATUS)" >> $LOGFILE
fi
if [ "$DEBUG" != 0 ]; then
	echo "$DATE - $0 - $DURATION sec: ($STATUS)"
fi
