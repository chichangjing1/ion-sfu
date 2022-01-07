#!/bin/bash

# 台州
################ Version Info ##################
# Create Date: 2021-05-12
# Revision Date: 2021-05-12 17:14:38
# Author:      chichangjing
# Mail:        0609ccj@163.com
# Version:     1.0
# Attention:   shell脚本模板
################################################

# 密码提示
PASSWORD_PROMPT=""

DATE=$(date +%Y%m%d)

# 用户名, ip, port 后期添加新的地址可以到config_target()接口里添加
USER=""
IPADDR=""
SSH_FLAG=""
SCP_FLAG=""
PORT=""
# 可执行文件名
BIN="ion-sfu"
#BIN="ion-sfu"
# 传送的子目录
SUB_DIR=${BIN}

# 日志目录
LOG_DIR=log

# 重定向日志文件
LOG_FILE="./mytest.log"
#exec 2>>${LOG_FILE}
#set -x

# 设置日志级别
loglevel=0
debug=0
info=1
warn=2
error=3

getdate()
{
    local curtime=`date "+%Y-%m-%d %H:%M:%S.%N"`
    echo $curtime
    return 0
}

log()
{
    local curtime=$(getdate)
    #echo "$curtime $*">> ${LOG_FILE}
    printf "[$curtime] $*\n"
}

# 调试日志
logDebug()
{
    local curtime=$(getdate)
    if [ $loglevel -le $debug ];then
        #echo "$curtime $*">> ${LOG_FILE}
        printf "[$curtime][debug] $*\n"
    fi
}

# 信息日志
logInfo()
{
    local curtime=$(getdate)
    if [ $loglevel -le $info ];then
        #echo "$curtime $*">> ${LOG_FILE}
        printf "\033[32m[$curtime][info] $*\033[0m\n"
    fi
}

# 告警日志
logWarn()
{
    local curtime=$(getdate)
    if [ $loglevel -le $warn ];then
        #echo "$curtime $*">> ${LOG_FILE}
        printf "\033[33m[$curtime][warn] $*\033[0m\n"
    fi
}

# 错误日志
logErr()
{
    local curtime=$(getdate)
    if [ $loglevel -le $error ];then
        #echo "$curtime $*">> ${LOG_FILE}
        printf "\033[31m[$curtime][err] $*\033[0m\n"
    fi
}

# 命令用法
usage() 
{
    echo "====================USAGE: $0 modules===================="
    echo "scp [file] [server]           -scp copy file to server"
    echo "help                          -print usage"
    echo "ssh [server]                  -ssh login"
    echo "build [target]                -go build to [linux | mac | windows]"
    echo "packed [tar.gz]               -packed bin to [tar.gz | tar.bz2]"
    echo "run [app] [config]            -run app with config file"
    echo "kill [app]                    -kill app"
    echo "mkcert                        -make cert"
    echo "<<<<<<<<<<<< Note: >>>>>>>>>>>>"
    echo "[server]:     [taizhou | lvcheng]"
    echo "[app]   :     [ehome-srv | iot-rtc | ion-sfu]"
    echo "[config]:     [config.json | config.toml]"
    echo "[target]:     [linux | mac | windows]"
}

# 输入参数检测,参数$1:实际参数个数 参数$2：理论参数个数
checkarg()
{
    if (( $1 != $2 ));then
        return 1
    fi
    return 0
}

# 全局配置
config_target()
{
    local server_target=$1

    # 台州:taizhou 律橙:lvcheng
    if [ "$server_target" == "taizhou" ];then
        # 密码提示
        PASSWORD_PROMPT="please input password:pass123456"
        # 用户名, ip, port
        USER=chi_changjing
        IPADDR=10.10.14.3
        SSH_FLAG=-p
        SCP_FLAG=-P
        PORT=22
    
    elif [ "$server_target" == "lvcheng" ];then
        # 密码提示
        PASSWORD_PROMPT="please input password:pass123456"
        # 用户名, ip, port
        USER=chi_changjing
        IPADDR=47.97.220.200
        SSH_FLAG=""
        SCP_FLAG=""
        PORT=""
    else
        logErr "[$0:${LINENO}]=>" "$server_target server target unknow"
        exit 0
    fi
}

