#!/bin/bash
set -ex

SHDIR=$(realpath $0)
SHDIR=$(dirname $SHDIR)

source $SHDIR/scripts/common

STOREPID=/tmp/pid
[ -e $STOREPID ] || mkdir -p $STOREPID

pid_ss=$STOREPID/pid_ss
pid_kcptun=$STOREPID/pid_kcptun

# 2022-blake3-chacha20-poly1305	32
# openssl rand -base64 <长度>

function start_shadowsocks() {
	nohup $SHDIR/shadowsocks/ssserver -c $SHDIR/shadowsocks/config.json &
	pid=$!
	sleep 1
	if [ $pid == `pgrep ssserver` ]; then
		echo $pid >$pid_ss
		echo -e "SS \033[32m启动成功\033[0m"
	else
		echo -e "SS \033[33m启动失败\033[0m"
		exit -1
	fi
}

function start_kcptun() {
	nohup $SHDIR/kcptun/server_linux_amd64 -c $SHDIR/kcptun/config.json &
	pid=$!
	sleep 1
	if [ $pid == `pgrep server_linux_` ]; then
		echo $pid >$pid_kcptun
		echo -e "SS \033[32m启动成功\033[0m"
	else
		echo -e "SS \033[33m启动失败\033[0m"
		exit -1
	fi
}

function mod_json()
{
	# echo kcptun config
	sed -i 's/SS_SERVER_IP/'$ss_server_ip'/'     $SHDIR/kcptun/config.json
	sed -i 's/SS_SERVER_PORT/'$ss_server_port'/' $SHDIR/kcptun/config.json
	sed -i 's/SS_PASSWD/'$ss_passwd'/'           $SHDIR/kcptun/config.json
	sed -i 's/KCPTUN_PORT/'$kcptun_port'/'       $SHDIR/kcptun/config.json
	# echo shadowsocks config
	sed -i 's/SS_SERVER_IP/'$ss_server_ip'/'     $SHDIR/shadowsocks/config.json
	sed -i 's/SS_SERVER_PORT/'$ss_server_port'/' $SHDIR/shadowsocks/config.json
	sed -i 's/SS_PASSWD/'$ss_passwd'/'           $SHDIR/shadowsocks/config.json
	sed -i 's/KCPTUN_PORT/'$kcptun_port'/'       $SHDIR/shadowsocks/config.json
}

function start_all()
{
	start_shadowsocks
	sleep 3
	start_kcptun
	sleep 3
}

function stop_all()
{
	stop $pid_ss
	stop $pid_kcptun
}

function usage() {
	echo "Usage:"
	echo "$0"
	echo "-c <start|stop|restart>"
	echo "-i <ss_server_ip>"
	echo "-p <ss_server_port>"
	echo "-w <ss_passwd>"
	echo "-k <kcptun_port>"
	exit -1;
}

while getopts "c:i:p:w:k:l:s" o; do
	case "${o}" in
		c)
			export cmd=${OPTARG}
			;;
		i)
			export ss_server_ip=${OPTARG}
			;;
		p)
			export ss_server_port=${OPTARG}
			;;
		w)
			export ss_passwd=${OPTARG}
			;;
		k)
			export kcptun_port=${OPTARG}
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [[ "status" == $cmd ]];then
	netstat -antpul
	exit 0
fi

if [[ -z "$cmd" || -z "$ss_server_ip" || -z "$ss_server_port" || -z "$ss_passwd" || -z "$kcptun_port" ]];
then
	usage;
fi

mod_json

echo cmd=$cmd
echo ss_server_ip=$ss_server_ip
echo ss_server_port=$ss_server_port
echo ss_passwd=$ss_passwd
echo kcptun_port=$kcptun_port

if [[ "start" == $cmd ]];then
	echo "即将：启动脚本";
	start_all;
elif  [[ "stop" == $cmd ]];then
	echo "即将：停止脚本";
	stop_all;
elif  [[ "restart" == $cmd ]];then
	stop_all;
	start_all;
fi
echo "服务状态："
sleep 1
netstat -antup
