#!/usr/bin/env bash

# Dig tool that checks NS , A , MX , TXT , PTR with IP Org
# Try using without downloading >" curl -4sL https://matrixevo.com/dig.sh | bash -s "<
# Try using without downloading and COLOR >" curl -4sL https://matrixevo.com/dig.sh | bash -s -- --color "<

# Quick Install >   echo "alias digg='curl -4sL https://matrixevo.com/dig.sh | bash -s -- --color'" >> ~/.bashrc && source ~/.bashrc
# Run using the command "digg"

HISTCONTROL=erasedups
history_file="${HOME}/.digg_history"
mys1a_cloud_hosting_ip_list="${HOME}/.digg_mys1a_cloud_hosting_ip_list"
sgp1a_cloud_hosting_ip_list="${HOME}/.digg_sgp1a_cloud_hosting_ip_list"
hkg1a_cloud_hosting_ip_list="${HOME}/.digg_hkg1a_cloud_hosting_ip_list"
staging_cloud_hosting_ip_list="${HOME}/.digg_staging_cloud_hosting_ip_list"
TIMEFORMAT="Time Taken : %R seconds"

# Default DNS Server
dns_server="8.8.8.8"

# Default IP Datasource ( ipinfo.io / ipapi.is )
ip_datasource="ipinfo.io"

set -o pipefail # This sets the 'pipefail' option to ensure that pipelines of commands fail if any command fails.
shopt -s nocasematch # enable case-insensitive matching

if [[ ! "$(command -v jq)" ]]; then
  echo "jq not installed..."
  sudo apt update && sudo apt install -y jq
fi

if [[ -f "${history_file}" ]]; then
  history -r "${history_file}"
else
  history -w "${history_file}"
fi

spin() {
  sp='/-\|'
  sc="0"
  sn="${#sp}"
  while true; do
    printf '\r%s Checking.' "${sp:sc++%sn:1}"
    sleep 0.1
    printf '\r%s Checking..' "${sp:sc++%sn:1}"
    sleep 0.1
    printf '\r%s Checking...' "${sp:sc++%sn:1}"
    sleep 0.1
  done
}

end_spin() {
  kill "${spin_pid}" &>/dev/null && printf '\r%s\r' "$(printf ' %.0s' {1..40})"
}

