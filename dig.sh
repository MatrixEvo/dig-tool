#!/usr/bin/env bash

while [ 1 ]; do
	unset HOSTNAME NS_RECORD A_RECORD MX_RECORD MAIL_RECORD WEBMAIL_RECORD TXT_RECORD PTR_RECORD IPINFO_A IPINFO_MAIL IPINFO_WEBMAIL
	while [ 1 ]; do
		read -p "Input Hostname : " HOSTNAME </dev/tty
		[ -z "$HOSTNAME" ] && echo "Please Input Hostname..." || break
	done
	NS_RECORD=$(dig +short ns $HOSTNAME @8.8.8.8 | sort)
	A_RECORD=$(dig +short a $HOSTNAME | sort)
	MX_RECORD=$(dig +short MX $HOSTNAME @8.8.8.8 | sort)
	MAIL_RECORD=$(dig +short a mail.$HOSTNAME @8.8.8.8 | sort)
	WEBMAIL_RECORD=$(dig +short a webmail.$HOSTNAME @8.8.8.8 | sort)
	TXT_RECORD=$(dig +short txt $HOSTNAME @8.8.8.8 | sort)
	[ -z "$A_RECORD" ] || PTR_RECORD=$(dig -x $A_RECORD @8.8.8.8 | grep "PTR" | sort)
	[ -z "$A_RECORD" ] || IPINFO_A=$(curl -s ipinfo.io/$A_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	[ -z "$MAIL_RECORD" ] || IPINFO_MAIL=$(curl -s ipinfo.io/$MAIL_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	[ -z "$WEBMAIL_RECORD" ] || IPINFO_WEBMAIL=$(curl -s ipinfo.io/$WEBMAIL_RECORD | grep "\"org\":" | xargs | cut -f1 -d ",")
	
	#echo $A_RECORD | /mnt/c/Windows/System32/clip.exe
	echo
	echo "NS record for $HOSTNAME"
	[ -z "$NS_RECORD" ] || printf "$NS_RECORD\n"
	echo
	echo "A record for $HOSTNAME"
	[ -z "$A_RECORD" ] || printf "$A_RECORD\n"
	[ -z "$IPINFO_A" ] || echo "$IPINFO_A"
	echo
	echo "MX record for $HOSTNAME"
	[ -z "$MX_RECORD" ] || printf "$MX_RECORD\n"
	echo
	echo "A record for mail.$HOSTNAME"
	[ -z "$MAIL_RECORD" ] || printf "$MAIL_RECORD\n"
	[ -z "$IPINFO_MAIL" ] || echo "$IPINFO_MAIL"
	echo
	echo "A record for webmail.$HOSTNAME"
	[ -z "$WEBMAIL_RECORD" ] || printf "$WEBMAIL_RECORD\n"
	[ -z "$IPINFO_WEBMAIL" ] || echo "$IPINFO_WEBMAIL"
	echo
	echo "TXT record for $HOSTNAME"
	[ -z "$TXT_RECORD" ] || printf "$TXT_RECORD\n"
	echo
	echo "PTR record for $HOSTNAME"
	[ -z "$PTR_RECORD" ] || printf "$PTR_RECORD\n"
	echo
done
