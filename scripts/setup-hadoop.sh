#!/bin/bash
#set -x

# https://hadoop.apache.org/docs/r2.4.1/hadoop-yarn/hadoop-yarn-common/yarn-default.xml

source "/vagrant/scripts/common.sh"

setupHadoop() {
    log info "creating hadoop directories"
    mkdir -p ${INSTALL_PATH}/hadoop/tmp
    mkdir -p ${INSTALL_PATH}/hadoop/data/data
    mkdir -p ${INSTALL_PATH}/hadoop/data/data
	
    log info "copying over hadoop configuration files"
    cp -f $HADOOP_RES_DIR/* $HADOOP_CONF_DIR
}

setupEnvVars() {
    echo "creating hadoop environment variables"
    hadoop_path=${INSTALL_PATH}/hadoop
    echo "# hadoop environment" >> $PROFILE
    echo "export HADOOP_HOME=$hadoop_path" >> $PROFILE
    echo 'export PATH=${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:$PATH' >> $PROFILE
    echo -e "\n" >> $PROFILE
    
}

installHadoop() {
    log info "install hadoop"
    if resourceExists $HADOOP_ARCHIVE; then
        installFromLocal $HADOOP_ARCHIVE
    else
        installFromRemote $HADOOP_ARCHIVE $HADOOP_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/$HADOOP_VERSION ${INSTALL_PATH}/hadoop
}

formatHdfs() {
    log info "formatting HDFS"
    hdfs namenode -format
}

startDaemons() {
    log info "starting Hadoop daemons"
    $HADOOP_PREFIX/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode
    $HADOOP_PREFIX/sbin/hadoop-daemons.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
    $HADOOP_PREFIX/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start resourcemanager
    $HADOOP_PREFIX/sbin/yarn-daemons.sh --config $HADOOP_CONF_DIR start nodemanager
    $HADOOP_PREFIX/sbin/yarn-daemon.sh start proxyserver --config $HADOOP_CONF_DIR
    $HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver --config $HADOOP_CONF_DIR

    log info "waiting for HDFS to come up"
    # loop until at least HDFS is up
    cmd="hdfs dfs -ls /"
    NEXT_WAIT_TIME=0
    up=0
    while [  $NEXT_WAIT_TIME -ne 4 ] ; do
        $cmd
        rc=$?
        if [[ $rc == 0 ]]; then
            up=1
            break
        fi
       sleep $(( NEXT_WAIT_TIME++ ))
    done

    if [[ $up != 1 ]]; then
        log info "HDFS doesn't seem to be up; exiting"
        exit $rc
    fi

    log info "listing all Java processes"
    jps
}

setupHdfs() {
    log info "creating user home directory in hdfs"
    hdfs dfs -mkdir -p /user/root
    hdfs dfs -mkdir -p /user/vagrant
    hdfs dfs -chown vagrant /user/vagrant

    log info "creating temp directories in hdfs"
    hdfs dfs -mkdir -p /tmp
    hdfs dfs -chmod -R 777 /tmp

    hdfs dfs -mkdir -p /var
    hdfs dfs -chmod -R 777 /var
}
log info "setup hadoop"

installHadoop
setupHadoop
setupEnvVars
source $PROFILE
#formatHdfs
#startDaemons
#setupHdfs