bannerColor() {
  local msg="${2} ${1} ${2}"
  local edge
  edge=${msg//?/$2}
  tput setaf 3
  tput bold
  echo "${edge}"
  echo "${msg}"
  echo "${edge}"
  tput sgr 0
  echo
}

create_dir() { # Create Directory if does not exist
  if [[ $# -ge 1 ]]; then
    for dir in "${@}"; do
      if [[ ! -d "${dir}" ]]; then
        if mkdir -p "${dir}" ; then
          echo "Created Directory - ${dir}"
        fi
      fi
    done
  fi
}

get_input() {
  local user_input
  while [[ -z "${user_input}" ]]; do
    read -rep "${1} : " user_input </dev/tty
  done
  echo "${user_input}"
  unset user_input
}

echo_color() { # Function to print text in the specified color
  local color_var text
  color_var="${1}"
  text="${2}"

  if [[ -n ${text} ]]; then
    # Using indirect reference to apply the color
    if [[ ${color_var} == "red" ]]; then
      echo -e "${!color_var}${text}${end}\n" >&2
    else
      echo -e "${!color_var}${text}${end}"
    fi
  fi
  unset color_var text
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

curl4() {
  timeout 2 curl -4sSL "${1}" 2>&1
}

dig_short() {
  if [[ ${1} ]] && [[ ${2} ]]; then
    timeout 3 dig -4 +timeout=1 +tries=3 +short @"${dns_server}" "${1}" "${2}" 2>/dev/null | grep -v "empty label\|timed out\|${dns_server}" | sort -h
  fi
}

check_ipinfo() {
  local ipinfo_response
  if [[ ${ip_datasource} == "ipapi.is" ]]; then
    ipinfo_response="$(curl4 "https://api.ipapi.is?q=${1}" | jq -r '{ip: .ip, country: .location.country_code, org: "AS\(.asn.asn) \(.asn.org)", timezone: .location.timezone}')"
  elif [[ ${ip_datasource} == "ipinfo.io" ]]; then
    ipinfo_response="$(curl4 "https://ipinfo.io/${1}" | jq -r '. | {ip: .ip , country: .country , org: .org , timezone: .timezone}')"
  fi
  echo "${ipinfo_response}"
  unset ipinfo_response
}

ipinfo_org_only() {
  if [[ -n "${1}" ]]; then
    local ipinfo response
    check_valid_ipv4 <<< "${1}" | while read -r ipinfo; do
      response=$(check_ipinfo "${ipinfo}" | jq -r '. | "org : \(.org)"')
      if [[ ${response} =~ ASnull ]]; then
        response=""
      fi
      echo "${response}"
    done
    unset ipinfo response
  fi
}

initialize_cloud_hosting_ip_list() {
  local mys_base64 sgp_base64 hkg_base64 stg_base64
  if [[ ! -f "${mys1a_cloud_hosting_ip_list}" ]] || ! sha256sum -c <<< "83cc716bde8851e8b605f937db1bd470f6b1d1211ba7c8caa7683d9b23d879e4  ${HOME}/.digg_mys1a_cloud_hosting_ip_list" &>/dev/null ; then
    mys_base64='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
    +lH1o+pH1Y96v+ANw68dg/i8Z/CmwbsGbxu8b/DGQf2o+lH1o8tbGvGpH1U/qn5U/aj6UfWj6kfV
    j6of3d5ziU/9qPpR9aPqR9WPqh9VP6p+VP3o7U3h5HuxI3+xI3+xI3+xI3+xI3//8O988OnFp4NP
    H6cLhjQhTsgTAoVEIVLIFEKFVCVV9TMiVUlVUpVUJVVJVVKVVItUi1RL/3SkWqRapFqkWqRapFqk
    2qTapNqk2vpGkWqTapNqk2qTapPqJtVNqptUN6lufdFJdZPqJtVNqptUD6keUj2kekj1kOrR7x+p
    HlI9pHpI9ZLqJdVLqpdUL6leUr3SAqleUr2kOqQ6pDqkOqQ6pDqkOqQ6shWpDqk+Un2k+kj1keoj
    1Ueqj1QfqT5J1BaVRi959JJIL5n0kkovufSSTC/Z9JJOL/H90rz4LHqb3qq36y172966l+8j4afu
    kPjk/Ej6kfUj7Ufej8QfmT9Sf+T+LIdSfNJ/5P8oAFEBogREDYgiEFUgykC2Sy4+lSBKQdSCKAZR
    DaIcRD2IghAVIbeXGuJTFKIqRFmIuhCFISpDlIaoDVEc8ngtJD71IQpEVIgoEVEjokhElYgyEXUi
    rxdr4lMqolZEsYhqEeUi6kUUjKgYUTJyvJoUn6oRZSPqRhSOqBxROqJ2RPGI6pHPy12vd7XgVT+q
    flT9qPpR9aPqR9WPqh9VPxovyMWnflT9qPpR9aPqR9WPqh/1fsEbhl87BvF5z+BNg3cN3jZ43+CN
    g/pR9aPqR5e3NOJTP6p+VP2o+lH1o+pH1Y+qH1U/ur3nEp/6UfWj6kfVj6ofVT+qflT9qPrR25vC
    yXewIz/YkR/syA925Ac78vOHf+eDTy8+HXz6OF0wpAlxQp4QKCQKkUKmECqkKqmqnxGpSqqSqqQq
    qUqqkqqkWqRapFr6pyPVItUi1SLVItUi1SLVJtUm1SbV1jeKVJtUm1SbVJtUm1Q3qW5S3aS6SXXr
    i06qm1Q3qW5S3aR6SPWQ6iHVQ6qHVI9+/0j1kOoh1UOql1QvqV5SvaR6SfWS6pUWSPWS6iXVIdUh
    1SHVIdUh1SHVIdWRrUh1SPWR6iPVR6qPVB+pPlJ9pPpI9Umitqg0esmjl0R6yaSXVHrJpZdkesmm
    l3R6ie+X5sVn0dv0Vr1db9nb9ta9fB8JP3WHxCfnR9KPrB9pP/J+JP7I/JH6I/dnOZTik/4j/0cB
    iAoQJSBqQBSBqAJRBrJdcvGpBFEKohZEMYhqEOUg6kEUhKgIub3UEJ+iEFUhykLUhSgMURmiNERt
    iOKQx2sh8akPUSCiQkSJiBoRRSKqRJSJqBN5vVgTn1IRtSKKRVSLKBdRL6JgRMWIkpHj1aT4VI0o
    G1E3onBE5YjSEbUjikdUj3xe7nq9qwWv+lH1o+pH1Y+qH1U/qn5U/aj60XhBLj71o+pH1Y+qH1U/
    qn5U/aj3C94w/NoxiM97Bm8avGvwtsH7Bm8c1I+qH1U/urylEZ/6UfWj6kfVj6ofVT+qflT9qPrR
    7T2X+NSPqh9VP6p+VP2o+lH1o+pH1Y/e3hROvg878g878g878g878g878u8P/84Hn158Ovj0cbpg
    SBPihDwhUEgUIoVMIVRIVVJVPyNSlVQlVUlVUpVUJVVJtUi1SLX0T0eqRapFqkWqRapFqkWqTapN
    qk2qrW8UqTapNqk2qTapNqluUt2kukl1k+rWF51UN6luUt2kukn1kOoh1UOqh1QPqR79/pHqIdVD
    qodUL6leUr2kekn1kuol1SstkOol1UuqQ6pDqkOqQ6pDqkOqQ6ojW5HqkOoj1Ueqj1QfqT5SfaT6
    SPWR6pNEbVFp9JJHL4n0kkkvqfSSSy/J9JJNL+n0Et8vzYvPorfprXq73rK37a17+T4SfuoOiU/O
    j6QfWT/SfuT9SPyR+SP1R+7PcijFJ/1H/o8CEBUgSkDUgCgCUQWiDGS75OJTCaIURC2IYhDVIMpB
    1IMoCFERcnupIT5FIapClIWoC1EYojJEaYjaEMUhj9dC4lMfokBEhYgSETUiikRUiSgTUSfyerEm
    PqUiakUUi6gWUS6iXkTBiIoRJSPHq0nxqRpRNqJuROGIyhGlI2pHFI+oHvm83PV6Vwte9aPqR9WP
    qh9VP6p+VP2o+lH1o/GCXHzqR9WPqh9VP6p+VP2o+lHvF7xh+LVjEJ/3DN40eNfgbYP3Dd44qB9V
    P6p+dHlLIz71o+pH1Y+qH1U/qn5U/aj6UfWj23su8akfVT+qflT9qPpR9aPqR9WPqh+9vSn8L9+/
    X2/6/w35fz5kfuj8sOaHPT/gb3vmh3d+OPPDh6FEAEMAEVAEGAFHABKQBCgBS8FS/jzAUrAULAVL
    wVKwFCwFywLLAsviPw5YFlgWWBZYFlgWWBZYNlg2WDZYNr8pYNlg2WDZYNlg2WC5wXKD5QbLDZab
    X1uw3GC5wXKD5QbLA5YHLA9YHrA8YHn4OwSWBywPWB6wvGB5wfKC5QXLC5YXLC9/ocHyguUFywHL
    AcsBywHLAcsBywHLoV3AcsDygeUDyweWDywfWD6wfGD5wPJRdXIdZXfRdhd1d9F3F4V30XgXlXfR
    eReld5HKCiaVJCwLS8PysEQsE0vFdHEo41RlIBV9HAo5NHKo5NDJoZRDK4daDr2cpWCRimoO3RzK
    ObRzqOfQz6GgQ0OHis5WR0lFS4eaDj0dijo0dajq0NWhrENb51beSUVhh8YOlR06O5R2aO1Q26G3
    Q3Hn0aqDVHR3KO/Q3qG+Q3+HAg8NHio8dHheLYZIRY2HHg9FHpo8VHno8lDmoc1DnedojUYqGj1U
    euj0UOqh1UOth14PxR6aPZ+Wjlo7cvFIt5duL91eur10e+n20u2l20u3N1rSkopuL91eur10e+n2
    0u2l26t1thbaXmmTSmttLba12tZyW+ttLbjp9tLtpdu7tAEgFd1eur10e+n20u2l20u3l24v3d6t
    fQmp6PbS7aXbS7eXbi/dXrq9dHvp9t7aLg2qNXeka+5I19yRrrkjXXNHuv7gb3vmh3d+OPPDh6FE
    AEMAEVAEGAFHABKQBCgBS8FS/jzAUrAULAVLwVKwFCwFywLLAsviPw5YFlgWWBZYFlgWWBZYNlg2
    WDZYNr8pYNlg2WDZYNlg2WC5wXKD5QbLDZabX1uw3GC5wXKD5QbLA5YHLA9YHrA8YHn4OwSWBywP
    WB6wvGB5wfKC5QXLC5YXLC9/ocHyguUFywHLAcsBywHLAcsBywHLoV3AcsDygeUDyweWDywfWD6w
    fGD5wPJRdXIdZXfRdhd1d9F3F4V30XgXlXfReReld5HKCiaVJCwLS8PysEQsE0vFdHEo41RlIBV9
    HAo5NHKo5NDJoZRDK4daDr2cpWCRimoO3RzKObRzqOfQz6GgQ0OHis5WR0lFS4eaDj0dijo0dajq
    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
    j6ofVT+qflT9qPpR9aPqR9WPbu+5xKd+VP2o+lH1o+pH1Y+qH1U/qn709qZw8t3Ykd/Ykd/Ykd/Y
    kd/Ykd9/+Hc++PTi08Gnj9MFQ5oQJ+QJgUKiEClkCqFCqpKq+hmRqqQqqUqqkqqkKqlKqkWqRaql
    fzpSLVItUi1SLVItUi1SbVJtUm1SbX2jSLVJtUm1SbVJtUl1k+om1U2qm1S3vuikukl1k+om1U2q
    h1QPqR5SPaR6SPXo949UD6keUj2kekn1kuol1Uuql1QvqV5pgVQvqV5SHVIdUh1SHVIdUh1SHVId
    2YpUh1QfqT5SfaT6SPWR6iPVR6qPVJ8kaotKo5c8ekmkl0x6SaWXXHpJppdsekmnl/h+aV58Fr1N
    b9Xb9Za9bW/dy/eR8FN3SHxyfiT9yPqR9iPvR+KPzB+pP3J/lkMpPuk/8n8UgKgAUQKiBkQRiCoQ
    ZSDbJRefShClIGpBFIOoBlEOoh5EQYiKkNtLDfEpClEVoixEXYjCEJUhSkPUhigOebwWEp/6EAUi
    KkSUiKgRUSSiSkSZiDqR14s18SkVUSuiWES1iHIR9SIKRlSMKBk5Xk2KT9WIshF1IwpHVI4oHVE7
    onhE9cjn5a7Xu1rwqh9VP6p+VP2o+lH1o+pH1Y+qH40X5OJTP6p+VP2o+lH1o+pH1Y96v+ANw68d
    g/i8Z/CmwbsGbxu8b/DGQf2o+lH1o8tbGvGpH1U/qn5U/aj6UfWj6kfVj6of3d5ziU/9qPpR9aPq
    R9WPqh9VP6p+VP3o7U3h5HuwI3+wI3+wI3+wI3+wI3/+8O988OnFp4NPH6cLhjQhTsgTAoVEIVLI
    FEKFVCVV9TMiVUlVUpVUJVVJVVKVVItUi1RL/3SkWqRapFqkWqRapFqk2qTapNqk2vpGkWqTapNq
    k2qTapPqJtVNqptUN6lufdFJdZPqJtVNqptUD6keUj2kekj1kOrR7x+pHlI9pHpI9ZLqJdVLqpdU
    L6leUr3SAqleUr2kOqQ6pDqkOqQ6pDqkOqQ6shWpDqk+Un2k+kj1keoj1Ueqj1QfqT5J1BaVRi95
    9JJIL5n0kkovufSSTC/Z9JJOL/H90rz4LHqb3qq36y172966l+8j4afukPjk/Ej6kfUj7Ufej8Qf
    mT9Sf+T+LIdSfNJ/5P8oAFEBogREDYgiEFUgykC2Sy4+lSBKQdSCKAZRDaIcRD2IghAVIbeXGuJT
    FKIqRFmIuhCFISpDlIaoDVEc8ngtJD71IQpEVIgoEVEjokhElYgyEXUirxdr4lMqolZEsYhqEeUi
    6kUUjKgYUTJyvJoUn6oRZSPqRhSOqBxROqJ2RPGI6pHPy12vd7XgVT+qflT9qPpR9aPqR9WPqh9V
    PxovyMWnflT9qPpR9aPqR9WPqh/1fsEbhl87BvF5z+BNg3cN3jZ43+CNg/pR9aPqR5e3NOJTP6p+
    VP2o+lH1o+pH1Y+qH1U/ur3nEp/6UfWj6kfVj6ofVT+qflT9qPrR25vCyfdiR/5iR/5iR/5iR/5i
    R/7+4d/54NOLTwefPk4XDGlCnJAnBAqJQqSQKYQKqUqq6mdEqpKqpCqpSqqSqqQqqRapFqmW/ulI
    tUi1SLVItUi1SLVItUm1SbVJtfWNItUm1SbVJtUm1SbVTaqbVDepblLd+qKT6ibVTaqbVDepHlI9
    pHpI9ZDqIdWj3z9SPaR6SPWQ6iXVS6qXVC+pXlK9pHqlBVK9pHpJdUh1SHVIdUh1SHVIdUh1ZCtS
    HVJ9pPpI9ZHqI9VHqo9UH6k+Un2SqC0qjV7y6CWRXjLpJZVecuklmV6y6SWdXuL7pXnxWfQ2vVVv
    11v2tr11L99Hwk/dIfHJ+ZH0I+tH2o+8H4k/Mn+k/sj9WQ6l+KT/yP9RAKICRAmIGhBFIKpAlIFs
    l1x8KkGUgqgFUQyiGkQ5iHoQBSEqQm4vNcSnKERViLIQdSEKQ1SGKA1RG6I45PFaSHzqQxSIqBBR
    IqJGRJGIKhFlIupEXi/WxKdURK2IYhHVIspF1IsoGFExomTkeDUpPlUjykbUjSgcUTmidETtiOIR
    1SOfl7te72rBq35U/aj6UfWj6kfVj6ofVT+qfjRekItP/aj6UfWj6kfVj6ofVT/q/YI3DL92DOLz
    nsGbBu8avG3wvsEbB/Wj6kfVjy5vacSnflT9qPpR9aPqR9WPqh9VP6p+dHvPJT71o+pH1Y+qH1U/
    qn5U/aj6UfWjtzeFk+9gR36wIz/YkR/syA925OcP/84Hn158Ovj0cbpgSBPihDwhUEgUIoVMIVRI
    VVJVPyNSlVQlVUlVUpVUJVVJtUi1SLX0T0eqRapFqkWqRapFqkWqTapNqk2qrW8UqTapNqk2qTap
    NqluUt2kukl1k+rWF51UN6luUt2kukn1kOoh1UOqh1QPqR79/pHqIdVDqodUL6leUr2kekn1kuol
    1SstkOol1UuqQ6pDqkOqQ6pDqkOqQ6ojW5HqkOoj1Ueqj1QfqT5SfaT6SPWR6pNEbVFp9JJHL4n0
    kkkvqfSSSy/J9JJNL+n0Et8vzYvPorfprXq73rK37a17+T4SfuoOiU/Oj6QfWT/SfuT9SPyR+SP1
    R+7PcijFJ/1H/o8CEBUgSkDUgCgCUQWiDGS75OJTCaIURC2IYhDVIMpB1IMoCFERcnupIT5FIapC
    lIWoC1EYojJEaYjaEMUhj9dC4lMfokBEhYgSETUiikRUiSgTUSfyerEmPqUiakUUi6gWUS6iXkTB
    iIoRJSPHq0nxqRpRNqJuROGIyhGlI2pHFI+oHvm83PV6Vwte9aPqR9WPqh9VP6p+VP2o+lH1o/GC
    XHzqR9WPqh9VP6p+VP2o+lHvF7xh+LVjEJ/3DN40eNfgbYP3Dd44qB9VP6p+dHlLIz71o+pH1Y+q
    H1U/qn5U/aj6UfWj23su8akfVT+qflT9qPpR9aPqR9WPqh+9vSkcfMF75MF75MF75MF75MF75MF7
    5MF75MF75MF75MF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF7
    5OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF7
    5OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF7
    5OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF7
    5OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75OF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF75NF7
    5NF75NF75NF75Av3yBfukS/cI1+4R75wj3zhHvnCPfKFe+QL98gX7pEv3iNfvEe+eI988R754j3y
    xXvki/fIF++RL94jX7xHvniPfPEe+eI98sV75Iv3yBfvkS/eI1+8R754j3zxHvniPfLFe+SL98gX
    75Ev3iNfvEe+eI988R754j3yxXvki/fIF++RL94jX7xHvniPfPEe+eI98sV75Iv3yBfvkS/eI1+8
    R754j3zxHvniPfLFe+SL98gX75Ev3iNfvEe+eI988R754j3yxXvki/fIF++RL94jX7xHvniPfPEe
    +eI98sV75Iv3yBfvkS/eI1+8R754j3zxHvniPfLFe+SL98gX75Ev3iNfvEe+eI988R754j3yxXvk
    i/fIF++RL94jX7xHvniPfPEe+eI98sV75Iv3yBfvkS/eI1+8R750j3zpHvnSPfKle+RL98iX7pEv
    3SNfuke+dI986R750j3ypXvkS/fIl+6RL90jX7pHvnSPfOke+dI98qV75Ev3yJfukS/dI1+6R750
    j3zpHvnSPfKle+RL98iX7pEv3SNfuke+dI986R750j3ypXvkS/fIl+6RL90jX7pHvnSPfOke+dI9
    8qV75Ev3yJfukS/dI1+6R750j3zpHvnSPfKle+RL98iX7pEv3SNfuke+dI986R750j3ypXvkS/fI
    l+6RL90jX7pHvnSPfOke+dI98qV75Ev3yJfukS/dI1+6R750j3zpHvnSPfKle+RL98iX7pEv3SNf
    uke+dI986R750j3ypXvkS/fIl+6RL90jX7pHvnSPfOke+dI98qV75Ev3yJfukS/dI1+6R750j3zp
    HvnSPfKle+RL98iX7pEv3SNfuke+dI986R750j3ypXvkS/fIl+6RL90jX7pHvnSPfOke+dI98qV7
    5Ev3yJfukS/dI1+6R750j3zpHvnSPfKle+RL98iX7pEv3SNfuke+dI986R750j3ypXvkS/fIl+6R
    L90jX7pHvnSPfOke+dI98qV75Ev3yJfukS/dI1+6R750j3zpHvnSPfKle+RL98iX7pEv3SNfuke+
    dI986R750j3ypXvkG2fkG2fkG2fkG2fkG2fkG2fkG2fkG2fkG2fkG2fkm2fkm2fkm2fkm2fkm2fk
    m2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fk
    m2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fk
    m2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fk
    m2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fk
    m2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkm2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fk
    W2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fkW2fku9iRFzvyYkde7MiLHXn/8O98
    8OnFp4NPH6cLhjQhTsgTAoVEIVLIFEKFVCVV9TMiVUlVUpVUJVVJVVKVVItUi1RL/3SkWqRapFqk
    WqRapFqk2qTapNqk2vpGkWqTapNqk2qTapPqJtVNqptUN6lufdFJdZPqJtVNqptUD6keUj2kekj1
    kOrR7x+pHlI9pHpI9ZLqJdVLqpdUL6leUr3SAqleUr2kOqQ6pDqkOqQ6pDqkOqQ6shWpDqk+Un2k
    +kj1keoj1Ueqj1QfqT5J1BaVRi959JJIL5n0kkovufSSTC/Z9JJOL/H90rz4LHqb3qq36y172966
    l+8j4afukPjk/Ej6kfUj7Ufej8QfmT9Sf+T+LIdSfNJ/5P8oAFEBogREDYgiEFUgykC2Sy4+lSBK
    QdSCKAZRDaIcRD2IghAVIbeXGuJTFKIqRFmIuhCFISpDlIaoDVEc8ngtJD71IQpEVIgoEVEjokhE
    lYgyEXUirxdr4lMqolZEsYhqEeUi6kUUjKgYUTJyvJoUn6oRZSPqRhSOqBxROqJ2RPGI6pHPy12v
    d7XgVT+qflT9qPpR9aPqR9WPqh9VPxovyMWnflT9qPpR9aPqR9WPqh/1fsEbhl87BvF5z+BNg3cN
    3jZ43+CNg/pR9aPqR5e3NOJTP6p+VP2o+lH1o+pH1Y+qH1U/ur3nEp/6UfWj6kfVj6ofVT+qflT9
    qPrR25vCv3zfP6vYvxuGf/bj//tzxp87/rzGn/f48/x7nvHnd/z5jD9/cxYGz8mZozNnZw7PnJ45
    PnN+JkAmQSdB8d8+CToJOgk6CToJOgk6CToJ1iRYk2Dhxz8J1iRYk2BNgjUJ1iRYk2BPgj0J9iTY
    +AZMgj0J9iTYk2BPgj0J7klwT4J7EtyT4MaXcBLck+CeBPckuCfBMwmeSfBMgmcSPJPgwe/BJHgm
    wTMJnknwToJ3EryT4J0E7yR4J8GLX8VJ8E6CdxKcSXAmwZkEZxKcSXAmwZkEBzaYBGcSfJPgmwTf
    JPgmwTcJvknwTYJvEnwQEo0EJV1w0gUpXbDSBS1d8NIFMV0w0wU1XWCRHsFCQdKQVCQdSUnSktQk
    PBmIMqWrwQJXBrIMbBnoMvBlIMzAmIEyA2dmMRxggTYDbwbiDMwZqDNwZyDPwJ6BPrNZMbDAoIFC
    A4cGEg0sGmg08Ggg0sCkuZlUsECmgU0DnQY+DYQaGDVQauDUQKp52HewwKuBWAOzBmoN3BrINbBr
    oNfAr3m52AALFBs4NpBsYNlAs4FnA9EGpg1Um8OVD1hg20C3gW8D4QbGDZQbODeQbmDdfFyGcR2G
    hRi8W3i38G7h3cK7hXcL7xbeLbzbcFEIFni38G7h3cK7hXcL7xbeLdenXKBqhQoWrlG5SOUqlctU
    rlO5UIV3C+8W3u3ichks8G7h3cK7hXcL7xbeLbxbeLfwbjfX7mCBdwvvFt4tvFt4t/Bu4d3Cu4V3
    e3Mjcf/r/wBJy7jT1IQBAA=='
    base64 -d <<< "${mys_base64//    /}" | gzip -d > "${mys1a_cloud_hosting_ip_list}"
  fi
  if [[ ! -f "${sgp1a_cloud_hosting_ip_list}" ]] || ! sha256sum -c <<< "bf15b32292f740cc538d85320b8c397866f326aa78718bb71aa60ce3daa69047  ${HOME}/.digg_sgp1a_cloud_hosting_ip_list" &>/dev/null; then
    sgp_base64='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'
    base64 -d <<< "${sgp_base64//    /}" | gzip -d > "${sgp1a_cloud_hosting_ip_list}"
  fi
  if [[ ! -f "${hkg1a_cloud_hosting_ip_list}" ]] || ! sha256sum -c <<< "eb44fa06c7473beba6e981b8561a04e439fdc4b0d016721e7482c44a496eb640  ${HOME}/.digg_hkg1a_cloud_hosting_ip_list" &>/dev/null; then
    hkg_base64='H4sIAAAAAAACA2XZvY5tVxVE4fw+BRKBs6tdtf4DngURASJBQuL5sUlco5zt7aDX6PY535xL989/
    +q9+fj9+/ONff9ff/vrPf//nL7/oGz/f+HnGr//992fFs+N5xPOM5xXPO55PPN94fnkWDs6TlUcr
    z1YerjxdebzyfGWAssBZYPzuWeAscBY4C5wFzgJngbNgZMHIgoE/fxaMLBhZMLJgZMHIgpEFMwtm
    FswsmPgEZMHMgpkFMwtmFswsWFmwsmBlwcqChQ9hFqwsWFmwsmBlwc6CnQU7C3YW7CzY+B5kwc6C
    nQU7C04WnCw4WXCy4GTByYKDr2IWnCw4WXCz4GbBzYKbBTcLbhbcLLjQIAtuFrwseFnwsuBlwcuC
    lwUvC14WPIBEkUDSB5M+oPRBpQ8sfXDpA0wfZPpA04eW4hEtBJJCkkgaSSSpJJmEkwKUMq1GC6wU
    sBS0FLgUvBTAFMQUyBTM1ODgQAvYFNwU4BTkFOgU7BTwFPQU+NTkFEMLBBUIFQwVEBUUFRgVHBUg
    FSTV4khFCzAVNBU4FTwVQBVEFUgVTBVQ1eZ8RwtcFWAVZBVoFWwVcBV0FXgVfNXhsoEWECsYKyAr
    KCswKzgrQCtIK1Cry80HLdBW4FbwVgBXEFcgVzBXQFdQV49rGPcwLGJw13DXcNdw13DXcNdw13DX
    cNfiUogWuGu4a7hruGu4a7hruGvup1xQa0NFC3dULqncUrmmck/logp3DXcNdz24LqMF7hruGu4a
    7hruGu4a7hruGu56cndHC9w13DXcNdw13DXcNdw13DXc9eJF4veWGTeyGTeyGTeyGTeyGTey+TN/
    zo7nE883nl+ehYPzZOXRyrOVhytPVx6vPF8ZoCxwFhi/exY4C5wFzgJngbPAWeAsGFkwsmDgz58F
    IwtGFowsGFkwsmBkwcyCmQUzCyY+AVkws2BmwcyCmQUzC1YWrCxYWbCyYOFDmAUrC1YWrCxYWbCz
    YGfBzoKdBTsLNr4HWbCzYGfBzoKTBScLThacLDhZcLLg4KuYBScLThbcLLhZcLPgZsHNgpsFNwsu
    NMiCmwUvC14WvCx4WfCy4GXBy4KXBQ8gUSSQ9MGkDyh9UOkDSx9c+gDTB5k+0PShpXhEC4GkkCSS
    RhJJKkkm4aQApUyr0QIrBSwFLQUuBS8FMAUxBTIFMzU4ONACNgU3BTgFOQU6BTsFPAU9BT41OcXQ
    AkEFQgVDBUQFRQVGBUcFSAVJtThS0QJMBU0FTgVPBVAFUQVSBVMFVLU539ECVwVYBVkFWgVbBVwF
    XQVeBV91uGygBcQKxgrICsoKzArOCtAK0grU6nLzQQu0FbgVvBXAFcQVyBXMFdAV1NXjGsY9DIsY
    3DXcNdw13DXcNdw13DXcNdy1uBSiBe4a7hruGu4a7hruGu6a+ykX1NpQ0cIdlUsqt1SuqdxTuajC
    XcNdw10PrstogbuGu4a7hruGu4a7hruGu4a7ntzd0QJ3DXcNdw13DXcNdw13DXcNd714kfi9ZcWN
    bMWNbMWNbMWNbMWNbP3Mn7Pj+cTzjeeXZ+HgPFl5tPJs5eHK05XHK89XBigLnAXG754FzgJngbPA
    WeAscBY4C0YWjCwY+PNnwciCkQUjC0YWjCwYWTCzYGbBzIKJT0AWzCyYWTCzYGbBzIKVBSsLVhas
    LFj4EGbByoKVBSsLVhbsLNhZsLNgZ8HOgo3vQRbsLNhZsLPgZMHJgpMFJwtOFpwsOPgqZsHJgpMF
    NwtuFtwsuFlws+Bmwc2CCw2y4GbBy4KXBS8LXha8LHhZ8LLgZcEDSBQJJH0w6QNKH1T6wNIHlz7A
    9EGmDzR9aCke0UIgKSSJpJFEkkqSSTgpQCnTarTASgFLQUuBS8FLAUxBTIFMwUwNDg60gE3BTQFO
    QU6BTsFOAU9BT4FPTU4xtEBQgVDBUAFRQVGBUcFRAVJBUi2OVLQAU0FTgVPBUwFUQVSBVMFUAVVt
    zne0wFUBVkFWgVbBVgFXQVeBV8FXHS4baAGxgrECsoKyArOCswK0grQCtbrcfNACbQVuBW8FcAVx
    BXIFcwV0BXX1uIZxD8MiBncNdw13DXcNdw13DXcNdw13LS6FaIG7hruGu4a7hruGu4a75n7KBbU2
    VLRwR+WSyi2Vayr3VC6qcNdw13DXg+syWuCu4a7hruGu4a7hruGu4a7hrid3d7TAXcNdw13DXcNd
    w13DXcNdw10vXiR+bfH//x3tt+n+250s3oQ3423gbeKNP3Pj7eDt4u3x9IphjZgj9ohBYpGYJDaJ
    UWKVWeX6G7HKrDKrzCqzyqwyq8yqwarBqlH/61g1WDVYNVg1WDVYNVg1WTVZNVk16xPFqsmqyarJ
    qsmqyarFqsWqxarFqlUfdFYtVi1WLVYtVm1WbVZtVm1WbVbt+v6xarNqs2qz6rDqsOqw6rDqsOqw
    6hQLrDqsOqy6rLqsuqy6rLqsuqy6rLqlFasuqx6rHqseqx6rHqseqx6rHqteIdqKFqNfOfoVpF9J
    +hWlX1n6FaZfafoVp1/1/YH56mvoW/qmvq1v7Fv75r68V4Ev9xyqvjJfhb5KfRX7KvdV8KvkV9Gv
    sl+jB2X1Ff8q/1UDQDUBVCNANQNUQ0A1BVRjQLMnefXVJFCNAtUsUA0D1TRQjQPVPFANBNVE0OpV
    o/pqKKimgmosqOaCajCoJoNqNKhmg2o4aPcuVH01H1QDQjUhVCNCNSNUQ0I1JVRjQjUndHpZq74a
    FapZoRoWqmmhGheqeaEaGKqJoRoZur1NVl9NDdXYUM0N1eBQTQ7V6FDNDtXwUE0PvV53e9+thbfm
    h2t+uOaHa3645odrfrjmh2t+uOaH1Qt59dX8cM0P1/xwzQ/X/HDND9f8cN8X+sLwhxtD9fWdoS8N
    fWvoa0PfG/riUPPDNT9c88OjrzTVV/PDNT9c88M1P1zzwzU/XPPDNT9c88Oz71zVV/PDNT9c88M1
    P1zzwzU/XPPDNT9c88OrL4Xrlx//A+lkOc5cOAAA'
    base64 -d <<< "${hkg_base64//    /}" | gzip -d > "${hkg1a_cloud_hosting_ip_list}"
  fi
  if [[ ! -f "${staging_cloud_hosting_ip_list}" ]] || ! sha256sum -c <<< "1e7abbbc42dc6379f94b778bc53955c24ea1df024184ac801e560a9d16579195  ${HOME}/.digg_staging_cloud_hosting_ip_list" &>/dev/null; then
    stg_base64='H4sIAAAAAAACA1XOoQqAMABF0b6vEAy2sfc23Qx+i5jEIoLi91u98bTTd69iCuF+tv049/W47mUo
    OdotutSo2QHMZCFHciIr2cj5T6dEijSZyUKO5ERWspFciStxJa7ElbgSV+JKXIkrcWWuzJW5ch7C
    B3ClyR72AQAA'
    base64 -d <<< "${stg_base64//    /}" | gzip -d > "${staging_cloud_hosting_ip_list}"
  fi
  unset mys_base64 sgp_base64 hkg_base64 stg_base64
}

check_if_cloud_hosting() {
  local ip
  for ip in ${1} ; do
    ip=$(check_valid_ipv4 <<< "${ip}")
    if [[ -n ${ip} ]]; then
      if grep -q "^${ip}$" "${mys1a_cloud_hosting_ip_list}" ; then
        echo "${ip} - MYS1a Cloud Hosting"
      elif grep -q "^${ip}$" "${sgp1a_cloud_hosting_ip_list}" ; then
        echo "${ip} - SGP1a Cloud Hosting"
      elif grep -q "^${ip}$" "${hkg1a_cloud_hosting_ip_list}" ; then
        echo "${ip} - HKG1a Cloud Hosting"
      elif grep -q "^${ip}$" "${staging_cloud_hosting_ip_list}" ; then
        echo "${ip} - Staging Cloud Hosting"
      else
        echo "${ip}"
      fi
    fi
  done
}

help_text() {
  (
    echo_color blue "Dig tool that checks NS , A , MX , TXT , PTR with IP Details"
    echo_color blue "By MatrixEvo"
    echo_color blue "Last Updated - 2nd September 2024"
    echo
    echo_color yellow "Script Related Functions :"
    echo "  chist - Clear Input History"
    echo "  clear or reset - Clear screen"
    echo "  color <on|off> - Turns this script color on or off"
    echo "  debug <on|off> - Turns on or off debug mode for this script"
    echo "  dns <DNS Server> - Change the Currently used DNS Server"
    echo "  datas <ipinfo|ipapi> - Change the IP Data Source ipinfo.io or ipapi.is ( Default - ipinfo.io )"
    echo "  history <search> - View or Search Input History"
    echo "  repeat <count> <function> - repeats function ( Default 3 times )"
    echo
    echo_color yellow "Tools Available :"
    echo "  ip - Your Current Public IP"
    echo "  pass <segment length> <segment count> <number of password> - Password Generator ( Default 6  3  5 )"
    echo "  pmp - Today's PMP Code"
    echo "  ptr <IP> - Check which NameServer is responsible for the PTR record zone"
    echo "  whois <Domain> - WHOIS info for the domain"
    echo "  grp - Get Cloud Hosting Restore Points"
    echo "  mcmc <domain> <mode> - Check MCMC Block"
    echo
    echo_color yellow "Connectivity Checks :"
    echo "  ping <Domain or IP> - ping 4 times , timeout 1 second"
    echo "  web <Domain or IP> - Check HTTP Response Code"
    echo "  nc or telnet <Domain or IP> - Check if generally used port is open"
    echo "  nc or telnet <Domain or IP> mail - Check if mail ports is open"
    echo "  nc or telnet <Domain or IP> <Port Number> - Check if specific port is open"
    echo "  tr or traceroute <Domain or IP> - Traceroute to the destination"
    echo
    echo_color yellow "SSL Related :"
    echo "  ssl <Domain or IP> <Port> - Check SSL Details ( Default Port 443 )"
    echo "  gencsr - Generate SSL CSR"
    echo "  pkcs - Convert PKCS7 To PEM / PFX ( To get Cert, Intermediate and Root Cert )"
    echo "  deccsr - Decode CSR Data"
    echo "  decssl - Decode SSL Cert"
    echo
    echo_color yellow "Email Related :"
    echo "  mail <Domain> - check DNS records essential for successful mail delivery"
    echo "  dkim - DKIM DNS Record TXT String Splitter"
    echo "  emt - Test Email Template"
  )
}

debug_toggle() {
  if [[ ${1} == "on" ]] || [[ -z ${1} ]]; then
    echo "Turning Debug On"
    set -x
  else
    echo "Turning Debug Off"
    set +x
  fi
}

color_toggle() {
  if [[ ${1} == "on" ]] || [[ -z ${1} ]]; then
    end="\033[0m"
    darkyellow="\033[0;33m"
    blue="\033[1;34m"
    red="\033[0;31m"
    lightred="\033[1;31m"
    yellow="\033[1;33m"
    green="\033[1;32m"
  else
    end=""
    darkyellow=""
    blue=""
    red=""
    lightred=""
    yellow=""
    green=""
  fi
}

search_history() {
  if [[ -z ${1} ]]; then
    history
  else
    history | grep "${1}"
  fi
}

clear_history() {
  history -c "${history_file}"
  history -w "${history_file}"
  history -r "${history_file}"
  echo "History Cleared !"
}

change_dns() {
  if [[ -z ${1} ]]; then
    echo "dns <IP or Domain Name of DNS Server> - Change the Currently used DNS Server"
    echo "dns u1 - IPS1 Hosted DNS - UnboundDNS1.small-dns.com - 183.81.162.41"
    echo "dns u2 - IPS1 Hosted DNS - UnboundDNS2.small-dns.com - 14.102.148.71"
    echo "dns g - Google - 8.8.8.8"
    echo "dns c - Cloudflare - 1.1.1.1"
    echo "dns o - OpenDNS - 208.67.222.222"
  else
    if [[ "${1}" == "u1" ]]; then
      dns_server="183.81.162.41"
    elif [[ "${1}" == "u2" ]]; then
      dns_server="14.102.148.71"
    elif [[ "${1}" == "g" ]]; then
      dns_server="8.8.8.8"
    elif [[ "${1}" == "c" ]]; then
      dns_server="1.1.1.1"
    elif [[ "${1}" == "o" ]]; then
      dns_server="208.67.222.222"
    elif [[ -n $(check_valid_ipv4 <<<"${1}") ]]; then
      dns_server="$(check_valid_ipv4 <<<"${1}")"
    elif [[ -n $(echo "${1}" | tr '[:upper:]' '[:lower:]' | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1) ]]; then
      dns_server="$(echo "${1}" | tr '[:upper:]' '[:lower:]' | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1)"
      while [[ ${dns_server:(-1)} == "." ]] || [[ ${dns_server::1} == "." ]]; do # Trim front and back extra dots (.)
        if [[ ${dns_server:(-1)} == "." ]]; then # Trim Back
          dns_server="${dns_server%?}"
        fi
        if [[ ${dns_server::1} == "." ]]; then # Trim Front
          dns_server="${dns_server:1}"
        fi
      done
      dns_server="$(dig -4 +short +timeout=1 +tries=2 @8.8.8.8 A "${dns_server}")"
    fi
    if [[ $(dig -4 +timeout=1 +tries=2 @"${dns_server}" A "dns.google" 2>&1) =~ NOERROR|REFUSED ]]; then
      if [[ $(dig_short A "dns.google") =~ 8.8.8.8|8.8.4.4 ]]; then
        echo "Warning - The DNS Server \"${dns_server}\" is an Open Resolver !"
      else
        echo "Ok - The DNS Server \"${dns_server}\" is NOT an Open Resolver !"
      fi
    else
      dns_server="8.8.8.8"
      echo "${1} is NOT responding to DNS queries , reverting to use 8.8.8.8"
    fi
  fi
}

change_ip_datasource() {
  if [[ ${1} == "ipapi" ]]; then
    ip_datasource="ipapi.is"
  elif [[ ${1} == "ipinfo" ]]; then
    ip_datasource="ipinfo.io"
  else
    echo "datas <ipinfo|ipapi> - Change the IP Data Source ipinfo.io or ipapi.is ( Default - ipapi.is )"
    echo
  fi
  echo "Currently Using : ${ip_datasource}"
}

password_generator() {
  local segment_length segment_count password num_passwords n i
  segment_length=${1:-6}   # Default segment length is 6
  segment_count=${2:-3}    # Default count is 3 segments
  num_passwords=${3:-5}  # Default number of passwords to generate is 5

  if [[ ${segment_length} -lt 3 ]]; then
    segment_length=3
  fi

  if [[ ${segment_count} -lt 2 ]]; then
    segment_count=2
  fi

  if [[ ${num_passwords} -lt 1 ]]; then
    num_passwords=1
  fi

  echo "Segment  Length : ${segment_length}"
  echo "Segment  Count  : ${segment_count}"
  echo "Password Count  : ${num_passwords}"
  echo "Password Length : $((segment_length * segment_count + segment_count - 1))"

  generate_segment() {
    local segment
    while true; do
      # Start with one lowercase letter, one uppercase letter, and one digit
      segment=$(tr -dc '[:lower:]' < /dev/urandom | tr -d 'iI1lLoO0' | head -c 1)
      segment+=$(tr -dc '[:upper:]' < /dev/urandom | tr -d 'iI1lLoO0' | head -c 1)
      segment+=$(tr -dc '[:digit:]' < /dev/urandom | tr -d 'iI1lLoO0' | head -c 1)

      # Add remaining random characters, ensuring uniqueness
      while [[ ${#segment} -lt ${segment_length} ]]; do
        char=$(tr -dc '[:alnum:]' < /dev/urandom | tr -d 'iI1lLoO0' | head -c 1)
        if [[ ! ${segment} == *"${char}"* ]]; then
          segment+="${char}"
        fi
      done

      # Shuffle the segment to mix the characters
      segment=$(fold -w1 <<< "${segment}" | shuf | tr -d '\n')

      # Ensure the segment is of the desired length and break the loop
      if [[ ${#segment} -eq ${segment_length} ]]; then
        break
      fi
    done
    echo "${segment}"
  }

  echo
  for ((n = 1; n <= num_passwords; n++)); do
    password=""
    for ((i = 1; i <= segment_count; i++)); do
      if [[ ${i} -eq 1 ]]; then
        password=$(generate_segment)
      else
        password+="-$(generate_segment)"
      fi
    done
    echo "${password}"
  done
}

check_whois() {
  local hostname temp
  if [[ ! "$(command -v whois)" ]]; then
    echo_color red "whois not found... attempting to install..."
    echo
    sudo apt update && apt install -y whois
  fi

  hostname=$(tr '[:upper:]' '[:lower:]' <<< "${1}" | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1 )
  hostname="$(check_root_hostname "${hostname}")"

  if [[ -z ${hostname} ]]; then
    echo "whois <Domain> - WHOIS info for the domain"
  elif [[ "$(command -v whois)" ]]; then
    temp=$(whois "${hostname}" | grep -v "   ")
    if [[ ! ${temp} =~ "No match for domain" ]]; then
      grep "Domain Name:" <<< "${temp}"
      echo
      grep "DNSSEC:" <<< "${temp}"
      echo
      grep "Registrar:" <<< "${temp}"
      echo
      grep "Date:" <<< "${temp}" | sort -h
      echo
      grep "Name Server:" <<< "${temp}" | sort -h
    else
      echo_color red "NO DATA - Possibly Domain Not Found or Does Not Exist"
      echo "Please confirm using other methods"
    fi
  fi
  unset hostname temp
}

check_port() {
  local hostname ports port tmp_file tmp_dir

  check_and_echo() {
    local port description output
    port="${1}"
    description="${2}"
    output="${3}"
    timeout 1 nc -4 -z -v -w 1 "${hostname}" "${port}" &>/dev/null && printf "Port %-5s - %-16s - %s\n" "${port}" "${description}" "${output}" >> "${tmp_file}" &
  }

  hostname=$(tr '[:upper:]' '[:lower:]' <<< "${1}" | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1 )

  if [[ -z ${hostname} ]] && [[ "${3}" == "wait" ]]; then
    return
  elif [[ -z ${hostname} ]]; then
    echo "nc Usage :"
    echo "  nc or telnet <Domain or IP> - Check if generally used port is open"
    echo "  nc or telnet <Domain or IP> mail - Check if mail ports is open"
    echo "  nc or telnet <Domain or IP> cp - Check cPanel / DA"
    echo "  nc or telnet <Domain or IP> <Port Number> - Check if specific port is open"
    return
  fi
  if [[ -z "${2}" ]]; then
    ports="22 80 443 2087 2222 3389 8006 9321 19389"
  else
    case ${2} in
      mail)
        ports="25 110 143 465 587 993 995 2525"
        ;;
      cp)
        ports="2087 2222"
        ;;
      *)
        ports="${@:2}"
        ;;
    esac
  fi
  if [[ ! "${3}" == "wait" ]]; then
    echo "Checking ${hostname} - Ports ${ports}"
    echo
  fi
  if [[ "${3}" == "wait" ]]; then
    tmp_file="$(mktemp)"
    if [[ $(ipinfo_org_only "${hostname}") =~ Cloudflare ]]; then
      echo "Cloudflare IP - Not Detecting Services" >> "${tmp_file}" &
    else
      check_and_echo "22" "Linux SSH" "ssh ${hostname} -p22"
      check_and_echo "80" "Web HTTP" "http://${hostname}"
      check_and_echo "443" "Web HTTPS" "https://${hostname}"
      check_and_echo "2087" "cPanel" "https://${hostname}:2087"
      check_and_echo "2222" "DirectAdmin" "https://${hostname}:2222"
      check_and_echo "3389" "Windows RDP" "${hostname}:3389"
      check_and_echo "8006" "Proxmox VE / PMG" "https://${hostname}:8006"
      check_and_echo "8080" "Web HTTP" "http://${hostname}:8080"
      check_and_echo "8443" "Web HTTPS" "https://${hostname}:8443"
      check_and_echo "9321" "Linux SSH" "ssh ${hostname} -p9321"
      check_and_echo "9998" "Smartermail" "https://${hostname}:9998"
      check_and_echo "19389" "Windows RDP" "${hostname}:19389"
    fi
    while [[ ! -f "${HOME}/.digg_wait" ]]; do
      sleep 0.01
    done
    if [[ -s ${tmp_file} ]]; then
      echo_color blue "Detected Services :"
      echo_color darkyellow "$(sort -k 2 -n < "${tmp_file}")"
      echo
    fi
    rm -f "${tmp_file}" &>/dev/null
  else
    tmp_dir="$(mktemp -d)"
    for port in ${ports}; do
        nc -4 -z -v -w 1 "${hostname}" "${port}" 2>&1 | sed 's/: Operation now in progress//' > "${tmp_dir}/${port}.out" &
    done
    wait
    for port in ${ports}; do
      cat "${tmp_dir}/${port}.out"
    done
    rm -rf "${tmp_dir}"
  fi
  unset hostname ports port tmp_file tmp_dir
}

check_traceroute() {
  if [[ ! "$(command -v traceroute)" ]]; then
    sudo apt install -y inetutils-traceroute
    echo
  fi

  hostname=$(tr '[:upper:]' '[:lower:]' <<< "${1}" | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1 )

  if [[ -z ${hostname} ]]; then
    echo "traceroute Usage :"
    echo "  tr or traceroute <Domain or IP> - Traceroute to the destination"
  else
    traceroute -q 1 -w 1 -m 15 "${hostname}"
  fi
}

check_ping() {
  if [[ -z ${1} ]]; then
    echo "ping <Domain or IP> - ping 4 times , timeout 1 second"
  else
    ping "${1}" -c 4 -W 1
  fi
}

check_web() {
  check_http_response() {
    declare -A http_status_codes=(
      [100]="Continue"
      [101]="Switching Protocols"
      [102]="Processing"
      [103]="Early Hints"
      [200]="OK"
      [201]="Created"
      [202]="Accepted"
      [203]="Non-Authoritative Information"
      [204]="No Content"
      [205]="Reset Content"
      [206]="Partial Content"
      [207]="Multi-Status"
      [208]="Already Reported"
      [226]="IM Used"
      [300]="Multiple Choices"
      [301]="Moved Permanently"
      [302]="Found"
      [303]="See Other"
      [304]="Not Modified"
      [305]="Use Proxy"
      [306]="Switch Proxy"
      [307]="Temporary Redirect"
      [308]="Permanent Redirect"
      [400]="Bad Request"
      [401]="Unauthorized"
      [402]="Payment Required"
      [403]="Forbidden"
      [404]="Not Found"
      [405]="Method Not Allowed"
      [406]="Not Acceptable"
      [407]="Proxy Authentication Required"
      [408]="Request Timeout"
      [409]="Conflict"
      [410]="Gone"
      [411]="Length Required"
      [412]="Precondition Failed"
      [413]="Payload Too Large"
      [414]="URI Too Long"
      [415]="Unsupported Media Type"
      [416]="Range Not Satisfiable"
      [417]="Expectation Failed"
      [418]="I'm a teapot"
      [421]="Misdirected Request"
      [422]="Unprocessable Entity"
      [423]="Locked"
      [425]="Too Early"
      [426]="Upgrade Required"
      [428]="Precondition Required"
      [429]="Too Many Requests"
      [431]="Request Header Fields Too Large"
      [451]="Unavailable For Legal Reasons"
      [500]="Internal Server Error"
      [501]="Not Implemented"
      [502]="Bad Gateway"
      [503]="Service Unavailable"
      [504]="Gateway Timeout"
      [505]="HTTP Version Not Supported"
      [506]="Variant Also Negotiates"
      [507]="Insufficient Storage"
      [508]="Loop Detected"
      [510]="Not Extended"
      [511]="Network Authentication Required"
      [520]="Web Server Returned an Unknown Error"
      [521]="Web Server Is Down"
      [522]="Connection Timed Out"
      [523]="Origin Is Unreachable"
      [524]="A Timeout Occurred"
      [525]="SSL Handshake Failed"
      [526]="Invalid SSL Certificate"
      [527]="Railgun Error"
      [530]="N/A"
      [000]="NXDomain or Failed to Connect"
    )

    local url="$1"
    local response redirect_url http_code status_message

    echo -n "Checking ${url} - "

    response=$(curl -4s --insecure --connect-timeout 3 --write-out "%{http_code} %{redirect_url}" --output /dev/null "${url}")
    http_code=$(echo "$response" | awk '{print $1}')
    redirect_url=$(echo "$response" | awk '{print $2}')

    # Get the status message from the associative array
    status_message="${http_status_codes[$http_code]:-Unknown Status Code}"

    # Colorize output based on status code
    case "$http_code" in
      2*) color="\e[32m" ;;  # Green for success
      3*) color="\e[33m" ;;  # Yellow for redirects
      4*) color="\e[31m" ;;  # Red for client errors
      5*) color="\e[35m" ;;  # Magenta for server errors
      *) color="\e[37m" ;;   # White/gray for unknown or other statuses
    esac

    # Handle redirection and output
    if [[ "$http_code" =~ ^30[0-8]$ ]]; then
      echo -e "${color}${http_code} ${status_message} >> ${redirect_url}\e[0m"
    else
      echo -e "${color}${http_code} ${status_message}\e[0m"
    fi
  }

  domain_filter() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    ip=$(echo "${1}" | grep -oE "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]).*" | cut -d ' ' -f1 | head -n1)
    hostname=$(echo "${1}" | sed -E 's/https?:\/\///g' | sed 's/www.//')

    if [[ -n ${ip} ]]; then
      check_http_response "http://${ip}" > "${tmp_dir}/ip1" &
      check_http_response "https://${ip}" > "${tmp_dir}/ip2" &
    elif [[ -n ${hostname} ]] ; then
      check_http_response "http://${hostname}" > "${tmp_dir}/host1" &
      check_http_response "https://${hostname}" > "${tmp_dir}/host2" &
      check_http_response "http://www.${hostname}" > "${tmp_dir}/host3" &
      check_http_response "https://www.${hostname}" > "${tmp_dir}/host4" &
    else
      echo "Please Input Valid IP / Hostname..."
    fi
    wait
    cat "${tmp_dir}/ip1" "${tmp_dir}/ip2" "${tmp_dir}/host1" "${tmp_dir}/host2" "${tmp_dir}/host3" "${tmp_dir}/host4" 2>/dev/null
  }

  if [[ -z ${1} ]]; then
    echo "web <Domain or IP> - Check HTTP Response Code"
  else
    domain_filter "${1}"
  fi
}

check_ssl() {
  additional_functions_ssl_filter() {
    openssl x509 -noout -dates -ext subjectAltName | sed 's/notBefore/\nExpiry Date :\n    notBefore/' | sed 's/notAfter/    notAfter/' | sed 's/X509v3 Subject Alternative Name:/\nSubject Alternative Name :/' | sed 's/, DNS/\n    DNS/g' | sed 's/DNS:/DNS: /g'
  }

  hostname=$(tr '[:upper:]' '[:lower:]' <<< "${1}" | cut -d'@' -f2 | tr -c '0-9a-z._\-' '\n' | grep "\." | head -n1 )

  if [[ -n ${hostname} ]] && [[ -z ${2} ]]; then
    bannerColor "Checking ${hostname} - Port 443" "="
    ssl_result=$(echo | timeout 3 openssl s_client -connect "${hostname}:443")
  elif [[ -z ${hostname} ]] || [[ ! ${2} =~ ^[0-9]+$	 ]]; then
    echo "ssl <Domain or IP> <Port> - Check SSL Details (Default Port 443)"
  elif [[ -n ${hostname} ]] && [[ ${2} =~ ^(21|25|110|143|587|3306)$ ]]; then
    case "${2}" in
      25|587)
        banner="SMTP"
        type="smtp"
        ;;
      21)
        banner="FTP over TLS"
        type="ftp"
        ;;
      110)
        banner="POP3"
        type="pop3"
        ;;
      143)
        banner="IMAP"
        type="imap"
        ;;
      3306)
        banner="MySQL"
        type="mysql"
        ;;
    esac
    bannerColor "Checking ${hostname} - Port ${2} - STARTTLS - ${banner}" "="
    ssl_result=$(echo | timeout 3 openssl s_client -connect "${hostname}:${2}" -starttls "${type}")
    if [[ ! ${?} == 0 ]]; then
      bannerColor "trying normal SSL..." "="
      ssl_result=$(echo | timeout 3 openssl s_client -connect "${hostname}:${2}")
    fi
  elif [[ -n ${hostname} ]] && [[ -n ${2} ]]; then
    bannerColor "Checking ${hostname} - Port ${2}" "="
    ssl_result=$(echo | timeout 3 openssl s_client -connect "${hostname}:${2}")
  fi
  if [ ${?} -eq 124 ]; then
    echo "SSL Check TIMED OUT"
  else
    additional_functions_ssl_filter <<< "${ssl_result}"
  fi
}

