#!/bin/bash
#set -x

if [ "$IS_VAGRANT" == "true" ];then
    source "/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
else
    source "/home/vagrant/vagrant_bigdata_cluster/scripts/common.sh"
fi


setup_Kerberos() {
    # 创建hadoop组
    groupadd hadoop
    # 创建各用户并设置密码
    useradd hdfs -g hadoop
    echo hdfs | passwd --stdin  hdfs
    useradd yarn -g hadoop
    echo yarn | passwd --stdin yarn
    useradd mapred -g hadoop
    echo mapred | passwd --stdin mapred

    # 创建keytab文件目录
    mkdir /etc/security/keytab/
    chown -R root:hadoop /etc/security/keytab/
    chmod 770 /etc/security/keytab/
    # 管理员主体认证:kinit admin/admin
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
    # hdp102
    kadmin -padmin/admin -wadmin -q"addprinc -randkey rm/hdp102"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/rm.service.keytab rm/hdp102"
    kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/hdp102"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/hdp102"
    kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/hdp102"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/hdp102"
    kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/hdp102"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/hdp102"
    # hdp103
    kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/hdp103"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/hdp103"
    kadmin -padmin/admin -wadmin -q"addprinc -randkey sn/hdp103"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/sn.service.keytab sn/hdp103"
    kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/hdp103"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/hdp103"
    kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/hdp103"
    kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/hdp103"
    # 修改所有节点keytab文件的所有者和访问权限
    chown -R root:hadoop /etc/security/keytab/
    chmod 660 /etc/security/keytab/*
    # 修改Hadoop配置文件
    keytool -keystore /etc/security/keytab/keystore -alias jetty -genkey -keyalg RSA
    chown -R root:hadoop /etc/security/keytab/keystore
    chmod 660 /etc/security/keytab/keystore
    xsync /etc/security/keytab/keystore
    
    # 修改hadoop配置文件ssl-server.xml.example
    mv $HADOOP_HOME/etc/hadoop/ssl-server.xml.example $HADOOP_HOME/etc/hadoop/ssl-server.xml

    # 配置HDFS使用HTTPS安全传输协议

    
    if [ ${INSTALL_PATH} != /home/vagrant/apps ];then
        sed -i "s@/home/vagrant/apps@${INSTALL_PATH}@g" `grep '/home/vagrant/apps' -rl ${conf_dir}/`
    fi
}

download_Kerberos() {
    local app_name=$1
    yum install -y krb5-workstation krb5-libs

    hostname=`cat /etc/hostname`
    if [ "$hostname" != "hdp101" ];then
        yum install -y krb5-server 
    fi
}

dispatch_Kerberos() {
    local app_name=$1
    dispatch_app ${app_name}
    for i in {"hdp102","hdp103"};
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
    setupEnv_app $app_name
    if [ "${IS_VAGRANT}" != "true" ];then
        dispatch_Kerberos ${app_name}
    fi
    source ${PROFILE}
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_Kerberos
fi
