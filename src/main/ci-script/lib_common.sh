#!/usr/bin/env bash

SED="sed"
TMP="/tmp"

# arguments: lead_pattern, tail_pattern, snippet_file, target_file
function append_or_replace() {
    local lead_pattern="$1"
    local tail_pattern="$2"
    local snippet_file="$3"
    local target_file="$4"

    local lead=$(echo "${lead_pattern}" | ${SED} 's/^\^//' | ${SED} 's/\$$//')
    local tail=$(echo "${tail_pattern}" | ${SED} 's/^\^//' | ${SED} 's/\$$//')

    if [[ -z $(grep -E "${lead_pattern}" ${target_file}) ]] || [[ -z $(grep -E "${tail_pattern}" ${target_file}) ]]; then
        if [ -w "${target_file}" ]; then
            echo "${lead}" >> ${target_file}
            cat ${snippet_file} >> ${target_file}
            echo "${tail}" >> ${target_file}
        else
            echo "Need to append to file '${target_file}', content:"
            echo "${lead}"
            cat ${snippet_file}
            echo "${tail}"
            echo "Input password if prompted."
            sudo sh -c "echo '${lead}' >> ${target_file}"
            sudo sh -c "cat ${snippet_file} >> ${target_file}"
            sudo sh -c "echo '${tail}' >> ${target_file}"
        fi
    else
        local tmp_file=${TMP}/insert_or_replace.tmp
        # see: http://superuser.com/questions/440013/how-to-replace-part-of-a-text-file-between-markers-with-another-text-file
        $SED -e "/$lead_pattern/,/$tail_pattern/{ /$lead_pattern/{p; r ${snippet_file}
        }; /$tail_pattern/p; d }" ${target_file} > ${tmp_file}
        if [ -w "${target_file}" ]; then
            cat ${tmp_file} > ${target_file}
        else
            echo "Need to replace in file '${target_file}', replace content between:"
            echo "${lead} ... ${tail} into:"
            echo "${lead}"
            cat ${snippet_file}
            echo "${tail}"
            echo "Input password if prompted."
            sudo sh -c "cat ${tmp_file} > ${target_file}"
        fi
    fi
}

function download() {
    local url=$1
    local dir=$2
    local filename=$3
    echo "downloading ${url}"
    aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0 -d ${dir} -o ${filename} "${url}"
}

## arguments: jar/zip archive, file, target
## returns:
#extract_file_from_archive() {
#    local archive="$1"
#    local file="$2"
#    local target="$3"
#    if [[ ${file:0:1} == / ]]; then file=${file:1}; fi
#    echo "EXTRACT unzip -p ${archive} ${file} > ${target}" 1>&2
#    unzip -p ${archive} ${file} > ${target}
#    local result=$?
#    cat ${target} 1>&2
#    echo "EXTRACT return code ${result}" 1>&2
#}

function get_linux_release() {
    source /etc/os-release
    local os_name="${ID}"
    local os_version="${VERSION_ID}"
    local os_label="${os_name}:${os_version}"

    local os_serial="${ID_LIKE}"
    case ${os_serial} in
        debian*)
            case ${os_name} in
                ubuntu)
                    if version_gt ${os_version} "14.00"; then
                        PLATFORM=debian
                    else
                        supported_os_help ${os_label}
                        exit 1
                    fi
                    ;;

                *)
                    supported_os_help ${os_label}
                    exit 1
            esac
            ;;
        rhel*)
            case ${os_name} in
                centos)
                    if version_gt ${os_version} "6"; then
                        PLATFORM=rhel
                    else
                        supported_os_help ${os_label}
                        exit 1
                    fi
                    ;;
                *)
                    supported_os_help ${os_label}
                    exit 1
                    ;;
            esac
            ;;
        *)
            supported_os_help ${os_label}
            exit 1
            ;;
    esac
    echo "your os platform is: ${os_label}"
}

# public repo only, example: https://api.github.com/repos/home1-oss/docker-nexus3
# arguments: namespace, project
function github_project_info() {
    local git_service="https://api.github.com"
    local namespace="${1}"
    local project="${2}"
    local project_info=$(curl -s -X GET "${git_service}/repos/${namespace}/${project}")
    echo ${project_info} | tr -d '\n\r'
}

# arguments: gitlab_url, namespace, project, token
function gitlab_project_info() {
    local gitlab_url="${1}"
    local namespace="${2}"
    local project="${3}"
    local token="${4}"

    # CI_PROJECT_URL note: ${namespace}%2F${project}
    local project_info=$(curl -s -X GET "${gitlab_url}/api/v3/projects/${namespace}%2F${project}?private_token=${token}")
    echo ${project_info} | tr -d '\n\r'
}

# arguments: gitlab_url, user, pass
function gitlab_session() {
    local gitlab_url="${1}"
    local user="${2}"
    local pass="${3}"

    local json=$(curl -s --request POST "${gitlab_url}/api/v3/session?login=${user}&password=${pass}")
    echo ${json} | tr -d '\n\r'
}

# To obtaining gitlab private_token:
# 1. copy from gitlab -> Profile Settings -> Account -> Private Token
# 2. curl --request POST "http://gitlab/api/v3/session?login={邮箱}&password={密码}"
# arguments: gitlab_url, user, pass
function gitlab_token() {
    local gitlab_url="${1}"
    local user="${2}"
    local pass="${3}"

    local session=$(gitlab_session "${gitlab_url}" "${user}" "${pass}")
    echo ${session} | jq -r ".private_token"
}