generate_csr_and_private_key() {
  gather_info() {
    read_country=$(get_input "Country Name (2 letter code)")
    read_state=$(get_input "State or Province Name (full name)")
    read_city=$(get_input "Locality Name (eg, city)")
    read_org=$(get_input "Organization Name (eg, company)")
    read_commonname=$(get_input "Common Name (e.g. website URL)")
    read_email=$(get_input "Email Address")
  }

  build_arguments() {
    if [[ -n ${read_country} ]]; then
      country="/C=${read_country}"
    fi
    if [[ -n ${read_state} ]]; then
      state="/ST=${read_state}"
    fi
    if [[ -n ${read_city} ]]; then
      city="/L=${read_city}"
    fi
    if [[ -n ${read_org} ]]; then
      org="/O=${read_org}"
    fi
    if [[ -n ${read_commonname} ]]; then
      commonname="/CN=${read_commonname}"
    fi
    if [[ -n ${read_email} ]]; then
      email="/emailAddress=${read_email}"
    fi
  }

  if [[ -d "/mnt/c" ]]; then
    sslpath="/mnt/c/SSLCertificates"
  else
    sslpath="${HOME}/SSLCertificates"
  fi

  generate_csr_key() {
    commonname_transformed="${read_commonname/#\*/wildcard}"
    certpath="${sslpath}/${commonname_transformed}_$(date +%Y)/${commonname_transformed}_$(date +%Y)"
    create_dir "${sslpath}/${commonname_transformed}_$(date +%Y)"
    openssl req -new -newkey rsa:4096 -nodes -keyout "${certpath}.key" -out "${certpath}.csr" -subj "${country}${state}${city}${org}${commonname}${email}"
  }

  check_variable() {
    for vars in ${@}; do
      var="${!vars}"
      if [[ -z ${var} ]]; then
        echo "EMPTY"
      fi
    done
  }

  #"/C=${read_country}/ST=${read_state}/L=${read_city}/O=${read_org}/OU=${read_orgunit}/CN=${read_commonname}/emailAddress=${read_email}"


  bannerColor "SSL Certificate Request and Private Key Generator Tool" "="
  gather_info
  build_arguments
  if [[ -n $(check_variable country state city org commonname email) ]]; then
    echo "Incomplete Information Provided for CSR..."
    return
  fi
  generate_csr_key
  echo
  cat "${certpath}.key" "${certpath}.csr"
  echo
  echo "CSR Output : ${certpath}.csr"
  echo "Key Output : ${certpath}.key"
  echo
  echo "Please use \"pkcs\" function to continue"
  echo
}