# 登陆
ssh_login()
{
    checkarg "$#" "2"
    if [ $? == 1 ];then
        logErr "[$0:${LINENO}]=>" "invalid parameter"
        exit 0
    fi
    local server_target=$2
    config_target $server_target
    log "[$0:${LINENO}]=>" "ssh ${USER}@${IPADDR} ${SSH_FLAG} ${PORT}"
    log "[$0:${LINENO}]=>" "${PASSWORD_PROMPT}"
    ssh ${USER}@${IPADDR} ${SSH_FLAG} ${PORT}
}

# 发布到服务器
pack_scp()
{
    checkarg "$#" "3"
    if [ $? == 1 ];then
        logErr "[$0:${LINENO}]=>" "invalid parameter"
        exit 0
    fi

    local server_target=$3
    config_target $server_target
    log "[$0:${LINENO}]=>" "${PASSWORD_PROMPT}"
    ssh ${USER}@${IPADDR} ${SSH_FLAG} ${PORT} "[ -d ~/${SUB_DIR} ] && echo ok || mkdir -p ~/${SUB_DIR}"
    log "[$0:${LINENO}]=>" "scp ${SCP_FLAG} ${PORT} -r $2 ${USER}@${IPADDR}:~/${SUB_DIR}"
    log "[$0:${LINENO}]=>" "${PASSWORD_PROMPT}"
    scp ${SCP_FLAG} ${PORT} -r $2 ${USER}@${IPADDR}:~/${SUB_DIR}
}

# 编译go工程
gobuild()
{
    local goos=$2

    checkarg "$#" "2"
    if [ $? == 1 ];then
        logErr "[$0:${LINENO}]=>" "invalid parameter"
        exit 0
    fi

    local cgo_enabled=0
    local main_app=main.go
    # ehome-srv用到cgo和linux动态库，只能在linux下编译
    if [ $BIN == ehome-srv ];then
        cgo_enabled=1
        if [ $goos != linux ];then
            logErr "[$0:${LINENO}]=>" "$BIN only support linux build"
            return 0
        fi
    fi

    if [ $BIN == ion-sfu ];then
        main_app=./cmd/signal/allrpc/main.go
    fi

    if [ $goos == linux ];then
        logInfo "[$0:${LINENO}]=>" "CGO_ENABLED=$cgo_enabled GOOS=linux GOARCH=amd64 go build -o $BIN ${main_app}"
        CGO_ENABLED=$cgo_enabled GOOS=linux GOARCH=amd64 go build -o $BIN ${main_app}
    elif [ $goos == mac ];then
        logInfo "[$0:${LINENO}]=>" "CGO_ENABLED=$cgo_enabled GOOS=darwin GOARCH=amd64 go build -o $BIN ${main_app}"
        CGO_ENABLED=$cgo_enabled GOOS=darwin GOARCH=amd64 go build -o $BIN ${main_app}
    elif [ $goos == windows ];then
        logInfo "[$0:${LINENO}]=>" "CGO_ENABLED=$cgo_enabled GOOS=windows GOARCH=amd64 go build -o $BIN ${main_app}"
        CGO_ENABLED=$cgo_enabled GOOS=windows GOARCH=amd64 go build -o $BIN ${main_app}
    else
        logErr "[$0:${LINENO}]=>" "Invalid parameter"
    fi

    if [ $? != 0 ]; then
        logErr "[$0:${LINENO}]=>" "Golang build run error"
    fi
}

# 打包可执行文件
packedbin()
{
    checkarg "$#" "2"
    if [ $? == 1 ];then
        logErr "[$0:${LINENO}]=>" "invalid parameter"
        exit 0
    fi

    if [ $2 == tar.gz ];then
        logInfo "[$0:${LINENO}]=>" "tar -czf ${BIN}.tar.gz ${BIN}"
        tar -czf ${BIN}.tar.gz ${BIN} 
    elif [ $2 == tar.bz2 ];then
        logInfo "[$0:${LINENO}]=>" "tar -cjf ${BIN}.tar.bz2 ${BIN}"
        tar -cjf ${BIN}.tar.bz2 ${BIN} 
    else
        logErr "[$0:${LINENO}]=>" "Invalid parameter"
    fi

    if [ $? != 0 ]; then
        logErr "[$0:${LINENO}]=>" "tar run error"
    fi

}

