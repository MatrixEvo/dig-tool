#!/usr/bin/env bash

# Dig tool that checks NS , A , MX , TXT , PTR with IP Org
# Try using without downloading >" curl -4sL https://matrixevo.com/dig.sh | bash -s "<
# Try using without downloading and COLOR >" curl -4sL https://matrixevo.com/dig.sh | bash -s -- --color "<

# Quick Install >   echo "alias digg='curl -4sL https://matrixevo.com/dig.sh | bash -s -- --color'" >> ~/.bashrc && source ~/.bashrc
# Run using the command "digg"

HISTCONTROL=erasedups
history_file="${HOME}/.digg_history"
TIMEFORMAT="Time Taken : %R seconds"
today="$(date +"%d-%m-%Y")"

# Default DNS Server
dns_server="8.8.8.8"

# add your IPInfo.io API key if available
ipinfo_api_key=""

set -o pipefail # This sets the 'pipefail' option to ensure that pipelines of commands fail if any command fails.
shopt -s nocasematch # enable case-insensitive matching

if [[ -f "${history_file}" ]]; then
  history -r "${history_file}"
else
  history -s "============================== History Started on ${today} =============================="
  history -w "${history_file}"
fi

color_toggle() {
  if [[ ${1} == "on" ]]; then
    end="\033[0m"
    darkyellow="\033[0;33m"
    blue="\033[1;34m"
    red="\033[0;31m"
    lightred="\033[1;31m"
    yellow="\033[1;33m"
  else
    end=""
    darkyellow=""
    blue=""
    red=""
    lightred=""
    yellow=""
  fi
}

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
  echo -e "${red}${1}${end}\n"
}

check_valid_ipv4() {
  grep -oE "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])"
}

check_ptr() {
  if [[ -n "${1}" ]]; then
    local ptr
    echo "${1}" | check_valid_ipv4 | while read -r ptr; do
      dig -4 +noall +answer -x "${ptr}" @"${dns_server}"
    done
    unset ptr
  fi
}

ipinfo_org_only() {
  if [[ -n "${1}" ]]; then
    local ipinfo
    echo "${1}" | check_valid_ipv4 | while read -r ipinfo; do
      check_ipinfo "${ipinfo}" | grep "\"org\":" | xargs | sed 's/.$//'
    done
    unset ipinfo
  fi
}

curl4() {
  timeout 3 curl -4sSL "${1}"
}

dig_short() {
  if [[ ${1} ]] && [[ ${2} ]]; then
    timeout 10 dig -4 +short @"${dns_server}" "${1}" "${2}" 2>&1 | grep -v "empty label" | sort -h
  fi
}

check_ipinfo() {
  curl4 "ipinfo.io/${1}?token=${ipinfo_api_key}" || echo "Error with IPInfo - ${1}"
}

