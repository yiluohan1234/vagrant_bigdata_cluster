#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_es() {
    local app_name=$1
    log info "copying over $app_name configuration files"
    mkdir -p $INSTALL_PATH/elasticsearch/datas
    mkdir -p $INSTALL_PATH/elasticsearch/logs
    cp -f $ES_RES_DIR/* $ES_CONF_DIR
    if [ "$IS_VAGRANT" == "true" ];then
        hostname=`cat /etc/hostname`
        node_host=`cat /etc/hosts |grep $hostname|awk '{print $1}'`
        file_path=$INSTALL_PATH/$app_name/config/elasticsearch.yml
        
        echo "------modify $i server.properties-------"
        #sed -i 's/^node.name: .*/node.name: '$hostname'/' $file_path
        sed -i 's@^network.host: .*@network.host: '$node_host'@' $file_path
    fi
}

download_es() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $ES_ARCHIVE; then
        installFromLocal $ES_ARCHIVE
    else
        installFromRemote $ES_ARCHIVE $ES_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/${ES_VERSION} ${INSTALL_PATH}/$app_name
    sudo chown -R vagrant:vagrant $INSTALL_PATH/$app_name
    rm $DOWNLOAD_PATH/$ES_ARCHIVE
}

dispatch_es() {
    local app_name=$1
    dispatch_app $app_name
    for i in {"hdp102","hdp103"};
    do
        node_name=$i
        node_host=`cat /etc/hosts |grep $i|awk '{print $1}'`
        file_path=$INSTALL_PATH/$app_name/config/elasticsearch.yml

        echo "------modify $i server.properties-------"
        #ssh $i "sed -i 's/^node.name: .*/node.name: '$node_name'/' $file_path"
        ssh $i "sed -i 's@^network.host: .*@network.host: '$node_host'@' $file_path"
    done
}

install_es() {
    local app_name="elasticsearch"
    log info "setup $app_name"

    download_es $app_name
    setup_es $app_name
    setupEnv_app $app_name
    #dispatch_app $app_name
    if [ "$IS_VAGRANT" != "true" ];then
        dispatch_es $app_name
    fi
    source $PROFILE
}

if [ "$IS_VAGRANT" == "true" ];then
    install_es
fi
