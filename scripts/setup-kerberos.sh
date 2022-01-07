#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi


setup_Kerberos() {
    # 修改/etc/krb5.conf文件
    sed -i '10 a dns_lookup_kdc = false' /etc/krb5.conf
    sed -i 's/^dns_lookup_kdc =.*/ dns_lookup_kdc = false/g' /etc/krb5.conf
    sed -i 's/^# default_realm =.*/ default_realm = EXAMPLE.COM/g' /etc/krb5.conf
    sed -i 's/^ default_ccache_name.*/ #default_ccache_name = KEYRING:persistent:%{uid}/g' /etc/krb5.conf
    sed -i 's/^# EXAMPLE.COM.*/ EXAMPLE.COM = {/g' /etc/krb5.conf
    sed -i 's/^#  admin_server =.*/  admin_server = hdp101/g' /etc/krb5.conf
    sed -i 's/^#  kdc =.*/  kdc = hdp101/g' /etc/krb5.conf
    sed -i 's/^# }.*/ }/g' /etc/krb5.conf
    if [ "$hostname" = "hdp101" ];then
        # 管理员主体认证:kinit admin/admin(hdp101)
        kdb5_util create -s << EOF
admin
admin
EOF
        # 启动KDC和Kadmin
        systemctl start krb5kdc
        systemctl enable krb5kdc
        systemctl start kadmin
        systemctl enable kadmin
        kadmin.local -q "addprinc admin/admin" <<EOF
admin
admin
EOF
    fi
}
setup_Kerberos_hadoop() {

    # 创建hadoop组、创建各用户并设置密码
    groupadd hadoop
    useradd hdfs -g hadoop
    echo hdfs | passwd --stdin  hdfs
    useradd yarn -g hadoop
    echo yarn | passwd --stdin yarn
    useradd mapred -g hadoop
    echo mapred | passwd --stdin mapred

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
    # 修改Hadoop配置文件

    # 配置HDFS使用HTTPS安全传输协议
    keytool -keystore /etc/security/keytab/keystore -alias jetty -genkey -keyalg RSA << EOF
123456
123456






y

EOF
    # 修改所有节点keytab文件的所有者和访问权限
    chown -R root:hadoop /etc/security/keytab/
    chmod 660 /etc/security/keytab/*
    xsync /etc/security/keytab/keystore
    
    # 修改hadoop配置文件ssl-server.xml.example
    mv $HADOOP_HOME/etc/hadoop/ssl-server.xml.example $HADOOP_HOME/etc/hadoop/ssl-server.xml

    # 修改$HADOOP_HOME/etc/hadoop/container-executor.cfg
    # 修改$HADOOP_HOME/etc/hadoop/yarn-site.xml文件

    # 配置Yarn使用LinuxContainerExecutor
    chown root:hadoop ${HADOOP_HOME}/bin/container-executor
    chmod 6050 ${HADOOP_HOME}/bin/container-executor
    chown root:hadoop ${HADOOP_HOME}/etc/hadoop/container-executor.cfg
    chown root:hadoop ${HADOOP_HOME}/etc/hadoop
    chown root:hadoop ${HADOOP_HOME}/etc
    chown root:hadoop ${HADOOP_HOME}
    chown root:hadoop /opt/module
    chmod 400 ${HADOOP_HOME}/etc/hadoop/container-executor.cfg
    
    # 修改本地路径权限
    if [ "$hostname" = "hdp101" ];then
        # name.dir:hdp101
        chown -R hdfs:hadoop ${HADOOP_HOME}/tmp/dfs/name/
        chmod 700 ${HADOOP_HOME}/tmp/dfs/name/
    fi
    if [ "$hostname" = "hdp103" ];then
        # namenode.checkpoint:hdp103
        chown -R hdfs:hadoop ${HADOOP_HOME}/tmp/dfs/namesecondary/
        chmod 700 ${HADOOP_HOME}/tmp/dfs/namesecondary/
    fi
    # logs.dir
    chown hdfs:hadoop ${HADOOP_HOME}/logs
    chmod 775 ${HADOOP_HOME}/logs
    # data.dir
    chown -R hdfs:hadoop ${HADOOP_HOME}/tmp/dfs/data/
    chmod 700 ${HADOOP_HOME}/tmp/dfs/data/
    # yarn local-dirs
    chown -R yarn:hadoop ${HADOOP_HOME}/tmp/nm-local-dir/
    chmod -R 775 ${HADOOP_HOME}/tmp/nm-local-dir/
    # yarn log-dirs
    chown yarn:hadoop ${HADOOP_HOME}/logs/userlogs/
    chmod 775 ${HADOOP_HOME}/logs/userlogs/

    # $HADOOP_HOME/sbin/start-dfs.sh
    sed -i '17a\HDFS_SECONDARYNAMENODE_USER=hdfs' ${HADOOP_HOME}/sbin/start-dfs.sh
    sed -i '17a\HDFS_DATANODE_USER=hdfs' ${HADOOP_HOME}/sbin/start-dfs.sh
    sed -i '17a\HDFS_NAMENODE_USER=hdfs' ${HADOOP_HOME}/sbin/start-dfs.sh
    # $HADOOP_HOME/sbin/stop-dfs.sh
    sed -i '17a\HDFS_SECONDARYNAMENODE_USER=hdfs' ${HADOOP_HOME}/sbin/stop-dfs.sh
    sed -i '17a\HDFS_DATANODE_USER=hdfs' ${HADOOP_HOME}/sbin/stop-dfs.sh
    sed -i '17a\HDFS_NAMENODE_USER=hdfs' ${HADOOP_HOME}/sbin/stop-dfs.sh

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

    # $HADOOP_HOME/sbin/start-yarn.sh
    sed -i '17a\YARN_NODEMANAGER_USER=yarn' ${HADOOP_HOME}/sbin/start-yarn.sh
    sed -i '17a\YARN_RESOURCEMANAGER_USER=yarn' ${HADOOP_HOME}/sbin/start-yarn.sh
    sed -i '17a\YARN_NODEMANAGER_USER=yarn' ${HADOOP_HOME}/sbin/stop-yarn.sh
    sed -i '17a\YARN_RESOURCEMANAGER_USER=yarn' ${HADOOP_HOME}/sbin/stop-yarn.sh

    # $HADOOP_HOME/bin/mapred
    sed -i '17a\MAPRED_HISTORYSERVER_USER=mapred' ${HADOOP_HOME}/bin/mapred


    usermod -a -G hadoop vagrant
    kadmin -p admin/admin -wadmin -q"addprinc -pw vagrant vagrant"
}
setup_Kerberos_hive(){
    useradd hive -g hadoop
    echo hive | passwd --stdin hive
    if [ "$hostname" = "hdp101" ];then
        kadmin -padmin/admin -wadmin -q"addprinc -randkey hive/hdp101"
        kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/hive.service.keytab hive/hdp101"
        chown -R root:hadoop /etc/security/keytab/
        chmod 660 /etc/security/keytab/hive.service.keytab

        cp ${HADOOP_HOME}/etc/hadoop/core-site.xml ${HIVE_HOME}/conf
        cp ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml ${HIVE_HOME}/conf
    fi

}
download_Kerberos() {
    local app_name=$1
    yum install -y krb5-workstation krb5-libs

    hostname=`cat /etc/hostname`
    if [ "$hostname" = "hdp101" ];then
        yum install -y krb5-server 
    fi
}

dispatch_Kerberos() {
    local app_name=$1
    dispatch_app ${app_name}
    for i in {"hdp101","hdp102","hdp103"};
    do
        node_name=$i
        node_host=`cat /etc/hosts |grep $i|awk '{print $1}'`
        file_path=${INSTALL_PATH}/${app_name}/config/elasticsearch.yml

        echo "------modify $i server.properties-------"
        #ssh $i "sed -i 's/^node.name: .*/node.name: '$node_name'/' $file_path"
        ssh $i "sed -i 's@^network.host: .*@network.host: '${node_host}'@' ${file_path}"
    done
}

install_Kerberos() {
    local app_name="Kerberos"
    log info "setup ${app_name}"

    download_Kerberos ${app_name}
    setup_Kerberos ${app_name}
    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_Kerberos ${app_name}
    fi
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_Kerberos
fi