check_pkcs() {
  bannerColor "All-In-One SSL Certificate Tool" "="

  if ! command -v zip &>/dev/null; then
    echo "zip command not found"
    sudo apt install -y zip
    echo
  fi

  get_pkcs7_data() {
    # Use a regular array to store the input
    declare -a final

    # Initialize a variable for the input line
    line=""

    # Loop to read input until "-----END PKCS7-----" is encountered
    echo "Enter the PKCS#7 certificate data :"
    echo
    echo "Starts with '-----BEGIN PKCS7-----'"
    echo " Ends  with '----- END  PKCS7-----'"
    echo
    while [[ ! "${line}" =~ "-----END PKCS7-----" ]]; do
      read -rep "" line </dev/tty
      final+=("${line}")
    done

    # Combine the array elements into a single string
    cert_data=$(printf "%s\n" "${final[@]}")

    echo -e "\n\n\n\n\n\nResult :\n\n\n"

    # Extract certificates using OpenSSL
    pem_data="$(openssl pkcs7 -print_certs <<< "${cert_data}")"

    echo "${pem_data}"
  }

  build_variables() {
    if [[ -d "/mnt/c" ]]; then
      sslpath="/mnt/c/SSLCertificates"
    else
      sslpath="${HOME}/SSLCertificates"
    fi
    commonname="$(head -n 1 <<< "${pem_data}" | rev | cut -d' ' -f1 | rev)"
    commonname_transformed="${commonname/#\*/wildcard}"
    friendly_name="${commonname}_$(date +%Y)"
    pfx_password="${commonname#*.}$(date +%Y)"
    output_folder_name="${sslpath}/${commonname_transformed}_$(date +%Y)"
    output_file_name="${output_folder_name}/${commonname_transformed}_$(date +%Y)"
    zip_output_path="${sslpath}/ZIPs"
    zip_output_file_name="${zip_output_path}/${commonname_transformed}_$(date +%Y).zip"
    cacert="${output_file_name}CA.crt"
    echo -e "\n\n"
    create_dir "${output_folder_name}" "${zip_output_path}"
    echo
    echo "Working Directory : ${output_folder_name}"
  }

  cleanup() {
      rm -f "${zip_output_file_name}" "${output_file_name}.crt" "${output_file_name}.p7b" "${output_file_name}.pfx" "${output_file_name}_pfx_password.txt" "${cacert}"
  }

  output_pkcs7() {
    echo "${cert_data}" > "${output_file_name}.p7b"
  }

  convert_to_pem() {
    awk '
    BEGIN {RS="-----END CERTIFICATE-----\n"}
    NR==1 { print $0 RS | "grep -v ^$ > \"" output_file_name ".crt\""; next }
    { print $0 RS | "grep -v ^$ > \"" output_file_name "CA.crt\"" }
    ' output_file_name="${output_file_name}" <<< "${pem_data}"
  }

  convert_to_pfx() {
    openssl_version="$(openssl version)"
    echo
    echo "Using ${openssl_version}"
    if [[ ${openssl_version} =~ ^"OpenSSL 3" ]]; then
      openssl pkcs12 -export -out "${output_file_name}.pfx" -inkey "${output_file_name}.key" -in "${output_file_name}.crt" -certfile "${cacert}" -name "${friendly_name}" -password pass:"${pfx_password}" -descert -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES
    else
      openssl pkcs12 -export -out "${output_file_name}.pfx" -inkey "${output_file_name}.key" -in "${output_file_name}.crt" -certfile "${cacert}" -name "${friendly_name}" -password pass:"${pfx_password}"
    fi
    echo
    if [[ -f ${output_file_name}.pfx ]]; then
      echo "PFX Output File : ${commonname_transformed}.pfx"
      echo
      echo "PFX Friendly Name : ${friendly_name}"
      echo
      echo "ZIP and PFX Password : ${pfx_password}"
      echo "PFX Password is ${pfx_password}" > "${output_file_name}_pfx_password.txt"
      echo
      cd "${output_folder_name}" && zip -r -P "${pfx_password}" -q -FS "${zip_output_file_name}" "./" && echo "Files Zipped at ${zip_output_file_name} !"
      echo
      echo "Ready to send to Customer !"
    else
      echo "ERROR Generating PFX !"
    fi
  }

  get_pkcs7_data
  build_variables
  cleanup
  output_pkcs7
  convert_to_pem
  if [[ ! -f "${output_file_name}.key" ]]; then
    echo
    echo "Private Key not found..."
    echo
    echo "Expecting ${output_file_name}.key"
    echo
    echo "${output_file_name}.pfx and ZIP file not generated"
    exit 1
  else
    convert_to_pfx
  fi
  unset final line cert_data pem_data sslpath commonname commonname_transformed friendly_name pfx_password output_folder_name output_file_name zip_output_path zip_output_file_name cacert openssl_version
}

