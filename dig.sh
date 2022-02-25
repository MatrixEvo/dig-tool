#!/usr/bin/env bash

while [ 1 ]; do
	while [ 1 ]; do
		read -p "Input Hostname : " hostname
		[ -z "$hostname" ] && echo "Please Input Hostname..." || break
	done
	unset A_RECORD MX_RECORD MAIL_RECORD IPINFO_A IPINFO_MAIL
	A_RECORD=$(dig +short a $hostname)
	MX_RECORD=$(dig +short MX $hostname)
	MAIL_RECORD=$(dig +short a mail.$hostname)
	[ -z "$A_RECORD" ] && IPINFO_A="No IP Found" || IPINFO_A=$(curl -s ipinfo.io/$A_RECORD | grep org | xargs | cut -f1 -d ",")
	[ -z "$MAIL_RECORD" ] && IPINFO_MAIL="No IP Found" || IPINFO_MAIL=$(curl -s ipinfo.io/$MAIL_RECORD | grep org | xargs | cut -f1 -d ",")
	
	echo $A_RECORD | /mnt/c/Windows/System32/clip.exe
	echo
	echo "NS record for $hostname"
	dig +short ns $hostname
	echo
	echo "A record for $hostname"
	dig +short a $hostname
	echo $IPINFO_A
	echo
	echo "MX record for $hostname"
	dig +short mx $hostname
	echo
	echo "A record for mail.$hostname"
	dig +short a mail.$hostname
	echo $IPINFO_MAIL
	echo
	echo "TXT record for $hostname"
	dig +short txt $hostname 
	echo
	echo "PTR record for $hostname"
	[ -z "$A_RECORD" ] && echo "No IP Found" || dig -x $A_RECORD | grep PTR
	echo
done