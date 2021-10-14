#!/bin/bash
#set -x

if [ "${IS_VAGRANT}" == "true" ];then
    source "/vagrant/scripts/common.sh"
else
    source "/home/vagrant/scripts/common.sh"
fi

setup_mysql() {
    local app_name=$1
    local mysql_install_dir=/usr/local/mysql
    local mysql_data_dir=/data/mysql
    local dbrootpwd="199037"

    # 安装依赖
    yum install -y libaio
    log info "install ${app_name}"
    log info "初始化：建立install_dir、data_dir和用户群组"
    id -u mysql >/dev/null 2>&1
    [ $? -ne 0 ] && useradd -M -s /sbin/nologin mysql
    [ ! -d "${mysql_install_dir}" ] && mkdir -p ${mysql_install_dir}
    mkdir -p ${mysql_data_dir};chown mysql.mysql -R ${mysql_data_dir}

    log info "下载解压mysql"
    if resourceExists ${MYSQL_ARCHIVE}; then
        tar -xzf ${DOWNLOAD_PATH}/${MYSQL_ARCHIVE} -C ${DOWNLOAD_PATH}
    else
        curl -o ${DOWNLOAD_PATH}/${MYSQL_ARCHIVE} -O -L $MYSQL_MIRROR_DOWNLOAD
        tar -xzf ${DOWNLOAD_PATH}/${MYSQL_ARCHIVE} -C ${DOWNLOAD_PATH}
    fi
    mv ${DOWNLOAD_PATH}/${MYSQL_VERSION}-linux-glibc2.12-x86_64/* ${mysql_install_dir}
    rm -rf ${DOWNLOAD_PATH}/${MYSQL_ARCHIVE}*

    log info "拷贝配置文件my.cnf"
    cp ${MYSQL_RES_DIR}/my.cnf /etc/

    #sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/local/lib/libjemalloc.so@' ${mysql_install_dir}/bin/mysqld_safe
    #sed -i "s@/usr/local/mysql@${mysql_install_dir}@g" ${mysql_install_dir}/bin/mysqld_safe
    
    log info "配置启动文件"
    cp ${mysql_install_dir}/support-files/mysql.server /etc/init.d/mysqld
    sed -i "s@^basedir=.*@basedir=${mysql_install_dir}@" /etc/init.d/mysqld
    sed -i "s@^datadir=.*@datadir=${mysql_data_dir}@" /etc/init.d/mysqld
    chmod +x /etc/init.d/mysqld
    chkconfig --add mysqld; chkconfig mysqld on;
    
    log info "配置环境变量/etc/profile"
    [ -z "$(grep ^'export PATH=' /etc/profile)" ] && echo "export PATH=${mysql_install_dir}/bin:\$PATH" >> /etc/profile
    [ -n "$(grep ^'export PATH=' /etc/profile)" -a -z "$(grep ${mysql_install_dir} /etc/profile)" ] && sed -i "s@^export PATH=\(.*\)@export PATH=${mysql_install_dir}/bin:\1@" /etc/profile
    . /etc/profile

    log info "初始化数据库"
    ${mysql_install_dir}/bin/mysqld --initialize-insecure --user=mysql --basedir=${mysql_install_dir} --datadir=${mysql_data_dir}
    service mysqld start
    
    ${mysql_install_dir}/bin/mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"${dbrootpwd}\" with grant option;"
    ${mysql_install_dir}/bin/mysql -e "grant all privileges on *.* to root@'localhost' identified by \"${dbrootpwd}\" with grant option;"

    log info "创建hive的元数据库"
    ${mysql_install_dir}/bin/mysql -uroot -p${dbrootpwd} -e "create user 'hive'@'%' IDENTIFIED BY 'hive';GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' WITH GRANT OPTION;grant all on *.* to 'hive'@'localhost' identified by 'hive';flush privileges;"

    # 进行远程访问授权
    ${mysql_install_dir}/bin/mysql -uroot -p${dbrootpwd} -e "use mysql; update user set authentication_string=password(\"${dbrootpwd}\") where user='root'; update user set authentication_string=password(\"${dbrootpwd}\"),plugin='mysql_native_password' where user='root';grant all on *.* to root@'%' identified by \"${dbrootpwd}\" with grant option;grant all privileges on *.* to 'root'@'%' identified by \"${dbrootpwd}\" with grant option;flush privileges;"
    
    # canal数据库用户名和密码赋权
    ${mysql_install_dir}/bin/mysql -uroot -p${dbrootpwd} -e "GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%' IDENTIFIED BY 'canal';flush privileges;"
    
    # 在数据库中建立一个maxwell 库用于存储 Maxwell的元数据
    ${mysql_install_dir}/bin/mysql -uroot -p${dbrootpwd} -e "CREATE DATABASE maxwell;GRANT ALL ON maxwell.* TO 'maxwell'@'%' IDENTIFIED BY 'maxwell';GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO maxwell@'%';flush privileges;"
    
    
    service mysqld stop
}


install_mysql() {
    local app_name="mysql"
    log info "setup ${app_name}"
    setup_mysql ${app_name}
}


if [ "${IS_VAGRANT}" == "true" ];then
    install_mysql
fi

