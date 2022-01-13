#!/bin/bash
#set -x
source "/vagrant/scripts/common.sh"

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

download_Kerberos() {
    local app_name=$1
    log info "install kerberos"
    yum install -y krb5-workstation krb5-libs

    hostname=`cat /etc/hostname`
    if [ "$hostname" = "hdp101" ];then
        yum install -y krb5-server 
    fi
}

install_Kerberos() {
    local app_name="Kerberos"
    log info "setup ${app_name}"
    download_Kerberos ${app_name}
    setup_Kerberos ${app_name}
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_Kerberos
fi
