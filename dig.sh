#!/usr/bin/env bash

while [ 1 ]; do
	unset hostname A_RECORD MX_RECORD MAIL_RECORD IPINFO_A IPINFO_MAIL
	while [ 1 ]; do
		read -p "Input Hostname : " hostname </dev/tty
		[ -z "$hostname" ] && echo "Please Input Hostname..." || break
	done
	NS_RECORD=$(dig +short ns $hostname @8.8.8.8)
	A_RECORD=$(dig +short a $hostname @8.8.8.8)
	MX_RECORD=$(dig +short MX $hostname @8.8.8.8)
	MAIL_RECORD=$(dig +short a mail.$hostname @8.8.8.8)
	WEBMAIL_RECORD=$(dig +short a webmail.$hostname @8.8.8.8)
	TXT_RECORD=$(dig +short txt $hostname @8.8.8.8)
	[ -z "$A_RECORD" ] || PTR_RECORD=$(dig -x $A_RECORD @8.8.8.8 | grep "PTR")
	[ -z "$A_RECORD" ] || IPINFO_A=$(curl -s ipinfo.io/$A_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	[ -z "$MAIL_RECORD" ] || IPINFO_MAIL=$(curl -s ipinfo.io/$MAIL_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	[ -z "$WEBMAIL_RECORD" ] || IPINFO_WEBMAIL=$(curl -s ipinfo.io/$WEBMAIL_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	
	#echo $A_RECORD | /mnt/c/Windows/System32/clip.exe
	echo
	echo "NS record for $hostname"
	[ -z "$NS_RECORD" ] || printf "$NS_RECORD\n"
	echo
	echo "A record for $hostname"
	[ -z "$A_RECORD" ] || printf "$A_RECORD\n"
	[ -z "$A_RECORD" ] || echo $IPINFO_A
	echo
	echo "MX record for $hostname"
	[ -z "$MX_RECORD" ] || printf "$MX_RECORD\n"
	echo
	echo "A record for mail.$hostname"
	[ -z "$MAIL_RECORD" ] || printf "$MAIL_RECORD\n"
	[ -z "$MAIL_RECORD" ] || echo $IPINFO_MAIL
	echo
	echo "A record for webmail.$hostname"
	[ -z "$WEBMAIL_RECORD" ] || printf "$WEBMAIL_RECORD\n"
	[ -z "$WEBMAIL_RECORD" ] || echo $IPINFO_WEBMAIL
	echo
	echo "TXT record for $hostname"
	[ -z "$TXT_RECORD" ] || printf "$TXT_RECORD\n"
	echo
	echo "PTR record for $hostname"
	[ -z "$PTR_RECORD" ] || printf "$PTR_RECORD\n"
	echo
done
