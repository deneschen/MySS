#!/bin/bash
echo "KCP/SpeederV2/Udp2raw一键启动脚本"
cd `dirname $0`

param=$1
if [ ! -d "./pid" ];then
	mkdir ./pid
fi

pid_ss=./pid/ss_$0.pid
pid_kcptun=./pid/kcptun_$0.pid
pid_speederv2=./pid/speederv2_$0.pid
pid_udp2raw=./pid/udp2raw_$0.pid

source ./common

loc_speeder_port=6001
pub_udp2raw_port=6002
loc_udp2raw_port=7004

function start_ss() {
	local flog=/tmp/sslog
	if [[ $is_server == 1 ]];then
		./ss/ssserver -c ./ss/ss.json >$flog 2>&1 &
	else
		./ss/sslocal -c ./ss/cl.json >$flog 2>&1 &
	fi
	pid=$!
	echo $pid >$pid_ss
	sleep 2
	pid_exists $pid
	if [ $? == 1 ];then
		echo -e "SS \033[32m启动成功\033[0m"
	else
		echo -e "SS \033[33m启动失败\033[0m"
	fi
}

function start_kcp() {
	local flog=/tmp/kcplog
	if [[ $is_server == 1 ]];then
		./kcptun/server_linux_amd64 -c ./kcptun/ss.json >$flog 2>&1 &
	else
		./kcptun/client_linux_amd64 -c ./kcptun/cli.json >$flog 2>&1 &
	fi
	pid=$!
	echo $pid >$pid_kcptun
	sleep 2
	pid_exists $pid
	if [ $? == 1 ];then
		echo -e "KCP \033[32m启动成功\033[0m"
	else
		echo -e "KCP \033[33m启动失败\033[0m"
	fi
}

function start_speeder() {
	local flog=/tmp/speederlog
	if [[ $is_server == 1 ]];then
		./UDPspeeder/speederv2_amd64 -s -l0.0.0.0:$loc_speeder_port -r0.0.0.0:MY_SERVER_PORT -k "passwd" -f20:40 --mode 0 >$flog 2>&1 &
	else
		./UDPspeeder/speederv2_amd64 -c -l0.0.0.0:20001 -r0.0.0.0:$loc_udp2raw_port -k "passwd" -f20:40 --mode 0 >$flog 2>&1 &
	fi
	pid=$!
	echo $pid >$pid_speederv2
	sleep 2
	pid_exists $pid
	if [ $? == 1 ];then
		echo -e "SpeedV2 \033[32m启动成功\033[0m"
	else
		echo -e "SpeedV2 \033[33m启动失败\033[0m"
	fi
}

function start_udp2raw() {
	local flog=/tmp/udp2rawlog
	if [[ $is_server == 1 ]];then
		./udp2raw/udp2raw_amd64 -s -lMY_SERVER_IP:$pub_udp2raw_port -r0.0.0.0:$loc_speeder_port -a -k "passwd" --raw-mode faketcp --cipher-mode xor --auth-mode none >$flog 2>&1 &
	else
		sudo ./udp2raw/udp2raw_amd64 -c -l0.0.0.0:$loc_udp2raw_port -rMY_SERVER_IP:$pub_udp2raw_port -a -k "passwd" --raw-mode faketcp --cipher-mode xor --auth-mode none >$flog 2>&1 &
	fi
	pid=$!
	echo $pid >$pid_udp2raw
	sleep 2
	pid_exists $pid
	if [ $? == 1 ];then
		echo -e "UDP2RAW \033[32m启动成功\033[0m"
	else
		echo -e "UDP2RAW \033[33m启动失败\033[0m"
	fi
}

function start() {
	start_ss
	start_kcp
	start_speeder
	start_udp2raw
}

function stop_proces() {
	stop $pid_ss
	stop $pid_kcptun
	stop $pid_speederv2
	stop $pid_udp2raw
}

if [[ "start" == $param ]];then
	echo "即将：启动脚本";
	start
elif  [[ "stop" == $param ]];then
	echo "即将：停止脚本";
	stop_proces;
elif  [[ "restart" == $param ]];then
	stop_proces
	start
else
	echo "当前配置(如不正确，请编辑脚本进行修改)："
	echo -e "\t 服务端IP：MY_SERVER_IP"
	echo -e "\t 本地加速端口: MY_SERVER_PORT"
	echo "服务状态："

	pid_status $pid_ss "SS"
	pid_status $pid_kcptun "KCP"
	pid_status $pid_speederv2 "speederv2"
	pid_status $pid_udp2raw "udp2raw"

	echo "使用方式：  is_server=1 or 0"
	echo -e "\t运行服务：bash $0 start "
	echo -e "\t停止服务：bash $0 stop "
	echo -e "\t重启服务：bash $0 restart "
fi
