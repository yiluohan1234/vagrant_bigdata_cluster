#!/bin/bash
#set -x

setup_flume() {
    local app_name=$1

    log info "copying over $app_name configuration files"
    cp -f $FLUME_RES_DIR/flume-env.sh $FLUME_CONF_DIR
    cp ${INSTALL_PATH}/flume/conf/flume-conf.properties.template ${INSTALL_PATH}/flume/conf/flume-conf.properties
}

download_flume() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $FLUME_ARCHIVE; then
        installFromLocal $FLUME_ARCHIVE
    else
        installFromRemote $FLUME_ARCHIVE $FLUME_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/"${FLUME_VERSION}" ${INSTALL_PATH}/flume
}

install_flume() {
    log info "setup flume"
    app_name="flume"

    #download_flume $app_name
    #setup_flume $app_name
    #setupEnv_app $app_name
    dispatch_app $app_name
    source $PROFILE
}

