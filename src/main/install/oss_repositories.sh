#!/usr/bin/env bash

declare -A OSS_REPOSITORIES_DICT
OSS_REPOSITORIES_DICT["common-config"]="/configserver/common-config"
#OSS_REPOSITORIES_DICT["common-production-config"]="/configserver/common-production-config"
OSS_REPOSITORIES_DICT["oss-archetype"]="/home1-oss/oss-archetype"
OSS_REPOSITORIES_DICT["home1-oss"]="/home1-oss/home1-oss"
OSS_REPOSITORIES_DICT["oss-build"]="/home1-oss/oss-build"
OSS_REPOSITORIES_DICT["oss-common-dependencies"]="/home1-oss/oss-common-dependencies"
OSS_REPOSITORIES_DICT["oss-configlint"]="/home1-oss/oss-configlint"
OSS_REPOSITORIES_DICT["oss-configserver"]="/home1-oss/oss-configserver"
OSS_REPOSITORIES_DICT["oss-eureka"]="/home1-oss/oss-eureka"
OSS_REPOSITORIES_DICT["oss-github"]="/home1-oss/oss-github"
#OSS_REPOSITORIES_DICT["oss-incubator"]="/home1-oss/oss-incubator"
#OSS_REPOSITORIES_DICT["oss-internal"]="/home1-oss/oss-internal"
#OSS_REPOSITORIES_DICT["oss-jenkins-pipline"]="/home1-oss/oss-jenkins-pipline"
OSS_REPOSITORIES_DICT["oss-keygen"]="/home1-oss/oss-keygen"
OSS_REPOSITORIES_DICT["oss-build"]="/home1-oss/oss-build"
OSS_REPOSITORIES_DICT["oss-lib"]="/home1-oss/oss-lib"
OSS_REPOSITORIES_DICT["oss-lib-adminclient"]="/home1-oss/oss-lib-adminclient"
OSS_REPOSITORIES_DICT["oss-lib-errorhandle"]="/home1-oss/oss-lib-errorhandle"
OSS_REPOSITORIES_DICT["oss-lib-log4j2"]="/home1-oss/oss-lib-log4j2"
OSS_REPOSITORIES_DICT["oss-lib-security"]="/home1-oss/oss-lib-security"
OSS_REPOSITORIES_DICT["oss-lib-swagger"]="/home1-oss/oss-lib-swagger"
OSS_REPOSITORIES_DICT["oss-lib-webmvc"]="/home1-oss/oss-lib-webmvc"
OSS_REPOSITORIES_DICT["oss-local"]="/home1-oss/oss-local"
OSS_REPOSITORIES_DICT["oss-release"]="/home1-oss/oss-release"
OSS_REPOSITORIES_DICT["oss-todomvc"]="/home1-oss/oss-todomvc"
OSS_REPOSITORIES_DICT["oss-todomvc-app-config"]="/configserver/oss-todomvc-app-config"
OSS_REPOSITORIES_DICT["oss-todomvc-gateway-config"]="/configserver/oss-todomvc-gateway-config"
OSS_REPOSITORIES_DICT["oss-todomvc-thymeleaf-config"]="/configserver/oss-todomvc-thymeleaf-config"
OSS_REPOSITORIES_DICT["oss-turbine"]="/home1-oss/oss-turbine"

#echo "${!OSS_REPOSITORIES_DICT[@]}"
#echo "${OSS_REPOSITORIES_DICT["key"]}"
#for key in ${!OSS_REPOSITORIES_DICT[@]}; do echo ${key}; done
#for value in ${OSS_REPOSITORIES_DICT[@]}; do echo ${value}; done
#echo "OSS_REPOSITORIES_DICT has ${#OSS_REPOSITORIES_DICT[@]} elements"

# 将oss全套项目和配置repo逐个clone到当前目录下

# arguments: git_domain, source_group
function clone_oss_repositories() {
    local git_domain="${1}"
    local source_group="${2}"

    echo "clone_oss_repositories ${git_domain} ${source_group}"
    for repository in ${!OSS_REPOSITORIES_DICT[@]}; do
        original_repository_path=$(echo ${OSS_REPOSITORIES_DICT[${repository}]} | sed 's#^/##')

        if [ ! -z "${source_group}" ]; then
            source_repository_path="${source_group}/${repository}"
            repository_path="${source_repository_path}"
        else
            repository_path="${original_repository_path}"
        fi

        if [ -d ${repository} ] && [ -d ${repository}/.git ]; then
            if [ "${repository_path}" != "${original_repository_path}" ] && [ -z "$(cd ${repository}; git remote -v | grep -E 'upstream.+(fetch)')" ]; then
                (cd ${repository} && git remote add upstream git@${git_domain}:${original_repository_path}.git && git fetch upstream)
            fi
        else
            if [ ! -d ${repository}/.git ]; then
                rm -rf ${repository}
            fi
            echo clone repository ${repository}
            #echo http: ${git_domain}/${repository_path}
            #echo ssh: git@${git_domain}:${repository_path}
            git clone git@${git_domain}:${repository_path}.git
            if [ "${repository_path}" != "${original_repository_path}" ]; then
                (cd ${repository} && git remote add upstream git@${git_domain}:${original_repository_path}.git && git fetch upstream)
            fi
        fi
    done
}