decode_csr() {
  get_csr_data() {
    local final line
    # Use a regular array to store the input
    declare -a final

    # Initialize a variable for the input line
    line=""

    # Loop to read input until "-----END CERTIFICATE REQUEST-----" is encountered
    echo "Enter the Certificate Signing Request data :"
    echo
    echo "Starts with '-----BEGIN CERTIFICATE REQUEST-----'"
    echo " Ends  with '-----END CERTIFICATE REQUEST-----'"
    echo
    while [[ ! "${line}" =~ "-----END CERTIFICATE REQUEST-----" ]]; do
      read -rep "" line </dev/tty
      final+=("${line}")
    done

    # Combine the array elements into a single string
    csr_data=$(printf "%s\n" "${final[@]}")
  }

  get_csr_data
  echo -e "\n\n\n"
  openssl req -noout -subject <<< "${csr_data}" | tr ',' '\n' | sed 's/subject=//' | sed 's/^C =/ Country       =/' | sed 's/ST =/State         =/' | sed 's/L =/Locality      =/' | sed 's/O =/Organization  =/' | sed 's/CN =/Common Name   =/' | sed 's/emailAddress =/Email Address =/'
  unset final line csr_data
}

decode_ssl() {
  get_ssl_data() {
    local final line
    # Use a regular array to store the input
    declare -a final

    # Initialize a variable for the input line
    line=""

    # Loop to read input until "-----END CERTIFICATE-----" is encountered
    echo "Enter the SSL certificate data :"
    echo
    echo "Starts with '-----BEGIN CERTIFICATE-----'"
    echo " Ends  with '-----END CERTIFICATE-----'"
    echo
    while [[ ! "${line}" =~ "-----END CERTIFICATE-----" ]]; do
      read -rep "" line </dev/tty
      final+=("${line}")
    done

    # Combine the array elements into a single string
    cert_data=$(printf "%s\n" "${final[@]}")
  }

  get_ssl_data
  echo -e "\n\n\n"
  openssl x509 -noout -issuer -dates -ext subjectAltName <<< "${cert_data}" | sed 's/notBefore/\nExpiry Date :\n    notBefore/' | sed 's/notAfter/    notAfter/' | sed 's/X509v3 Subject Alternative Name:/\nSubject Alternative Name :/' | sed 's/, DNS/\n    DNS/g' | sed 's/DNS:/DNS: /g'
  unset final line cert_data
}

