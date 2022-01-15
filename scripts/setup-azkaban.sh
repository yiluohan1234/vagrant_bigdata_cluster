#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

setup_azkaban() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    # 编译
    cd ${INSTALL_PATH}/${AZKABAN_VERSION}
    sed -i "s@mavenCentral()@maven { url 'http://maven.aliyun.com/nexus/content/groups/public/' }@g" ${INSTALL_PATH}/${AZKABAN_VERSION}/build.gradle
    ./gradlew build -x test

    log info "create ${app_name} configuration directories"
    mkdir -p ${INSTALL_PATH}/azkaban

    tar -zxvf ${INSTALL_PATH}/${AZKABAN_VERSION}/azkaban-web-server/build/distributions/azkaban-web-server-0.1.0-SNAPSHOT.tar.gz -C ${INSTALL_PATH}/azkaban
    mv ${INSTALL_PATH}/azkaban/azkaban-web-server-0.1.0-SNAPSHOT ${INSTALL_PATH}/azkaban/web-server

    tar -zxvf ${INSTALL_PATH}/${AZKABAN_VERSION}/azkaban-exec-server/build/distributions/azkaban-exec-server-0.1.0-SNAPSHOT.tar.gz -C ${INSTALL_PATH}/azkaban
    mv ${INSTALL_PATH}/azkaban/azkaban-exec-server-0.1.0-SNAPSHOT ${INSTALL_PATH}/azkaban/exec-server

    tar -zxvf ${INSTALL_PATH}/${AZKABAN_VERSION}/azkaban-db/build/distributions/azkaban-db-0.1.0-SNAPSHOT.tar.gz -C ${INSTALL_PATH}/azkaban
    mv ${INSTALL_PATH}/azkaban/azkaban-db-0.1.0-SNAPSHOT/ ${INSTALL_PATH}/azkaban/azkaban-db

    log info "copying over ${app_name} configuration files"
    # 将resources配置文件拷贝到插件的配置目录
    cp -f $res_dir/exec/azkaban.properties ${INSTALL_PATH}/azkaban/exec-server/conf/
    cp -f $res_dir/web/azkaban.properties ${INSTALL_PATH}/azkaban/web-server/conf
    cp -f $res_dir/web/azkaban-users.xml ${INSTALL_PATH}/azkaban/web-server/conf
    echo "memCheck.enabled=false" >> ${INSTALL_PATH}/azkaban/exec-server/plugins/jobtypes/commonprivate.properties
    #rm -rf ${INSTALL_PATH}/${AZKABAN_VERSION}
    chmod -R 755 $INSTALL_PATH
    chown -R $DEFAULT_USER:$DEFAULT_GROUP $INSTALL_PATH
}

download_azkaban() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local app_version=$(eval echo \$${app_name_upper}_VERSION)
    local archive=$(eval echo \$${app_name_upper}_ARCHIVE)
    local download_url=$(eval echo \$${app_name_upper}_MIRROR_DOWNLOAD)

    log info "install ${app_name}"
    if resourceExists ${archive}; then
        installFromLocal ${archive}
    else
        installFromRemote ${archive} ${download_url}
    fi
    chown -R $DEFAULT_USER:$DEFAULT_GROUP ${INSTALL_PATH}/${app_version}
    rm ${DOWNLOAD_PATH}/${archive}
}



install_azkaban() {
    local app_name="azkaban"
    log info "setup ${app_name}"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        download_azkaban ${app_name}
        setup_azkaban ${app_name}
        setupEnv_app $app_name
        # if [ "${IS_VAGRANT}" != "true" ];then
        #     dispatch_app ${app_name}
        # fi
        source ${PROFILE}
    fi
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_azkaban
fi
