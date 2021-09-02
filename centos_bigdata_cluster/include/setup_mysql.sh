#!/bin/bash

add_mysql_group(){
    local app_name=$1
    log info "add group $app_name"
    su - root<<EOF
    # 卸载系统自带的Mariadb
    rpm -e --nodeps mariadb-libs
    # libaio安装
    yum install -y libaio
    # 添加mysql用户组
    groupadd mysql
    useradd -g mysql mysql -d /home/mysql
    # 修改mysql用户的登陆密码（mysql/mysql）
    echo "cyf@123456" |passwd mysql --stdin
EOF
}

download_mysql() {
    local app_name=$1
    log info "install $app_name"
    if resourceExists $MYSQL_ARCHIVE; then
        installFromLocal $MYSQL_ARCHIVE
    else
        installFromRemote $MYSQL_ARCHIVE $MYSQL_MIRROR_DOWNLOAD
    fi
    mv ${INSTALL_PATH}/${MYSQL_VERSION}-linux-glibc2.12-x86_64 ${INSTALL_PATH}/mysql
    sudo mv ${INSTALL_PATH}/mysql /usr/local/
}

setup_mysql(){
    # 创建临时目录、数据目录和日志目录
    mkdir -p /home/mysql/3306/data
    mkdir -p /home/mysql/3306/log
    mkdir -p /home/mysql/3306/tmp
    # 更改所属的组和用户
    chown -R mysql:mysql /home/mysql/

    cat $MYSQL_RESDIR/my.cnf >> /etc/my.cnf
    # 初始化数据库，并指定启动mysql的用户
    ./usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/home/mysql/3306/data
    echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
    # 复制启动脚本到资源目录
    cp /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysqld
    # 增加mysqld服务控制脚本执行权限
    chmod +x /etc/rc.d/init.d/mysqld
    # 将mysqld服务加入到系统服务
    chkconfig --add mysqld
    service mysqld start
}
change_password(){
    pass=`grep password /home/mysql/3306/log/error.log |sed -n '1p;1q'`
    new_pass="123456"
    mysql -uroot -p${pass} -e "set password for root@localhost=password($new_pass);exit;"

}
install_mysql() {
    local app_name="mysql"
    log info "setup $app_name"
    add_mysql_group $app_name
    #download_mysql $app_name
    #setupEnv_app $app_name

    #source $PROFILE
}
