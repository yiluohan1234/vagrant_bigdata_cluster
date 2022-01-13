#!/bin/bash
#set -x

setup_Kerberos_hadoop_basic_config() {
    local INSTALL_PATH=/opt/module
    local GITEE_RESOURCE_URL_PATH=https://gitee.com/yiluohan1234/vagrant_bigdata_cluster/raw/master/resources
    local conf_dir=${INSTALL_PATH}/hadoop/etc/hadoop
    
    # 重新复制配置文件
    curl -o ${conf_dir}/core-site.xml -LJO ${GITEE_RESOURCE_URL_PATH}/hadoop/core-site.xml
    curl -o ${conf_dir}/hdfs-site.xml -LJO ${GITEE_RESOURCE_URL_PATH}/hadoop/hdfs-site.xml
    curl -o ${conf_dir}/mapred-site.xml -LJO ${GITEE_RESOURCE_URL_PATH}/hadoop/mapred-site.xml
    curl -o ${conf_dir}/yarn-site.xml -LJO ${GITEE_RESOURCE_URL_PATH}/hadoop/yarn-site.xml
    curl -o ${conf_dir}/ssl-server.xml -LJO ${GITEE_RESOURCE_URL_PATH}/hadoop/ssl-server.xml
    sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    if [ "${IS_KERBEROS}" == "true" ];then
        sed -i '31,49s/vagrant/hive/g' ${conf_dir}/core-site.xml
        sed -i '30,34d' ${conf_dir}/core-site.xml
    else
        sed -i '66,99d' ${conf_dir}/core-site.xml
        sed -i '35,111d' ${conf_dir}/hdfs-site.xml
        sed -i '36,46d' ${conf_dir}/mapred-site.xml
        sed -i '73,112d' ${conf_dir}/yarn-site.xml
        rm -rf ${conf_dir}/ssl-server.xml
    fi
  
    # 创建hadoop组、创建各用户并设置密码
    # groupadd hadoop
    # useradd hdfs -g hadoop
    # echo hdfs | passwd --stdin  hdfs
    # useradd yarn -g hadoop
    # echo yarn | passwd --stdin yarn
    # useradd mapred -g hadoop
    # echo mapred | passwd --stdin mapred
    # usermod -a -G hadoop vagrant

    # 创建keytab文件目录
    mkdir /etc/security/keytab/
 
    hostname=`cat /etc/hostname`
    if [ "$hostname" = "hdp101" ];then
        # hdp101
        kadmin -padmin/admin -wadmin -q"addprinc -randkey nn/hdp101"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nn.service.keytab nn/hdp101"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/hdp101"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/hdp101"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/hdp101"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/hdp101"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey jhs/hdp101"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/jhs.service.keytab jhs/hdp101"  
        kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/hdp101"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/hdp101"
        
        kadmin -padmin/admin -wadmin -q"addprinc -pw vagrant vagrant"
    elif [ "$hostname" = "hdp102" ];then
        # hdp102
        kadmin -padmin/admin -wadmin -q"addprinc -randkey rm/hdp102"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/rm.service.keytab rm/hdp102"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/hdp102"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/hdp102"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/hdp102"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/hdp102"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/hdp102"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/hdp102"
    else
        # hdp103
        kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/hdp103"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/hdp103"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey sn/hdp103"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/sn.service.keytab sn/hdp103"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/hdp103"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/hdp103"
        kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/hdp103"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/hdp103"
    fi
    # 配置HDFS使用HTTPS安全传输协议
    keytool -keystore /etc/security/keytab/keystore -alias jetty -genkey -keyalg RSA << EOF
123456
123456






y

EOF
    # 修改所有节点keytab文件的所有者和访问权限
    chown -R root:hadoop /etc/security/keytab/
    chmod 660 /etc/security/keytab/*
    # xsync /etc/security/keytab/keystore

    # 修改$HADOOP_HOME/etc/hadoop/container-executor.cfg
    sed -i 's@^banned.users=.*@banned.users=hdfs,yarn,mapred@' ${INSTALL_PATH}/hadoop/etc/hadoop/container-executor.cfg
    sed -i 's@^yarn.nodemanager.linux-container-executor.group=.*@yarn.nodemanager.linux-container-executor.group=hadoop@' ${INSTALL_PATH}/hadoop/etc/hadoop/container-executor.cfg

    # 修改$HADOOP_HOME/etc/hadoop/yarn-site.xml文件

    # 配置Yarn使用LinuxContainerExecutor
    chown root:hadoop ${INSTALL_PATH}/hadoop/bin/container-executor
    chmod 6050 ${INSTALL_PATH}/hadoop/bin/container-executor
    chown root:hadoop ${INSTALL_PATH}/hadoop/etc/hadoop/container-executor.cfg
    chown root:hadoop ${INSTALL_PATH}/hadoop/etc/hadoop
    chown root:hadoop ${INSTALL_PATH}/hadoop/etc
    chown root:hadoop ${INSTALL_PATH}/hadoop
    chown root:hadoop /opt/module
    chmod 400 ${INSTALL_PATH}/hadoop/etc/hadoop/container-executor.cfg
    
    # 修改本地路径权限
    if [ "$hostname" = "hdp101" ];then
        # 修改本地路径权限:name.dir:hdp101
        chown -R hdfs:hadoop ${INSTALL_PATH}/hadoop/tmp/dfs/name/
        chmod 700 ${INSTALL_PATH}/hadoop/tmp/dfs/name/
    fi
    if [ "$hostname" = "hdp103" ];then
        # namenode.checkpoint:hdp103
        chown -R hdfs:hadoop ${INSTALL_PATH}/hadoop/tmp/dfs/namesecondary/
        chmod 700 ${INSTALL_PATH}/hadoop/tmp/dfs/namesecondary/
    fi
    # logs.dir
    chown hdfs:hadoop ${INSTALL_PATH}/hadoop/logs
    chmod 775 ${INSTALL_PATH}/hadoop/logs
    # data.dir
    chown -R hdfs:hadoop ${INSTALL_PATH}/hadoop/tmp/dfs/data/
    chmod 700 ${INSTALL_PATH}/hadoop/tmp/dfs/data/
    # yarn local-dirs
    chown -R yarn:hadoop ${INSTALL_PATH}/hadoop/tmp/nm-local-dir/
    chmod -R 775 ${INSTALL_PATH}/hadoop/tmp/nm-local-dir/
    # yarn log-dirs
    chown yarn:hadoop ${INSTALL_PATH}/hadoop/logs/userlogs/
    chmod 775 ${INSTALL_PATH}/hadoop/logs/userlogs/

    # $HADOOP_HOME/sbin/start-dfs.sh
    sed -i '17a\HDFS_SECONDARYNAMENODE_USER=hdfs' ${INSTALL_PATH}/hadoop/sbin/start-dfs.sh
    sed -i '17a\HDFS_DATANODE_USER=hdfs' ${INSTALL_PATH}/hadoop/sbin/start-dfs.sh
    sed -i '17a\HDFS_NAMENODE_USER=hdfs' ${INSTALL_PATH}/hadoop/sbin/start-dfs.sh
    # $HADOOP_HOME/sbin/stop-dfs.sh
    sed -i '17a\HDFS_SECONDARYNAMENODE_USER=hdfs' ${INSTALL_PATH}/hadoop/sbin/stop-dfs.sh
    sed -i '17a\HDFS_DATANODE_USER=hdfs' ${INSTALL_PATH}/hadoop/sbin/stop-dfs.sh
    sed -i '17a\HDFS_NAMENODE_USER=hdfs' ${INSTALL_PATH}/hadoop/sbin/stop-dfs.sh

    # $HADOOP_HOME/sbin/start-yarn.sh
    sed -i '17a\YARN_NODEMANAGER_USER=yarn' ${INSTALL_PATH}/hadoop/sbin/start-yarn.sh
    sed -i '17a\YARN_RESOURCEMANAGER_USER=yarn' ${INSTALL_PATH}/hadoop/sbin/start-yarn.sh
    sed -i '17a\YARN_NODEMANAGER_USER=yarn' ${INSTALL_PATH}/hadoop/sbin/stop-yarn.sh
    sed -i '17a\YARN_RESOURCEMANAGER_USER=yarn' ${INSTALL_PATH}/hadoop/sbin/stop-yarn.sh

    # $HADOOP_HOME/bin/mapred
    echo "$hostname"
    sed -i '17a\MAPRED_HISTORYSERVER_USER=mapred' ${INSTALL_PATH}/hadoop/bin/mapred 
}
setup_Kerberos_hadoop(){
    for i in {"hdp101","hdp102","hdp103"};
    do 
        ssh $i "$(typeset -f setup_Kerberos_hadoop_basic_config); setup_Kerberos_hadoop_basic_config"
    done
    # 重启hdp
    for i in {"hdp101","hdp102","hdp103"};
    do
        if [ "$i" = "hdp101" ];then
            ssh $i "sudo -i -u hdfs hdfs --daemon start namenode"
            #ssh $i "sudo -i -u mapred mapred --daemon start historyserver"
        elif [ "$i" = "hdp102" ];then
            ssh $i "sudo -i -u yarn yarn --daemon start resourcemanager"
        else
            ssh $i "sudo -i -u hdfs hdfs --daemon start secondarynamenode"
        fi
        ssh $i "sudo -i -u hdfs hdfs --daemon start datanode"
        ssh $i "sudo -i -u yarn yarn --daemon start nodemanager"
    done
    sleep 6
    #bigstart hdp restart
    # 创建hdfs/hadoop主体(hdp101)
    kadmin.local -q "addprinc hdfs/hadoop" << EOF
hdfs
hdfs
EOF
    echo "hdfs" |kinit hdfs/hadoop 

    hadoop fs -chown hdfs:hadoop / /tmp /user
    hadoop fs -chmod 755 /
    hadoop fs -chmod 1777 /tmp

    hadoop fs -mkdir -p /tmp/logs
    hadoop fs -chown yarn:hadoop /tmp/logs
    hadoop fs -chmod 1777 /tmp/logs

    hadoop fs -chown -R mapred:hadoop /tmp/hadoop-yarn/staging/history/done_intermediate
    hadoop fs -chmod -R 1777 /tmp/hadoop-yarn/staging/history/done_intermediate
    hadoop fs -chown -R mapred:hadoop /tmp/hadoop-yarn/staging/history/done
    hadoop fs -chmod -R 750 /tmp/hadoop-yarn/staging/history/done
    hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/staging/history/
    hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/staging/
    hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/
    hadoop fs -chmod 770 /tmp/hadoop-yarn/staging/history/
    hadoop fs -chmod 770 /tmp/hadoop-yarn/staging/
    hadoop fs -chmod 770 /tmp/hadoop-yarn/

    hadoop fs -mkdir /user/vagrant
    hadoop fs -chown vagrant:hadoop /user/vagrant
}
setup_Kerberos_hive() {
    # 创建系统用户
    # useradd hive -g hadoop
    # echo hive | passwd --stdin hive
    if [ "$hostname" = "hdp101" ];then
        # 创建hive kerberos主体
        kadmin -padmin/admin -wadmin -q"addprinc -randkey hive/hdp101"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/hive.service.keytab hive/hdp101"
        chown -R root:hadoop /etc/security/keytab/
        chmod 660 /etc/security/keytab/hive.service.keytab
    fi
    local app_name="hive"
    local app_name_upper=`get_string_upper ${app_name}`
    local res_dir=$(eval echo \$${app_name_upper}_RES_DIR)
    local conf_dir=$(eval echo \$${app_name_upper}_CONF_DIR)
	
    log info "copying over ${app_name} configuration files"
    cp -f ${res_dir}/hive* ${conf_dir}

}
setup_Kerberos_hadoop