check_hostname() {
  local hostnamedotcount roothostname ns_name ns_record a_record mx_record mail_record webmail_record txt_record ptr_a_record ptr_mail_record ptr_webmail_record ipinfo_a_record ipinfo_mail_record ipinfo_webmail_record
  # GATHERING INFO
  ns_record=$(dig_short NS ${1})
  if [[ -z ${ns_record} ]]; then
    # Checking for root hostname without subdomain
    hostnamedotcount=$(echo "${1}" | grep -o "\." | wc -l)
    roothostname="${1}"
    if [[ ${hostnamedotcount} -gt 1 ]]; then
      roothostname=$(echo "${1}" | cut -d'.' -f"${hostnamedotcount}"-)
      if [[ ${#roothostname} =~ 5|6 ]] && [[ ${roothostname:0:3} =~ co|com|org|net|int|edu|gov|mil|biz ]]; then
        roothostname=$(echo "${1}" | cut -d'.' -f"$(("${hostnamedotcount}" - 1))"-)
      fi
    fi
    ns_name="${roothostname}"
    ns_record=$(dig_short NS "${roothostname}")
  else
    ns_name=${1}
  fi
  a_record=$(dig_short A "${1}")
  mx_record=$(dig_short MX "${1}")
  mail_record=$(dig_short A "mail.${1}")
  webmail_record=$(dig_short A "webmail.${1}")
  txt_record=$(dig_short TXT "${1}")
  # Error If No Info Found
  if [[ -z ${ns_record} ]] && [[ -z ${a_record} ]] && [[ -z ${mx_record} ]] && [[ -z ${mail_record} ]] && [[ -z ${webmail_record} ]] && [[ -z ${txt_record} ]]; then
    # history -d "$(history 1 | awk '{print $1}')" - Uncomment to delete the last invalid entry from history
    red "Please Input Valid IP / Hostname... or Domain ${1} Not Found or No DNS Records"
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
  header "NS record for ${ns_name}"
  records "${ns_record}"
  echo
  header "A record for ${1}"
  records "${a_record}"
  records "${ptr_a_record}"
  ipinfo_records "${ipinfo_a_record}"
  echo
  header "MX record for ${1}"
  records "${mx_record}"
  echo
  header "A record for mail.${1}"
  records "${mail_record}"
  records "${ptr_mail_record}"
  ipinfo_records "${ipinfo_mail_record}"
  echo
  header "A record for webmail.${1}"
  records "${webmail_record}"
  records "${ptr_webmail_record}"
  ipinfo_records "${ipinfo_webmail_record}"
  echo
  header "TXT record for ${1}"
  records "${txt_record}"
  echo
  unset hostnamedotcount roothostname ns_name ns_record a_record mx_record mail_record webmail_record txt_record ptr_a_record ptr_mail_record ptr_webmail_record ipinfo_a_record ipinfo_mail_record ipinfo_webmail_record
}

check_ip() {
  local ptr_a_record ipinfo_a_record
  # GATHERING INFO
  ptr_a_record=$(check_ptr "${1}")
  ipinfo_a_record=$(check_ipinfo "${1}" | sed 's/\"/ /g')
  # OUTPUT BELOW
  echo
  header "PTR :"
  echo
  records "${ptr_a_record}"
  echo
  header "IPInfo :"
  ipinfo_records "${ipinfo_a_record}"
  echo
  unset ptr_a_record ipinfo_a_record
}

additional_functions() {
  echo
  if [[ ${1} == "?" ]] || [[ ${1} == "help" ]]; then
    header "Dig tool that checks NS , A , MX , TXT , PTR with IP Org from ipinfo.io"
    header "By MatrixEvo"
    header "Last Updated - 27th June 2023"
    echo
    yellow "Functions Available :"
    echo "  debug <on|off> - Turns on or off debug mode for this script"
    echo "  color <on|off> - Turns this script color on or off"
    echo "  history <search> - View or Search Input History"
    echo "  chist - Clear Input History"
    echo "  clear - Clear screen"
    echo "  dns <DNS Server> - Change the Currently used DNS Server"
    echo "  repeat <count> <function> - repeats function ( Default 3 times )"
    echo "  pmp - Today's PMP Code"
    echo "  ip - Your Current Public IP"
    echo "  whois <Domain> - WHOIS info for the domain"
    echo "  mail <Domain> - check DNS records essential for successful mail delivery"
    echo "  pass <length> <count> - Password Generator ( Default 16 length - 5x )"
    echo
    yellow "Connectivity Checks :"
    echo "  ping <Domain or IP> - ping 4 times , timeout 1 second"
    echo "  web <Domain or IP> - Check HTTP Response Code"
    echo "  nc or telnet <Domain or IP> - Check if generally used port is open"
    echo "  nc or telnet <Domain or IP> <Port Number> - Check if specific port is open"
    echo
    yellow "SSL Related :"
    echo "  ssl <Domain or IP> <Port> - Check SSL Details (Default Port 443)"
    echo "  gencsr - Generate SSL CSR"
    echo "  p2p - Convert SSL CRT to PFX for Windows"
    echo "  alphassl - Print out AlphaSSL Intermediate Cert and GlobalSign Root Cert"
    echo "  orgssl - Print out Organization Validated Intermediate Cert and GlobalSign Root Cert"
    echo "  letsencrypt - Print out Let's Encrypt R3 Intermediate and ISRG Root X1 Cert"
  elif [[ ${1} =~ ^"debug" ]]; then
    if [[ ${2} == "on" ]] || [[ -z ${2} ]]; then
      echo "Turning Debug On"
      set -x
    elif [[ ${2} == "off" ]]; then
      echo "Turning Debug Off"
      set +x
    fi
  elif [[ ${1} =~ ^"color" ]]; then
    if [[ ${2} == "on" ]] || [[ -z ${2} ]]; then
      echo "Turning Color On"
      color_toggle "on"
    elif [[ ${2} == "off" ]]; then
      echo "Turning Color Off"
      color_toggle "off"
    fi
  elif [[ ${1} == "history" ]]; then
    if [[ -z ${2} ]]; then
      history
    else
      history | grep "${2}"
    fi
  elif [[ ${1} == "chist" ]]; then
    echo "History Cleared on ${today}" > "${history_file}"
  elif [[ ${1} == "clear" ]]; then
    reset
    clear
  elif [[ ${1} == "dns" ]]; then
    if [[ -z ${2} ]]; then
      echo "dns <IP or Domain Name of DNS Server> - Change the Currently used DNS Server"
      echo "dns g - Google - 8.8.8.8"
      echo "dns c - Cloudflare - 1.1.1.1"
      echo "dns o - OpenDNS - 208.67.222.222"
      echo "dns u1 - Hosted Unbound DNS 1 - 183.81.162.41"
      echo "dns u2 - Hosted Unbound DNS 2 - 14.102.148.71"
    elif [[ "${2}" == "g" ]]; then
      dns_server="8.8.8.8"
    elif [[ "${2}" == "c" ]]; then
      dns_server="1.1.1.1"
    elif [[ "${2}" == "o" ]]; then
      dns_server="208.67.222.222"
    elif [[ "${2}" == "u1" ]]; then
      dns_server="183.81.162.41"
    elif [[ "${2}" == "u2" ]]; then
      dns_server="14.102.148.71"
    elif [[ -n $(check_valid_ipv4 <<<"${2}") ]]; then
      dns_server="$(check_valid_ipv4 <<<"${2}")"
    elif [[ -n $(echo "${2}" | tr '[:upper:]' '[:lower:]' | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1) ]]; then
      dns_server="$(echo "${2}" | tr '[:upper:]' '[:lower:]' | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1)"
      while [[ ${dns_server: -1} == "." ]] || [[ ${dns_server::1} == "." ]]; do # Trim front and back extra dots (.)
        if [[ ${dns_server: -1} == "." ]]; then # Trim Back
          dns_server="${dns_server%?}"
        fi
        if [[ ${dns_server::1} == "." ]]; then # Trim Front
          dns_server="${dns_server: 1}"
        fi
      done
    else
      dns_server="8.8.8.8"
      echo "${2} is Invalid , reverting to use 8.8.8.8"
    fi
  elif [[ ${1} == "pmp" ]]; then
    curl4 https://pmp.matrixevo.com
  elif [[ ${1} =~ ^"pass" ]]; then
    curl4 https://matrixevo.com/passwordgenerator.sh | bash -s -- "${2}" "${3}"
  elif [[ ${1} == "ip" ]]; then
    curl4 https://ip.matrixevo.com
  elif [[ ${1} =~ ^"whois" ]]; then
    curl4 https://matrixevo.com/checkwhois.sh | bash -s -- "${2}"
  elif [[ ${1} =~ ^"nc" ]] || [[ ${1} =~ ^"telnet" ]]; then
    curl4 https://matrixevo.com/checkport.sh | bash -s -- "${2}" "${3}"
  elif [[ ${1} =~ ^"ping" ]]; then
    curl4 https://matrixevo.com/checkping.sh | bash -s -- "${2}"
  elif [[ ${1} =~ ^"web" ]]; then
    if [[ -z ${2} ]]; then
      echo "web <Domain or IP> - Check HTTP Response Code"
    else
      curl4 https://matrixevo.com/checkhttpresponse.sh | bash -s -- "${2}"
    fi
  elif [[ ${1} == "gencsr" ]]; then
    curl4 https://matrixevo.com/gencsr.sh | bash
  elif [[ ${1} == "p2p" ]]; then
    curl4 https://matrixevo.com/convert_pem_to_pfx.sh | bash
  elif [[ ${1} =~ ^"ssl" ]]; then
    curl4 https://matrixevo.com/checksslstatus.sh | bash -s -- "${2}" "${3}"
  elif [[ ${1} == "alphassl" ]]; then
    curl4 https://matrixevo.com/AlphaSSLCA_GlobalSignRootR1.crt
  elif [[ ${1} == "orgssl" ]]; then
    curl4 https://matrixevo.com/GlobalSignOV_GlobalSignRoot.crt
  elif [[ ${1} == "letsencrypt" ]]; then
    curl4 https://matrixevo.com/LetsEncryptR3_ISRGRootX1.crt
  elif [[ ${1} =~ ^"mail" ]]; then
    if [[ -z ${2} ]]; then
      echo "mail <Domain> - check DNS records essential for successful mail delivery"
    else
      curl4 https://matrixevo.com/checkmail.sh | bash -s -- "${2}" "${dns_server}" --color
    fi
  fi
  echo
}

repeat_functions() {
  local command count repeat_times
  count=0
  echo
  if [[ -z ${2} && -z ${3} ]] || [[ ${2} =~ ^[0-9]+$ && -z ${3} ]]; then
    echo "repeat <count> <function> - repeats function ( Default 3 times )"
  elif [[ ${2} ]]; then
    if [[ ! ${2} =~ ^[0-9]+$ ]]; then
      command=${@/#repeat/}
      repeat_times=3
    else
      command=$(cut -d' ' -f2- <<< ${@/#repeat/})
      repeat_times="${2}"
      while [[ ${repeat_times::1} == "0" ]]; do
        repeat_times="${repeat_times/#0/}"
        if [[ -z ${repeat_times} ]]; then
          repeat_times=3
        fi
      done
    fi
    while [[ ! ${count} == ${repeat_times} ]]; do
      ((count++))
      echo "Repeating - ${count}/${repeat_times} - ${command}"
      additional_functions ${command}
    done
  fi
  echo
  unset command count repeat_times
}

filter() {
  local ip hostname
  if [[ ${1} =~ ^(ping |pass |whois |mail |nc |telnet |web |ssl |debug |dns |history |color ) ]] || \
    [[ ${1} =~ ^(\?|alphassl|debug|color|chist|clear|dns|gencsr|help|history|ip|mail|nc|orgssl|p2p|pass|ping|pmp|ssl|telnet|web|whois|letsencrypt)$ ]]; then
    history -s "${1}"
    additional_functions ${@}
    return
  elif [[ ${1} == "repeat" ]] || [[ ${1} =~ ^"repeat " ]]; then
    history -s "${1}"
    repeat_functions ${@}
    return
  fi

  ip=$(echo "${1}" | check_valid_ipv4 | head -n1)
  hostname=$(echo "${1}" | tr '[:upper:]' '[:lower:]' | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1 )

  if [[ -z ${ip} ]] && [[ -z ${hostname} ]] || [[ ${#hostname} -le 3 ]]; then
    red "Please Input Valid IP / Hostname..."
  elif [[ -n ${ip} ]]; then
    history -s "${ip}"
    check_ip "${ip}"
  elif [[ -n ${hostname} ]] ; then
    while [[ ${hostname: -1} == "." ]] || [[ ${hostname::1} == "." ]]; do # Trim front and back extra dots (.)
      if [[ ${hostname: -1} == "." ]]; then # Trim Back
        hostname="${hostname%?}"
      fi
      if [[ ${hostname::1} == "." ]]; then # Trim Front
        hostname="${hostname: 1}"
      fi
    done
    history -s "${hostname}"
    check_hostname "${hostname}"
  fi
  unset ip hostname
}

start() {
  local user_input
  if ! grep -q "${today}" "${history_file}"; then
    history -s "============================== ${today} =============================="
    history -w "${history_file}"
  fi
  if [[ $1 ]] && [[ ! $1 == "--color" ]]; then
    user_input=${@/#--color /}
    time filter "${user_input}"
  else
    while IFS= read -rep "$(yellow "Current DNS Server : ${dns_server} - Input IP / Hostname : ")" user_input </dev/tty ; do
      time filter "${user_input}"
      history -w "${history_file}"
      unset user_input
    done
  fi
}

if [[ $* =~ "--color" ]]; then
  color_toggle "on"
fi

start "${*}"
