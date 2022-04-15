#!/usr/bin/env bash
#Dig tool that checks NS , A , MX , TXT , PTR with IP Org

end="\033[0m"
darkyellow="\033[0;33m"
blue="\033[1;34m"
red="\033[0;31m"
lightred="\033[1;31m"
yellow="\033[1;33m"

header() { echo -e "${blue}${1}${end}" ; }
records() { echo -e "${darkyellow}${1}${end}" ; }
ipinfo_records() { echo -e "${lightred}${1}${end}" ; }
yellow() { echo -e "${yellow}${1}${end}" ; }
red() { echo -e "${red}${1}${end}" ; }
check_valid_ip() { grep -oE "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])" ; }
ipinfo_org_only() { grep "\"org\":" | xargs | cut -f1 -d "," ; }

while true; do
  unset hostname ns_record a_record mx_record mail_record webmail_record txt_record ptr_a_record ptr_a ptr_mail_record ptr_mail ptr_webmail_record ptr_webmail ipinfo_a_record ipinfo_mail_record ipinfo_webmail_record
  while true; do
    read -r -p "$(yellow "Input Hostname : ")" hostname </dev/tty
    if [[ -z ${hostname} ]]; then red "Please Input Hostname..." ; else break ; fi
  done
  ns_record=$(dig +short ns "${hostname}" @8.8.8.8 | sort)
  a_record=$(dig +short a "${hostname}" | sort)
  mx_record=$(dig +short MX "${hostname}" @8.8.8.8 | sort)
  mail_record=$(dig +short a mail."${hostname}" @8.8.8.8 | sort)
  webmail_record=$(dig +short a webmail."${hostname}" @8.8.8.8 | sort)
  txt_record=$(dig +short txt "${hostname}" @8.8.8.8 | sort)
  [[ -z ${a_record} ]] || ptr_a_record=$(echo "${a_record}" | check_valid_ip | while read -r ptr_a; do dig -x "${ptr_a}" @8.8.8.8 +noall +answer ; done)
  [[ -z ${mail_record} ]] || ptr_mail_record=$(echo "${mail_record}" | check_valid_ip | while read -r ptr_mail; do dig -x "${ptr_mail}" @8.8.8.8 +noall +answer ; done)
  [[ -z ${webmail_record} ]] || ptr_webmail_record=$(echo "${webmail_record}" | check_valid_ip | while read -r ptr_webmail; do dig -x "${ptr_webmail}" @8.8.8.8 +noall +answer ; done)
  [[ -z ${a_record} ]] || ipinfo_a_record=$(curl -s ipinfo.io/"$(echo "${a_record}" | head -n1)" | ipinfo_org_only)
  [[ -z ${mail_record} ]] || ipinfo_mail_record=$(curl -s ipinfo.io/"$(echo "${mail_record}" | head -n1)" | ipinfo_org_only)
  [[ -z ${webmail_record} ]] || ipinfo_webmail_record=$(curl -s ipinfo.io/"$(echo "${webmail_record}" | head -n1)" | ipinfo_org_only)
  echo
  header "NS record for ${hostname}"
  [[ -z ${ns_record} ]] || records "${ns_record}"
  echo
  header "A record for ${hostname}"
  [[ -z ${a_record} ]] || records "${a_record}"
  if [[ ${ptr_a_record} =~ "PTR" ]]; then records "${ptr_a_record}" ; fi
  [[ -z ${ipinfo_a_record} ]] || ipinfo_records "${ipinfo_a_record}"
  echo
  header "MX record for ${hostname}"
  [[ -z ${mx_record} ]] || records "${mx_record}"
  echo
  header "A record for mail.${hostname}"
  [[ -z ${mail_record} ]] || records "${mail_record}"
  if [[ ${ptr_mail_record} =~ "PTR" ]]; then records "${ptr_mail_record}" ; fi
  [[ -z ${ipinfo_mail_record} ]] || ipinfo_records "${ipinfo_mail_record}"
  echo
  header "A record for webmail.${hostname}"
  [[ -z ${webmail_record} ]] || records "${webmail_record}"
  if [[ ${ptr_webmail_record} =~ "PTR" ]]; then records "${ptr_webmail_record}" ; fi
  [[ -z ${ipinfo_webmail_record} ]] || ipinfo_records "${ipinfo_webmail_record}"
  echo
  header "TXT record for ${hostname}"
  [[ -z ${txt_record} ]] || records "${txt_record}"
  echo
done
