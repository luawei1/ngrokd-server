#!/bin/bash
# -*- coding: UTF-8 -*-
#############################################
# 作者：KevinCheng
# 环境：Ubuntu18.04 64位
# 1. 配置域名解析
# 2. git clone **.git
# 3. cd *.git && sh ngrokd-ubuntu.sh							#
#############################################
sed -i '$a source /etc/profile' ~/.bashrc
# 获取当前脚本执行路径
SELFPATH=$(
    cd "$(dirname "$0")"
    pwd
)
GOOS=$(go env | grep GOOS | awk -F\" '{print $2}')
GOARCH=$(go env | grep GOARCH | awk -F\" '{print $2}')
# 安装依赖
install_yilai() {
    cd $SELFPATH
    # linux 屏幕管理包
    apt install -y screen
    # 清理openssl缓存
    openssl rand -writerand .rnd
}

# 安装go
install_go() {
    cd $SELFPATH
    # 动态链接库，用于下面的判断条件生效
    ldconfig
    # 判断操作系统位数下载不同的安装包
    if [ $(getconf WORD_BIT) = '32' ] && [ $(getconf LONG_BIT) = '64' ]; then
        # 判断文件是否已经存在
        if [ ! -f $SELFPATH/go1.4.linux-amd64.tar.gz ]; then
            wget https://storage.googleapis.com/golang/go1.4.linux-amd64.tar.gz --no-check-certificate
            wget https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz --no-check-certificate
        fi
        tar -zxf go1.4.linux-amd64.tar.gz
        mv go /root/go1.4
        tar -C /usr/local/ -zxf go1.7.linux-amd64.tar.gz
    else
        # 暂时用不到
        echo "暂时不安装32位的"
    fi
    sed -i '$a export GOROOT=/usr/local/go' /etc/profile
    sed -i '$a export PATH=$GOROOT/bin:$PATH' /etc/profile
}

# 安装ngrok
install_ngrok() {
    cd ngrok-master
    echo '请输入解析的域名'
    read NGROK_DOMAIN
    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=whbaqn.com" -days 5000 -out rootCA.pem
    openssl genrsa -out device.key 2048
    openssl req -new -key device.key -subj "/CN=whbaqn.com" -out device.csr
    openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000
    
    cp rootCA.pem assets/client/tls/ngrokroot.crt
    cp device.crt assets/server/tls/snakeoil.crt
    cp device.key assets/server/tls/snakeoil.key
    # 编译服务端
    make release-server
}

# 编译客户端
compile_client() {
    cd /usr/local/go/src
    GOOS=$1 GOARCH=$2 ./make.bash
    cd $SELFPATH/ngrok
    GOOS=$1 GOARCH=$2 make release-client
}

# 生成客户端
client() {
    echo "1、Linux 32位"
    echo "2、Linux 64位"
    echo "3、Windows 32位"
    echo "4、Windows 64位"
    echo "5、Mac OS 32位"
    echo "6、Mac OS 64位"
    echo "7、Linux ARM"

    read num
    case "$num" in
    [1])
        compile_client linux 386
        ;;
    [2])
        compile_client linux amd64
        ;;
    [3])
        compile_client windows 386
        ;;
    [4])
        compile_client windows amd64
        ;;
    [5])
        compile_client darwin 386
        ;;
    [6])
        compile_client darwin amd64
        ;;
    [7])
        compile_client linux arm
        ;;
    *) echo "选择错误，退出" ;;
    esac

}

echo "请输入下面数字进行选择"
echo "#############################################"
echo "#作者网名：KevinCheng"
echo "#############################################"
echo "------------------------"
echo "1、安装依赖"
echo "2、安装Go"
echo "3、安装Ngrok"
echo "4、生成客户端"
echo "5、启动服务"
echo "------------------------"
read num
case "$num" in
[1])
    install_yilai
    
    ;;
[2])
    install_go
    
    ;;
[3])
    install_ngrok
    ;;
[4])
    client
    ;;
[5])
    echo "输入启动域名"
    read domain
    echo "服务端连接端口"
    read port
    $SELFPATH/ngrok/bin/ngrokd -domain=$domain -tunnelAddr=":$port"
    ;;
*) echo "" ;;
esac
