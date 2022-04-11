#!/bin/bash
set -e
if [[ $is_server == 1 ]];
then
	socat -v UDP-LISTEN:4000,fork PIPE
else
	./UDPping/udpping.py MY_SERVER_IP 4000
fi
