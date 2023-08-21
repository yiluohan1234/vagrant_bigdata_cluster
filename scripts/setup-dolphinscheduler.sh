#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_dolphinscheduler() {
    local app_name=$1
    local conf_dir=${INSTALL_PATH}/${app_name}-install/conf/config
    yum install -y -q psmisc
    curl -o ${INSTALL_PATH}/mysql-connector-java-8.0.16.zip -O -L https://cdn.mysql.com/archives/mysql-connector-java-8.0/mysql-connector-java-8.0.16.zip
    unzip -q ${INSTALL_PATH}/mysql-connector-java-8.0.16.zip -d ${INSTALL_PATH}
    cp ${INSTALL_PATH}/mysql-connector-java-8.0.16/mysql-connector-java-8.0.16.jar ${INSTALL_PATH}/${app_name}-install/lib/
    rm -rf ${INSTALL_PATH}/mysql-connector-java-8.0.16*

    log info "create ${app_name} configuration directories"
    sed -i 's@^ips=.*@ips="hdp101,hdp102,hdp103"@' ${conf_dir}/install_config.conf
    sed -i 's@^masters=.*@masters="hdp101"@' ${conf_dir}/install_config.conf
    sed -i 's@^workers=.*@workers="hdp101:default,hdp102:default,hdp103:default"@' ${conf_dir}/install_config.conf
    sed -i 's@^alertServer=.*@alertServer="hdp101"@' ${conf_dir}/install_config.conf
    sed -i 's@^apiServers=.*@apiServers="hdp101"@' ${conf_dir}/install_config.conf
    sed -i '/pythonGatewayServers/s/^/#/g' ${conf_dir}/install_config.conf
    sed -i 's@^installPath=.*@installPath="/opt/module/dolphinscheduler"@' ${conf_dir}/install_config.conf
    sed -i 's@^deployUser=.*@deployUser="atguigu"@' ${conf_dir}/install_config.conf
    sed -i 's@^javaHome=.*@javaHome="'${INSTALL_PATH}'/java"@' ${conf_dir}/install_config.conf
    sed -i 's@^DATABASE_TYPE=.*@DATABASE_TYPE="mysql"@' ${conf_dir}/install_config.conf
    sed -i 's@^SPRING_DATASOURCE_URL=.*@SPRING_DATASOURCE_URL="jdbc:mysql://hdp103:3306/dolphinscheduler?useUnicode=true\&characterEncoding=UTF-8\&useSSL=false"@' ${conf_dir}/install_config.conf
    sed -i 's@^SPRING_DATASOURCE_USERNAME=.*@SPRING_DATASOURCE_USERNAME="dolphinscheduler"@' ${conf_dir}/install_config.conf
    sed -i 's@^SPRING_DATASOURCE_PASSWORD=.*@SPRING_DATASOURCE_PASSWORD="dolphinscheduler"@' ${conf_dir}/install_config.conf
    sed -i 's@^registryServers=.*@registryServers="hdp101:2181,hdp102:2181,hdp103:2181"@' ${conf_dir}/install_config.conf
    sed -i 's@^registryNamespace=.*@registryNamespace="dolphinscheduler"@' ${conf_dir}/install_config.conf
    sed -i 's@^resourceStorageType=.*@resourceStorageType="HDFS"@' ${conf_dir}/install_config.conf
    VERSION_PAT="2.([0-9]).([0-9])"
    if [[ $HADOOP_VERSION_NUM =~ $VERSION_PAT ]]
    then
        sed -i 's@^defaultFS=.*@defaultFS="hdfs://hdp101:9000"@' ${conf_dir}/install_config.conf
    else
        sed -i 's@^defaultFS=.*@defaultFS="hdfs://hdp101:8020"@' ${conf_dir}/install_config.conf
    fi
    sed -i 's@^yarnHaIps=.*@yarnHaIps=@' ${conf_dir}/install_config.conf
    sed -i 's@^hdfsRootUser=.*@hdfsRootUser="atguigu"@' ${conf_dir}/install_config.conf

    # Replace the default configuration
    sed -i "s@hdp101@${HOSTNAME_LIST[0]}@g" `grep 'hdp101' -rl ${conf_dir}/`
    sed -i "s@hdp102@${HOSTNAME_LIST[1]}@g" `grep 'hdp102' -rl ${conf_dir}/`
    sed -i "s@hdp103@${HOSTNAME_LIST[2]}@g" `grep 'hdp103' -rl ${conf_dir}/`


    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

install_dolphinscheduler() {
    local app_name="dolphinscheduler"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        mv ${INSTALL_PATH}/${app_name} ${INSTALL_PATH}/${app_name}-install
        setup_dolphinscheduler ${app_name}
        setupEnv_app $app_name

        source ${PROFILE}
    fi
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_dolphinscheduler
fi