# arguments:
function git_commit_id() {
    echo "$(git rev-parse HEAD)"
}

# arguments: git_service, user, pass
function git_credentials_entry() {
    local git_service="${1}"
    local user="${2}"
    local pass="${3}"

    local protocol=$(echo "${git_service}" | awk -F:/ '{print $1}')
    local user_colon_pass="$(url_encode ${user}):$(url_encode ${pass})"
    echo "${protocol}://${user_colon_pass}@$(url_domain ${git_service})"
}

# arguments: git_domain
function git_credentials_pass() {
    local git_domain="${1}"

    local line="$(cat ${HOME}/.git-credentials | grep ${git_domain})"
    local user_colon_pass=$(echo ${line} | awk -F/ '{print $3}' | awk -F@ '{print $1}')
    url_decode "$(echo ${user_colon_pass} | awk -F: '{print $2}')"
}

# arguments: git_domain
function git_credentials_user() {
    local git_domain="${1}"

    local line="$(cat ${HOME}/.git-credentials | grep -Ev ^# | grep ${git_domain})"
    local user_colon_pass=$(echo ${line} | awk -F/ '{print $3}' | awk -F@ '{print $1}')
    url_decode "$(echo ${user_colon_pass} | awk -F: '{print $1}')"
}

function git_repo_slug() {
    echo $(git remote show origin -n | ruby -ne 'puts /^\s*Fetch.*:(\d+\/)?(.*).git/.match($_)[2] rescue nil')
}

# usage: host_ip_address=$(eval "$(hostip_expression)")
function hostip_expression() {
    #echo "ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print \$2}'"

    if [ ${PLATFORM} == "mac" ]; then
        echo "ipconfig getifaddr en0 || ipconfig getifaddr en1"
    else
        # linux, initd eth0 || systemd en*
        # echo "ifconfig -s | grep -E 'eth0|en' | cut -d ' ' -f 1 | xargs ifconfig | grep inet | grep -v inet6 | sed 's/inet[^0-9]*\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/;s/^[[:blank:]]*//'"
        echo "ifconfig -s | grep -E '^eth0|^en' | cut -d ' ' -f 1 | xargs ifconfig | grep inet | grep -v inet6 | sed -E 's/inet[^0-9]*([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*/\1/;s/^[[:blank:]]*//'"
    fi
}

# arguments: var_name, prompt, default_val
function read_plain_input() {
    local var_name="${1}"
    local prompt="${2}"
    local default_val="${3}"

    printf "${prompt}"
    if [ ! -z "${default_val}" ]; then printf " default is: ${default_val}\n"; else printf "\n"; fi
    read "${var_name}"
    if [ -z "${!var_name}" ] && [ ! -z "${default_val}" ]; then
        eval ${var_name}=${default_val}
    fi
}

# arguments: var_name, prompt, default_val
function read_secret_input() {
    local var_name="${1}"
    local prompt="${2}"
    local default_val="${3}"

    printf "${prompt}"
    if [ ! -z "${default_val}" ]; then printf " default is: *secret*\n"; else printf "\n"; fi
    read -s "${var_name}"
    if [ -z "${!var_name}" ] && [ ! -z "${default_val}" ]; then
        eval ${var_name}=${default_val}
    fi
}

function supported_os_help() {
    local cur_platform=$1
    echo -e "not support platform: ${cur_platform} \n
    supported os platforms as below:
        mac os >= 10.11
        ubuntu >= 14.04
        centos >= 7

    we'll support more os platforms in future...
    "
}

# arguments: url
function url_domain() {
    echo "${1}" | awk -F/ '{print $3}'
}

# arguments: text
function url_encode() {
    echo "${1}" | sed 's#@#%40#'
}

# arguments: text
function url_decode() {
    echo "${1}" | sed 's#%40#@#'
}

# see: http://stackoverflow.com/questions/16989598/bash-comparing-version-numbers
# arguments: first_version, second_version
# return: if first_version is greater than second_version
function version_gt() {
    if [ ! -z "$(sort --help | grep GNU)" ]; then
        test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
    else
        test "$(printf '%s\n' "$@" | sort | head -n 1)" != "$1";
    fi
}

case "${OSTYPE}" in
    darwin*)
        PLATFORM=mac
        ;;

    linux*)
        get_linux_release
        ;;

    *)
        supported_os_help ${OSTYPE}
        exit 1
        ;;
esac

# >>>>>>>>>> ---------- lib_java ---------- >>>>>>>>>>
if type -p java; then
    echo found java executable in PATH
    _java=java
elif [[ -n "${JAVA_HOME}" ]] && [[ -x "${JAVA_HOME}/bin/java" ]];  then
    echo found java executable in JAVA_HOME
    _java="${JAVA_HOME}/bin/java"
else
    echo "no java"
    exit 1
fi
if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo java version "$version"
    if [[ "$version" < "1.8" ]]; then
        echo version is less than 1.8
        exit 1
    fi
fi
# <<<<<<<<<< ---------- lib_java ---------- <<<<<<<<<<
