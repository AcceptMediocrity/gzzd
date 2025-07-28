#!/usr/bin/env bash

#####################
# 帮助信息
#####################
usage() {
cat <<EOF
Usage: $(basename "$0") -a APP_NAME [OPTIONS]

Required:
  -a, --app APP_NAME      要调试的应用名称（必填）

Options:
  -w, --work-dir DIR      临时数据目录，默认 /tmp
  -u, --ui-port PORT      UI 端口，默认 9091
  -p, --proxy-server PORT proxy 与 ui 通信端口，默认 9013
  -g, --proxy-agent PORT  proxy 与 agent 通信端口，默认 9014
  -i, --ip IP             本机 IPv4，默认自动探测
  -h, --help              显示帮助
EOF
exit 1
}

get_first_ipv4() {
    ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1
}

#####################
# 参数解析：支持 -a value 和 --app=value 两种风格
#####################
parse_args() {
    # 默认值
    APP_NAME=""
    WORK_DIR="/tmp"
    UI_PORT=9091
    PROXY_SVR_PORT=9013
    PROXY_AGENT_PORT=9014
    IP=$(get_first_ipv4)
    AGENT_DIR=${WORK_DIR}/gzzd

    # 先把长选项映射到短选项
    for arg in "$@"; do
        shift
        case "$arg" in
            --app)         set -- "$@" "-a" ;;
            --work-dir)    set -- "$@" "-w" ;;
            --ui-port)     set -- "$@" "-u" ;;
            --proxy-server)set -- "$@" "-p" ;;
            --proxy-agent) set -- "$@" "-g" ;;
            --ip)          set -- "$@" "-i" ;;
            --help)        set -- "$@" "-h" ;;
            *)             set -- "$@" "$arg" ;;
        esac
    done

    while getopts ":a:w:u:p:g:i:h" opt; do
        case "$opt" in
            a) APP_NAME=$OPTARG ;;
            w) WORK_DIR=$OPTARG ;;
            u) UI_PORT=$OPTARG ;;
            p) PROXY_SVR_PORT=$OPTARG ;;
            g) PROXY_AGENT_PORT=$OPTARG ;;
            i) IP=$OPTARG ;;
            h) usage ;;
            \?) echo "无效参数: -$OPTARG" >&2; usage ;;
            :)  echo "选项 -$OPTARG 需要参数" >&2; usage ;;
        esac
    done

    # 必填校验
    [[ -z "$APP_NAME" ]] && { echo "错误：应用名称必填！"; usage; }

    # 端口必须是数字
    for p in "$UI_PORT" "$PROXY_SVR_PORT" "$PROXY_AGENT_PORT"; do
        [[ "$p" =~ ^[0-9]+$ ]] || { echo "错误：端口必须是数字！"; exit 1; }
    done
}

main() {
    parse_args "$@"

    # 创建目录
    mkdir -p "$WORK_DIR/gzzd"

    # 打印配置，方便调试
    cat <<EOF
=====================
  应用名称      : $APP_NAME
  工作目录      : $WORK_DIR
  UI端口        : $UI_PORT
  Proxy-Svr端口 : $PROXY_SVR_PORT
  Proxy-Agent端口: $PROXY_AGENT_PORT
  本机IP        : $IP
=====================
EOF
}

main "$@"

#sh start-all-stand-alone.sh -a demo -w /tmp -u 9091 -p 9013 -g 9014 -i 192.168.233.129 start
side_option="-Dcustomize.config.ip=${IP} -Dcustomize.config.appName=${APP_NAME} -Dcustomize.config.workDir=${WORK_DIR} -Dserver.port=${UI_PORT} -Dproxy.server.ip=${IP} -Dproxy.server.port=${PROXY_SVR_PORT} -Dproxy.agent.newport=${PROXY_AGENT_PORT} "
start(){
    # 1.启动serverside的ui及proxy
    echo "Start serverside ..."
    echo "side_option: [${side_option}], AGENT_DIR: ${AGENT_DIR}"
    nohup java ${side_option} -jar serverside-ui.jar 2>&1 < /dev/null &
    sleep 5
    target_pid=`ps -ef|grep -iv grep|grep serverside-ui | awk '{print $2}' | sort -n -k 1 | head -n 1`
    if [ -n ${target_pid} ]
    then
        echo "serverside started!!!"
    else
      echo "serverside not started!!!"
      exit 1
    fi
    # 2.启动agent
    start_agent ${IP}:${UI_PORT}
}

start_agent(){
   stop_agent
   rm -rf ${AGENT_DIR}/agent-bin ${AGENT_DIR}/agent-bin.tgz
   proxyServerUrl=$1
   echo "agent-bin.tgz url ${proxyServerUrl}"
   wget -P ${AGENT_DIR} http://${proxyServerUrl}/agent-bin.tgz
   tar -zxvf ${AGENT_DIR}/agent-bin.tgz -C ${AGENT_DIR}
   sed -i 's,BISTOURY_APP_LIB_CLASS,BISTOURY_PROXY_HOST="'${proxyServerUrl}'"\nBISTOURY_APP_LIB_CLASS,' ${AGENT_DIR}/agent-bin/bin/bistoury-agent-env.sh
   #target_pid=`jps | grep -iv jps |grep ${APP_NAME}| awk '{print $1}' | sort -n -k 1 | head -n 1`
   target_pid=`ps -ef|grep ${APP_NAME} | grep -iv grep|grep -v serverside-ui | awk '{print $2}' | sort -n -k 1 | head -n 1`
   echo "[${APP_NAME}] pid : [${target_pid}]"
   sh ${AGENT_DIR}/agent-bin/bin/bistoury-agent.sh -p ${target_pid} -j $JAVA_HOME start
}

stop(){
    echo "Stopping serverside ... "
    echo "side_option: [${side_option}], AGENT_DIR: ${AGENT_DIR}"
    # 1.停止agent
    stop_agent
    #清理工作目录
    rm -rf ${AGENT_DIR}/*
    # 2.停止serverside
    #target_pid=`jps | grep -iv jps|grep serverside-ui | awk '{print $1}' | sort -n -k 1 | head -n 1`
    target_pid=`ps -ef|grep serverside-ui | grep -iv grep | awk '{print $2}' | sort -n -k 1 | head -n 1`
    echo "serverside-ui pid ${target_pid}"
    kill -9 ${target_pid}
    #clear_workDir

}

stop_agent(){
  if [ -f ${AGENT_DIR}/agent-bin/pid/bistoury-agent.pid ]
  then
    echo "bistoury-agent.sh stop"
    sh ${AGENT_DIR}/agent-bin/bin/bistoury-agent.sh stop
  fi
}

clear_workDir(){
  #清理工作目录
  rm -rf ${workDir}/*
}

for CMD in "$@";do true; done
case ${CMD} in
start)
    start
    ;;
stop)
    stop
    exit 0
    ;;
print_config)
    echo "side_option: [${side_option}], AGENT_DIR: ${AGENT_DIR}"
    exit 0
    ;;
*)
    echo "Usage: $0 {start|print_config|stop}" >&2
esac