check_ptr1() {
  if [[ -z ${1} ]]; then
    echo "ptr <IP> - Check which NameServer is responsible for the PTR record zone"
  else
    result=$(dig +trace -x "$(check_valid_ipv4 <<< "${1}")" @"${dns_server}" 2>/dev/null) # | grep -v "^;\|NSEC3\|RRSIG\|DS\|SOA\|^\.\|^in-addr.arpa" | tail -n+6 | head -n-1
    filtered_result="$(grep "NS" <<< "${result}" | grep -v "^\.\|RRSIG\|NSEC3\|^in-addr")"
    echo_color darkyellow "$(grep -E "^[0-9]+\.in-addr\.arpa\." <<< "${filtered_result}")"
    echo
    echo_color darkyellow "$(grep -E "^[0-9]+\.[0-9]+\.in-addr\.arpa\." <<< "${filtered_result}")"
    echo
    echo_color darkyellow "$(grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.in-addr\.arpa\." <<< "${filtered_result}")"
    echo
    echo_color darkyellow "$(grep "PTR" <<< "${result}")"
  fi
}

split_dkim() {
  bannerColor "DKIM Splitter" "="
  read -rep "Input DKIM : " dkim < /dev/tty
  local dkim length start end segment output
  length="${#dkim}"
  start=0
  end=130

  echo
  echo "Input length : ${length}"
  echo

  if [[ ${length} -lt ${end} ]]; then
    echo "Length is shorter than ${end} , no splitting required"
    exit 1
  fi

  while [[ ${start} -lt ${length} ]]; do
    segment="${dkim:start:end}"
    if [[ -z "${output}" ]]; then
      output="( \"${segment}\""
    elif [[ ${#segment} -lt ${end} ]]; then
      output="${output}\n\"${segment}\" )"
    else
      output="${output}\n\"${segment}\""
    fi
    (( start=start+end ))
  done
  echo "Split DKIM - Length per line - ${end} :"
  echo
  echo
  echo -e "${output}"
}

email_template() {
  (
    echo "Subject :"
    echo
    echo "Monthly Sales Report"
    echo
    echo "Body :"
    echo
    echo "Hi IPServerOne Test Email,"
    echo
    echo "Please refer to attachment for the Monthly Sales Report."
    echo
    echo "Thank you"
  )
}

additional_functions() {
  end_spin
  echo
  if [[ "${ascii_value}" -eq 63 ]] || [[ ${1} == "help" ]]; then
    help_text
  elif [[ ${1} =~ ^"debug" ]]; then
    debug_toggle "${2}"
  elif [[ ${1} =~ ^"color" ]]; then
    color_toggle "${2}"
  elif [[ ${1} == "history" ]]; then
    search_history "${2}"
  elif [[ ${1} == "chist" ]]; then
    clear_history
  elif [[ ${1} == "clear" ]] || [[ ${1} == "reset" ]]; then
    reset
    clear
  elif [[ ${1} == "dns" ]]; then
    change_dns "${2}"
  elif [[ ${1} == "datas" ]]; then
    change_ip_datasource "${2}"
  elif [[ ${1} == "pmp" ]]; then
    curl4 https://pmp.matrixevo.com
  elif [[ ${1} =~ ^"pass" ]]; then
    password_generator "${@:2}"
  elif [[ ${1} == "ip" ]]; then
    curl4 https://ip.matrixevo.com
  elif [[ ${1} =~ ^"whois" ]]; then
    check_whois "${2}"
  elif [[ ${1} == "grp" ]]; then
    curl4 https://grp.matrixevo.com
  elif [[ ${1} =~ ^"mcmc" ]]; then
    curl4 https://matrixevo.com/mcmc_check.sh | bash -s -- "${2}" "${3}"
  elif [[ ${1} =~ ^"nc" ]] || [[ ${1} =~ ^"telnet" ]]; then
    check_port "${@:2}"
  elif [[ ${1} =~ ^(tr|traceroute) ]]; then
    check_traceroute "${2}"
  elif [[ ${1} =~ ^"ping" ]]; then
    check_ping "${2}"
  elif [[ ${1} =~ ^"web" ]]; then
    check_web "${2}"
  elif [[ ${1} =~ ^"ssl" ]]; then
    check_ssl "${2}" "${3}"
  elif [[ ${1} == "gencsr" ]]; then
    generate_csr_and_private_key
  elif [[ ${1} == "pkcs" ]]; then
    check_pkcs
  elif [[ ${1} =~ ^"mail" ]]; then
    if [[ -z ${2} ]]; then
      echo "mail <Domain> - check DNS records essential for successful mail delivery"
    else
      curl4 https://matrixevo.com/checkmail.sh | bash -s -- "${2}" "${dns_server}" --color
    fi
  elif [[ ${1} =~ ^"ptr" ]]; then
    check_ptr1 "${2}"
  elif [[ ${1} == "dkim" ]]; then
    split_dkim
  elif [[ ${1} == "emt" ]]; then
    email_template
  elif [[ ${1} == "deccsr" ]]; then
    decode_csr
  elif [[ ${1} == "decssl" ]]; then
    decode_ssl
  fi
  echo
}

repeat_functions() {
  end_spin
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
      command=$(cut -d' ' -f3- <<< ${@/#repeat/})
      repeat_times="${2}"
      while [[ ${repeat_times::1} == "0" ]]; do
        repeat_times=${repeat_times/#0/}
        if [[ -z ${repeat_times} ]]; then
          repeat_times=3
        fi
      done
    fi
    while [[ ! "${count}" == "${repeat_times}" ]]; do
      ((count++))
      echo "Repeating - ${count}/${repeat_times} - ${command}"
      additional_functions ${command}
    done
  fi
  echo
  unset command count repeat_times
}

check_root_hostname() { # Checking for root hostname without subdomain
  hostnamedotcount=$(echo "${1}" | grep -o "\." | wc -l)
  roothostname="${1}"
  if [[ ${hostnamedotcount} -gt 1 ]]; then
    roothostname=$(echo "${1}" | cut -d'.' -f"${hostnamedotcount}"-)
    if [[ ${#roothostname} =~ 5|6 ]] && [[ ${roothostname:0:3} =~ co|com|org|net|int|edu|gov|mil|biz ]]; then
      roothostname=$(echo "${1}" | cut -d'.' -f"$(("${hostnamedotcount}" - 1))"-)
    fi
  fi
  echo "${roothostname}"
}

check_hostname() {
  local hostnamedotcount roothostname ns_name ns_record a_record mx_record mail_record webmail_record txt_record ptr_a_record ptr_mail_record ptr_webmail_record ipinfo_a_record ipinfo_mail_record ipinfo_webmail_record
  # GATHERING INFO
  ns_record=$(dig_short NS "${1}")
  if [[ ${ns_record} =~ "timed out" ]]; then
    end_spin
    echo_color red "DNS NameServer Lookup timed out"
    return
  fi
  if [[ -z ${ns_record} ]]; then
    ns_name="$(check_root_hostname "${1}")"
    ns_record=$(dig_short NS "${ns_name}")
  else
    ns_name=${1}
  fi
  a_record=$(dig_short A "${1}")
  check_port "${a_record}" "cp" "wait" &
  www_record=$(dig_short A "www.${1}")
  mx_record=$(dig_short MX "${1}")
  mail_record=$(dig_short A "mail.${1}")
  webmail_record=$(dig_short A "webmail.${1}")
  txt_record=$(dig_short TXT "${1}")
  # Error If No Info Found
  if [[ -z ${ns_record} ]] && [[ -z ${a_record} ]] && [[ -z ${www_record} ]] && [[ -z ${mx_record} ]] && [[ -z ${mail_record} ]] && [[ -z ${webmail_record} ]] && [[ -z ${txt_record} ]]; then
    # history -d "$(history 1 | awk '{print $1}')" - Uncomment to delete the last invalid entry from history
    end_spin
    echo_color red "Please Input Valid IP / Hostname... or Domain ${1} Not Found or No DNS Records"
    return
  fi
  ptr_a_record=$(check_ptr "${a_record}")
  ptr_www_record=$(check_ptr "${www_record}")
  ptr_mail_record=$(check_ptr "${mail_record}")
  ptr_webmail_record=$(check_ptr "${webmail_record}")
  ipinfo_a_record=$(ipinfo_org_only "${a_record}")
  ipinfo_www_record=$(ipinfo_org_only "${www_record}")
  ipinfo_mail_record=$(ipinfo_org_only "${mail_record}")
  ipinfo_webmail_record=$(ipinfo_org_only "${webmail_record}")
  end_spin
  # OUTPUT BELOW
  echo
  echo_color blue "NS record for ${ns_name}"
  echo_color darkyellow "${ns_record}"
  echo
  echo_color blue "A record for ${1}"
  echo_color darkyellow "$(check_if_cloud_hosting "${a_record}")"
  echo_color green "${ptr_a_record}"
  echo_color lightred "${ipinfo_a_record}"
  echo
  echo_color blue "A record for www.${1}"
  echo_color darkyellow "$(check_if_cloud_hosting "${www_record}")"
  echo_color green "${ptr_www_record}"
  echo_color lightred "${ipinfo_www_record}"
  echo
  echo_color blue "MX record for ${1}"
  echo_color darkyellow "${mx_record}"
  echo
  echo_color blue "A record for mail.${1}"
  echo_color darkyellow "$(check_if_cloud_hosting "${mail_record}")"
  echo_color green "${ptr_mail_record}"
  echo_color lightred "${ipinfo_mail_record}"
  echo
  echo_color blue "A record for webmail.${1}"
  echo_color darkyellow "$(check_if_cloud_hosting "${webmail_record}")"
  echo_color green "${ptr_webmail_record}"
  echo_color lightred "${ipinfo_webmail_record}"
  echo
  echo_color blue "TXT record for ${1}"
  echo_color darkyellow "${txt_record}"
  echo
  touch "${HOME}/.digg_wait"
  wait
  unset hostnamedotcount roothostname ns_name ns_record a_record mx_record mail_record webmail_record txt_record ptr_a_record ptr_mail_record ptr_webmail_record ipinfo_a_record ipinfo_mail_record ipinfo_webmail_record
}

bogon_reference() {
  (
    echo
    echo_color green "Bogon / Private IP"
    echo
    echo_color blue "Reference : https://ipinfo.io/bogon"
  )
}

check_ip() {
  local ptr_a_record ipinfo_a_record
  end_spin
  # OUTPUT BELOW
  echo
  case ${1} in
    0.0.0.0|10.*|172.16.*|192.168.*)
      echo_color darkyellow "${1} - Private-use networks" ; bogon_reference ;;
    100.64.*)
      echo_color darkyellow "${1} - Carrier-grade NAT" ; bogon_reference ;;
    127.0.53.53)
      echo_color darkyellow "${1} - Name collision occurrence" ; bogon_reference ;;
    127.*)
      echo_color darkyellow "${1} - Loopback" ; bogon_reference ;;
    169.254.*)
      echo_color darkyellow "${1} - Link local" ; bogon_reference ;;
    192.0.0.*)
      echo_color darkyellow "${1} - IETF protocol assignments" ; bogon_reference ;;
    192.0.2.*)
      echo_color darkyellow "${1} - TEST-NET-1" ; bogon_reference ;;
    198.18.*)
      echo_color darkyellow "${1} - Network interconnect device benchmark testing" ; bogon_reference ;;
    198.51.100.*)
      echo_color darkyellow "${1} - TEST-NET-2" ; bogon_reference ;;
    203.0.113.*)
      echo_color darkyellow "${1} - TEST-NET-3" ; bogon_reference ;;
    224.*)
      echo_color darkyellow "${1} - Multicast" ; bogon_reference ;;
    240.*)
      echo_color darkyellow "${1} - Reserved for future use" ; bogon_reference ;;
    255.255.255.255)
      echo_color darkyellow "${1} - Limited broadcast" ; bogon_reference ;;
    *)
      # GATHERING INFO
      check_port "${1}" "cp" "wait" &
      ptr_a_record=$(check_ptr "${1}")
      ipinfo_a_record=$(check_ipinfo "${1}" | sed 's/\"/ /g')
      echo_color darkyellow "$(check_if_cloud_hosting "${1}")"
      echo
      echo_color blue "PTR :"
      echo
      echo_color green "${ptr_a_record}"
      echo
      echo_color blue "IPInfo :"
      echo_color lightred "${ipinfo_a_record}"
  esac
  echo
  touch "${HOME}/.digg_wait"
  wait
  unset ptr_a_record ipinfo_a_record
}

