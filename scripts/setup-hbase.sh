#!/bin/bash
#set -x
if [ -d /vagrant/scripts ];then
    source "/vagrant/scripts/common.sh"
fi

setup_hbase() {
    local app_name=$1
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)

    log info "modifying over ${app_name} configuration files"
    # cp -f ${res_dir}/* ${conf_dir}
    # hbase-env.sh
    sed -i "s@^# export HBASE_MANAGES_ZK=.*@export HBASE_MANAGES_ZK=false@" ${conf_dir}/hbase-env.sh
    sed -i "s@^# export JAVA_HOME=.*@export JAVA_HOME=${INSTALL_PATH}/java@" ${conf_dir}/hbase-env.sh
    # sed -i "s@^# export HBASE_CLASSPATH=.*@export HBASE_CLASSPATH=${INSTALL_PATH}/hadoop/@" ${conf_dir}/hbase-env.sh
    # 启动报错：PermSize 和 MaxPermSize 的限制,HBase默认这两个参数有128M的限制，由于长期使用导致程序超过了该阈值
    sed -i '/export HBASE_MASTER_OPTS="$HBASE_MASTER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m -XX:ReservedCodeCacheSize=256m"/s/^/#/g' ${conf_dir}/hbase-env.sh
    sed -i '/export HBASE_REGIONSERVER_OPTS="$HBASE_REGIONSERVER_OPTS -XX:PermSize=128m -XX:MaxPermSize=128m -XX:ReservedCodeCacheSize=256m"/s/^/#/g' ${conf_dir}/hbase-env.sh
    
    # hbase-site.xml
    create_property_xml ${res_dir}/hbase-site.properties ${conf_dir}/hbase-site.xml

    # regionservers 和 backup-masters
    sed -i '1,$d' ${conf_dir}/regionservers 
    echo -e "${HOSTNAME_LIST[0]}\n${HOSTNAME_LIST[1]}\n${HOSTNAME_LIST[2]}" >> ${conf_dir}/regionservers
    # echo "${HOSTNAME_LIST[1]}" >> ${conf_dir}/backup-masters

    cp ${INSTALL_PATH}/hadoop/etc/hadoop/core-site.xml ${INSTALL_PATH}/hbase/conf/
    cp ${INSTALL_PATH}/hadoop/etc/hadoop/hdfs-site.xml ${INSTALL_PATH}/hbase/conf
    mv ${INSTALL_PATH}/hbase/lib/slf4j-log4j12-1.7.25.jar ${INSTALL_PATH}/hbase/lib/slf4j-log4j12-1.7.25.jar_bak
    
    # 更换默认配置
    sed -i "s@hdp101@${HOSTNAME_LIST[0]}@g" `grep 'hdp101' -rl ${conf_dir}/`
    sed -i "s@hdp102@${HOSTNAME_LIST[1]}@g" `grep 'hdp102' -rl ${conf_dir}/`
    sed -i "s@hdp103@${HOSTNAME_LIST[2]}@g" `grep 'hdp103' -rl ${conf_dir}/`

    if [ $INSTALL_PATH != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

install_hbase() {
    local app_name="hbase"
    if [ ! -d ${INSTALL_PATH}/${app_name} ];then
        log info "setup ${app_name}"
        download_and_unzip_app ${app_name}
        setup_hbase ${app_name}
        setupEnv_app ${app_name}

        if [ "${IS_VAGRANT}" != "true" ];then
            dispatch_app ${app_name}
        fi
        
        source ${PROFILE}
    fi
}

if [ "${IS_VAGRANT}" == "true" ];then
    install_hbase
fi
