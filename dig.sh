#!/usr/bin/env bash

while [ 1 ]; do
	unset HOSTNAME A_RECORD MX_RECORD MAIL_RECORD WEBMAIL_RECORD IPINFO_A IPINFO_MAIL IPINFO_WEBMAIL
	while [ 1 ]; do
		read -p "Input Hostname : " HOSTNAME </dev/tty
		[ -z "$HOSTNAME" ] && echo "Please Input Hostname..." || break
	done
	A_RECORD=$(dig +short a $HOSTNAME)
	MX_RECORD=$(dig +short MX $HOSTNAME)
	MAIL_RECORD=$(dig +short a mail.$HOSTNAME)
	WEBMAIL_RECORD=$(dig +short a webmail.$HOSTNAME)
	[ -z "$A_RECORD" ] || IPINFO_A=$(curl -s ipinfo.io/$A_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	[ -z "$MAIL_RECORD" ] || IPINFO_MAIL=$(curl -s ipinfo.io/$MAIL_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	[ -z "$WEBMAIL_RECORD" ] || IPINFO_WEBMAIL=$(curl -s ipinfo.io/$WEBMAIL_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	
	#echo $A_RECORD | /mnt/c/Windows/System32/clip.exe
	echo
	echo "NS record for $HOSTNAME"
	dig +short ns $HOSTNAME
	echo
	echo "A record for $HOSTNAME"
	dig +short a $HOSTNAME
	echo $IPINFO_A
	echo
	echo "MX record for $HOSTNAME"
	dig +short mx $HOSTNAME
	echo
	echo "A record for mail.$HOSTNAME"
	dig +short a mail.$HOSTNAME
	echo $IPINFO_MAIL
	echo "A record for webmail.$HOSTNAME"
	dig +short a webmail.$HOSTNAME
	echo $IPINFO_WEBMAIL
	echo
	echo "TXT record for $HOSTNAME"
	dig +short txt $HOSTNAME 
	echo
	echo "PTR record for $HOSTNAME"
	[ -z "$A_RECORD" ] || dig -x $A_RECORD | grep PTR
	echo
done