# kill指定程序
killapp()
{
    checkarg "$#" "2"
    if [ $? == 1 ];then
        logErr "[$0:${LINENO}]=>" "invalid parameter"
        exit 0
    fi

    local bin=$2
    logDebug "[$0:${LINENO}]=>" "`ps -ef | grep -w $bin | grep -v "grep\|$0"`"
    local pid=`ps -ef | grep -w $bin | grep -v "grep\|$0" | awk '{print $2}'`

    if [ -n "$pid" ];then
        logInfo "[$0:${LINENO}]=>" "kill -9 $pid"
        kill -9 $pid
    fi
}

# 生成本地证书
mkcert()
{
    logInfo "[$0:${LINENO}]=>" "mkcert ${2}"
    log "在脚本中使用mkcert命令一直异常错误，这里手动给ion-sfu生成证书步骤"
    log "之前没有运行过mkcert -install 先运行一次"
    log "创建自签名证书例如要为域名：test.local和IP：127.0.0.1创建证书，可以使用如下的命令:"
    log "mkcert 127.0.0.1 localhost 10.10.14.3"
}


# 运行指定程序
runapp()
{
    checkarg "$#" "3"
    if [ $? == 1 ];then
        logErr "[$0:${LINENO}]=>" "invalid parameter"
        exit 0
    fi

    local bin=$2
    local config=$3
    local logfile=$bin-$DATE
    logDebug "[$0:${LINENO}]=>" "`ps -ef | grep -w $bin | grep -v "grep\|$0"`"
    local pid=`ps -ef | grep -w $bin | grep -v "grep\|$0" | awk '{print $2}'`

    if [ -n "$pid" ];then
        logInfo "[$0:${LINENO}]=>" "kill -9 $pid"
        kill -9 $pid
    fi

    if [ $bin == ehome-srv ];then
        logInfo "[$0:${LINENO}]=>" "./$bin -config=$config >> $LOG_DIR/$logfile.log 2>&1 &"
        ./$bin -config=$config >> $LOG_DIR/$logfile.log 2>&1 &
    elif [ $bin == iot-rtc ];then
        logInfo "[$0:${LINENO}]=>" "./$bin -config=$config >> $LOG_DIR/$logfile.log 2>&1 &"
        ./$bin -config=$config >> $LOG_DIR/$logfile.log 2>&1 &
    elif [ $bin == ion-sfu ];then
        logInfo "[$0:${LINENO}]=>" "./$bin -c=$config -jaddr="0.0.0.0:7000" -gaddr="0.0.0.0:50051" >> $LOG_DIR/$logfile.log 2>&1 &"
        #./$bin -c=$config -jaddr="0.0.0.0:7000" -gaddr="0.0.0.0:50051" -cert 127.0.0.1+2.pem -key 127.0.0.1+2-key.pem >> $LOG_DIR/$logfile.log 2>&1 &
        ./$bin -c=$config -jaddr="0.0.0.0:7000" -gaddr="0.0.0.0:50051" -cert 10.10.14.3_public.crt -key 10.10.14.3.key >> $LOG_DIR/$logfile.log 2>&1 &
    else
        logErr "[$0:${LINENO}]=>" "Invalid parameter"
    fi

    if [ $? != 0 ]; then
        logErr "[$0:${LINENO}]=>" "$bin run error"
    fi

}

# 解析命令
parse()
{
    local build_target=$1

    if [ ! -n "$build_target" ];then
        logErr "[$0:${LINENO}]=>" "miss parameter"
        usage
        exit 0
    fi

    if [ $build_target == scp ];then
        pack_scp "$@"
        exit 0
    elif [ $build_target == ssh ];then
        ssh_login "$@"
        exit 0 
    elif [ $build_target == build ];then
        gobuild "$@"
        exit 0 
    elif [ $build_target == packed ];then
        packedbin "$@"
        exit 0 
    elif [ $build_target == mkcert ];then
        mkcert "$@"
        exit 0 
    elif [ $build_target == run ];then
        runapp "$@"
        exit 0 
    elif [ $build_target == kill ];then
        killapp "$@"
        exit 0
    elif [ $build_target == --help ] || [ $build_target == help ] || [ $build_target == -h ] || [ -z $build_target ];then
        usage
        exit 0
    else
        logErr "[$0:${LINENO}]=>" "Invalid parameter"
        exit 0
    fi
}

# 主函数
main()
{
    parse "$@"
}

main "$@"
