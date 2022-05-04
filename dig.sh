#!/usr/bin/env bash
#Dig tool that checks NS , A , MX , TXT , PTR with IP Org
#Try using without downloading >" curl -s https://raw.githubusercontent.com/MatrixEvo/dig-tool/main/dig.sh | bash "<

end="\033[0m"
darkyellow="\033[0;33m"
blue="\033[1;34m"
red="\033[0;31m"
lightred="\033[1;31m"
yellow="\033[1;33m"
HISTCONTROL=erasedups

header() {
  echo -e "${blue}${1}${end}"
}

records() {
  if [[ -n "${1}" ]]; then
    echo -e "${darkyellow}${1}${end}"
  fi
}

ipinfo_records() {
  if [[ -n "${1}" ]]; then
    echo -e "${lightred}${1}${end}"
  fi
}

yellow() {
  echo -e "${yellow}${1}${end}"
}

red() {
  echo -e "${red}${1}${end}"
}

check_valid_ip() {
  grep -oE "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"
}

check_ptr() {
  if [[ -n "${1}" ]]; then
    local ptr
    echo "${1}" | check_valid_ip | while read -r ptr; do
      dig +noall +answer -x "${ptr}" @8.8.8.8
    done
  fi
}

ipinfo_org_only() {
  if [[ -n "${1}" ]]; then
    local ipinfo
    echo "${1}" | check_valid_ip | while read -r ipinfo; do
      curl -s ipinfo.io/"${ipinfo}" | grep "\"org\":" | xargs | cut -d',' -f1
    done
  fi
}

dig_short() {
  dig +short @8.8.8.8 "${1}" "${2}" 2>&1 | grep -v "empty label" | sort
}

check_hostname() {
  local hostnamedotcount roothostname ns_record a_record mx_record mail_record webmail_record txt_record ptr_a_record ptr_mail_record ptr_webmail_record ipinfo_a_record ipinfo_mail_record ipinfo_webmail_record
  # Checking for root hostname without subdomain
  hostnamedotcount=$(echo "${hostname}" | grep -o "\." | wc -l)
  roothostname="${hostname}"
  if [[ ${hostnamedotcount} -gt 1 ]]; then
    roothostname=$(echo "${hostname}" | cut -d'.' -f"${hostnamedotcount}"-)
    if [[ ${#roothostname} == 6 ]] && [[ ${roothostname:0:3} =~ com|org|net|int|edu|gov|mil|biz ]]; then
      roothostname=$(echo "${hostname}" | cut -d'.' -f"$(("${hostnamedotcount}" - 1))"-)
    fi
  fi
  # GATHERING INFO
  ns_record=$(dig_short ns "${roothostname}")
  a_record=$(dig_short a "${hostname}")
  mx_record=$(dig_short mx "${hostname}")
  mail_record=$(dig_short a "mail.${hostname}")
  webmail_record=$(dig_short a "webmail.${hostname}")
  txt_record=$(dig_short txt "${hostname}")
  # Error If No Info Found
  if [[ -z ${ns_record} ]] && [[ -z ${a_record} ]] && [[ -z ${mx_record} ]] && [[ -z ${mail_record} ]] && [[ -z ${webmail_record} ]] && [[ -z ${txt_record} ]]; then
    history -d "$(history 1 | awk '{print $1}')"
    red "Please Input Valid IP / Hostname... or Domain Not Found"
    return
  fi
  ptr_a_record=$(check_ptr "${a_record}")
  ptr_mail_record=$(check_ptr "${mail_record}")
  ptr_webmail_record=$(check_ptr "${webmail_record}")
  ipinfo_a_record=$(ipinfo_org_only "${a_record}")
  ipinfo_mail_record=$(ipinfo_org_only "${mail_record}")
  ipinfo_webmail_record=$(ipinfo_org_only "${webmail_record}")
  # OUTPUT BELOW
  echo
  header "NS record for ${roothostname}"
  records "${ns_record}"
  echo
  header "A record for ${hostname}"
  records "${a_record}"
  records "${ptr_a_record}"
  ipinfo_records "${ipinfo_a_record}"
  echo
  header "MX record for ${hostname}"
  records "${mx_record}"
  echo
  header "A record for mail.${hostname}"
  records "${mail_record}"
  records "${ptr_mail_record}"
  ipinfo_records "${ipinfo_mail_record}"
  echo
  header "A record for webmail.${hostname}"
  records "${webmail_record}"
  records "${ptr_webmail_record}"
  ipinfo_records "${ipinfo_webmail_record}"
  echo
  header "TXT record for ${hostname}"
  records "${txt_record}"
  echo
}

check_ip() {
  local ptr_a_record ipinfo_a_record
  # GATHERING INFO
  ptr_a_record=$(check_ptr "${ip}")
  ipinfo_a_record=$(ipinfo_org_only "${ip}")
  # OUTPUT BELOW
  echo
  header "A record for ${ip}"
  records "${ip}"
  records "${ptr_a_record}"
  ipinfo_records "${ipinfo_a_record}"
  echo
}

start() {
  while IFS= read -rep "$(yellow "Input IP / Hostname : ")" inputhostname </dev/tty ; do
    unset ip hostname
    ip=$(echo "${inputhostname}" | check_valid_ip | head -n1)
    hostname=$(echo "${inputhostname}" | tr '[:upper:]' '[:lower:]' | sed 's/[=+,\"<> !@#$%^&*()\/:?;_]/\n/g' | grep "\." | head -n1 )

    if [[ -z ${ip} ]] && [[ -z ${hostname} ]] || [[ ${#hostname} -le 3 ]] || [[ -z $(echo "${hostname}" | cut -d'.' -f1) ]] || [[ -z $(echo "${hostname}" | cut -d'.' -f2) ]];then
      red "Please Input Valid IP / Hostname..."
      break
    fi

    if [[ -n ${ip} ]]; then
      history -s "${ip}"
      check_ip
    elif [[ -n ${hostname} ]] ;then
      history -s "${hostname}"
      check_hostname
    fi
  done
}

while true; do
  start
done