filter() {
  local ip hostname
  ascii_value="$(printf "%d" "'${1:0:1}")"
  if [[ ${1} =~ ^(color |datas |debug |dns |history |mail |mcmc |nc |pass |ping |ptr |ssl |telnet |tr |traceroute |web |whois ) ]] || [[ "${ascii_value}" -eq 63 ]] || \
    [[ ${1} =~ ^(chist|clear|color|datas|debug|dkim|dns|emt|gencsr|grp|help|history|ip|mail|mcmc|nc|pass|ping|pkcs|pmp|ptr|repeat|reset|ssl|telnet|tr|traceroute|web|whois|deccsr|decssl)$ ]]; then
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
    end_spin
    echo_color red "Please Input Valid IP / Hostname..."
  elif [[ -n ${ip} ]]; then
    history -s "${ip}"
    check_ip "${ip}"
  elif [[ -n ${hostname} ]] ; then
    while [[ ${hostname:(-1)} == "." ]] || [[ ${hostname::1} == "." ]]; do # Trim front and back extra dots (.)
      if [[ ${hostname:(-1)} == "." ]]; then # Trim Back
        hostname="${hostname%?}"
      fi
      if [[ ${hostname::1} == "." ]]; then # Trim Front
        hostname="${hostname:1}"
      fi
    done
    history -s "${hostname}"
    check_hostname "${hostname}"
  fi
  rm -f "${HOME}/.digg_wait"
  unset ip hostname ascii_value
}

start() {
  local user_input
  initialize_cloud_hosting_ip_list
  if [[ $* =~ "--color" ]]; then
    color_toggle "on"
  fi
  # Actually Starts / Loops Here
  if [[ $1 ]] && [[ ! $1 == "--color" ]]; then
    user_input=${@/#--color /}
    spin & spin_pid="${!}"
    time filter "${user_input}"
    end_spin
  else
    while IFS= read -rep "$(echo_color yellow "Current DNS Server : ${dns_server} - Input IP / Hostname : ")" user_input </dev/tty ; do
      spin & spin_pid="${!}"
      time filter "${user_input}"
      history -w "${history_file}"
      end_spin
      unset user_input
    done
  fi
}

start "${*}"
