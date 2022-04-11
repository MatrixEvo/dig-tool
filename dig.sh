#!/usr/bin/env bash
#Dig tool that checks NS , A , MX , TXT , PTR with IP Org

end="\033[0m"
darkyellow="\033[0;33m"
blue="\033[1;34m"
red="\033[0;31m"
lightred="\033[1;31m"
yellow="\033[1;33m"

function header() { echo -e "${blue}${1}${end}" ; }
function records() { echo -e "${darkyellow}${1}${end}" ; }
function ipinforecords() { echo -e "${lightred}${1}${end}" ; }
function yellow() { echo -e "${yellow}${1}${end}" ; }
function red() { echo -e "${red}${1}${end}" ; }

while true; do
  unset HOSTNAME NS_RECORD A_RECORD MX_RECORD MAIL_RECORD WEBMAIL_RECORD TXT_RECORD PTR_RECORD IPINFO_A IPINFO_MAIL IPINFO_WEBMAIL
  while true; do
    read -r -p "$(yellow "Input Hostname : ")" HOSTNAME </dev/tty
    if [ -z "${HOSTNAME}" ]; then
      red "Please Input Hostname..."
    else
      break
    fi
  done
  NS_RECORD=$(dig +short ns "${HOSTNAME}" @8.8.8.8 | sort)
  A_RECORD=$(dig +short a "${HOSTNAME}" | sort)
  MX_RECORD=$(dig +short MX "${HOSTNAME}" @8.8.8.8 | sort)
  MAIL_RECORD=$(dig +short a mail."${HOSTNAME}" @8.8.8.8 | sort)
  WEBMAIL_RECORD=$(dig +short a webmail."${HOSTNAME}" @8.8.8.8 | sort)
  TXT_RECORD=$(dig +short txt "${HOSTNAME}" @8.8.8.8 | sort)
  [ -z "${A_RECORD}" ] || PTR_RECORD=$(dig -x "${A_RECORD}" @8.8.8.8 | grep "PTR" | sort)
  [ -z "${A_RECORD}" ] || IPINFO_A=$(curl -s ipinfo.io/"$(echo "${A_RECORD}" | head -n1)" | grep "\"org\":" | xargs | cut -f1 -d ",")
  [ -z "$MAIL_RECORD" ] || IPINFO_MAIL=$(curl -s ipinfo.io/"$(echo "${MAIL_RECORD}" | head -n1)" | grep "\"org\":" | xargs | cut -f1 -d ",")
  [ -z "$WEBMAIL_RECORD" ] || IPINFO_WEBMAIL=$(curl -s ipinfo.io/"$(echo "${WEBMAIL_RECORD}" | head -n1)" | grep "\"org\":" | xargs | cut -f1 -d ",")
  echo
  header "NS record for ${HOSTNAME}"
  [ -z "${NS_RECORD}" ] || printf "%s\n" "$(records "${NS_RECORD}")"
  echo
  header "A record for ${HOSTNAME}"
  [ -z "${A_RECORD}" ] || printf "%s\n" "$(records "${A_RECORD}")"
  [ -z "${IPINFO_A}" ] || ipinforecords "${IPINFO_A}"
  echo
  header "MX record for ${HOSTNAME}"
  [ -z "${MX_RECORD}" ] || printf "%s\n" "$(records "${MX_RECORD}")"
  echo
  header "A record for mail.${HOSTNAME}"
  [ -z "${MAIL_RECORD}" ] || printf "%s\n" "$(records "${MAIL_RECORD}")"
  [ -z "${IPINFO_MAIL}" ] || ipinforecords "${IPINFO_MAIL}"
  echo
  header "A record for webmail.${HOSTNAME}"
  [ -z "${WEBMAIL_RECORD}" ] || printf "%s\n" "$(records "${WEBMAIL_RECORD}")"
  [ -z "${IPINFO_WEBMAIL}" ] || ipinforecords "${IPINFO_WEBMAIL}"
  echo
  header "TXT record for ${HOSTNAME}"
  [ -z "${TXT_RECORD}" ] || printf "%s\n" "$(records "${TXT_RECORD}")"
  echo
  header "PTR record for ${HOSTNAME}"
  [ -z "${PTR_RECORD}" ] || printf "%s\n" "$(records "${PTR_RECORD}")"
  echo
done
