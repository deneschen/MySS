#!/bin/bash
cd `dirname $0`

source ./common

loc_speeder_port=6001
pub_udp2raw_port=6002
loc_udp2raw_port=7004

lh=127.0.0.1

strore_pid=/tmp/pid
pid_ss=$strore_pid/pid_ss
pid_kcptun=$strore_pid/pid_kcptun
pid_speederv2=$strore_pid/pid_speederv2
pid_udp2raw=$strore_pid/pid_udp2raw

[ -e $strore_pid ] || mkdir -p $strore_pid

function start_ss() {
	local flog=/tmp/sslog
	if [[ $is_server == 1 ]];then
		./ss/ssserver -c ./ss/ss.json >$flog 2>&1 &
	else
		./ss/sslocal -c ./ss/cl.json >$flog 2>&1 &
	fi
	pid=$!
	pid_exists $pid
	if [ $? == 1 ];then
		echo $pid >$pid_ss
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
	pid_exists $pid
	if [ $? == 1 ];then
		echo $pid >$pid_kcptun
		echo -e "KCP \033[32m启动成功\033[0m"
	else
		echo -e "KCP \033[33m启动失败\033[0m"
	fi
}

function start_speeder() {
	local flog=/tmp/speederlog
	if [[ $is_server == 1 ]];then
		./UDPspeeder/speederv2_amd64 -s -l$lh:$loc_speeder_port -r$lh:$loc_ss_port -k "passwd" -f20:40 --mode 0 >$flog 2>&1 &
	else
		./UDPspeeder/speederv2_amd64 -c -l$lh:$loc_kcp_port -r$lh:$loc_udp2raw_port -k "passwd" -f20:40 --mode 0 >$flog 2>&1 &
	fi
	pid=$!
	pid_exists $pid
	if [ $? == 1 ];then
		echo $pid >$pid_speederv2
		echo -e "SpeedV2 \033[32m启动成功\033[0m"
	else
		echo -e "SpeedV2 \033[33m启动失败\033[0m"
	fi
}

function start_udp2raw() {
	local flog=/tmp/udp2rawlog
	if [[ $is_server == 1 ]];then
		./udp2raw/udp2raw_amd64 -s -l$lh:$pub_udp2raw_port -r$lh:$loc_speeder_port -a -k "passwd" --raw-mode faketcp --cipher-mode xor --auth-mode none >$flog 2>&1 &
	else
		sudo ./udp2raw/udp2raw_amd64 -c -l$lh:$loc_udp2raw_port -r$server_ip:$pub_udp2raw_port -a -k "passwd" --raw-mode faketcp --cipher-mode xor --auth-mode none >$flog 2>&1 &
	fi
	pid=$!
	pid_exists $pid
	if [ $? == 1 ];then
		echo $pid >$pid_udp2raw
		echo -e "UDP2RAW \033[32m启动成功\033[0m"
	else
		echo -e "UDP2RAW \033[33m启动失败\033[0m"
	fi
}

function mod_json() {
	sed -i
	's/MY_SERVER_IP/'$server_ip'/;s/MY_SERVER_PORT/'$loc_ss_port'/;s/MY_SERVER_PASSWD/'$ss_passwd'/;s/PUB_KCPTUN_PORT/'$pub_kcp_port'/;s/LOC_KCPTUN_PORT/'$loc_kcp_port'/' kcptun/cli.json kcptun/ss.json ss/cl.json ss/ss.json test.sh Win/cl.json Win/cli.json Win/start.cmd
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

function usage() {
	echo "Usage:"
	echo "$0"
	echo "-c <start|stop|restart>"
	echo "-i <server_ip>"
	echo "-p <server_port>"
	echo "-w <passwd>"
	echo "-k <pub_kcp_port>"
	echo "-l <loc_kcp_port>"
	echo "[-s](this is optional)"
	exit -1;
}

while getopts "c:i:p:w:k:l:s" o; do
	case "${o}" in
		c)
			export cmd=${OPTARG}
			;;
		i)
			export server_ip=${OPTARG}
			;;
		p)
			export loc_ss_port=${OPTARG}
			;;
		w)
			export ss_passwd=${OPTARG}
			;;
		k)
			export pub_kcp_port=${OPTARG}
			;;
		l)
			export loc_kcp_port=${OPTARG}
			;;
		s)
			export is_server=1
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [[ -z "$cmd" || -z "$server_ip" || -z "$loc_ss_port" || -z "$ss_passwd" || -z "$pub_kcp_port" || -z "$loc_kcp_port" ]];
then
	usage;
fi

mod_json

echo cmd=$cmd
echo server_ip=$server_ip
echo loc_ss_port=$loc_ss_port
echo ss_passwd=$ss_passwd
echo pub_kcp_port=$pub_kcp_port
echo loc_kcp_port=$loc_kcp_port
echo is_server=$is_server

if [[ "start" == $cmd ]];then
	echo "即将：启动脚本";
	start
elif  [[ "stop" == $cmd ]];then
	echo "即将：停止脚本";
	stop_proces;
elif  [[ "restart" == $cmd ]];then
	stop_proces
	start
fi
echo "服务状态："
pid_status $pid_ss "SS"
pid_status $pid_kcptun "KCP"
pid_status $pid_speederv2 "speederv2"
pid_status $pid_udp2raw "udp2raw"
