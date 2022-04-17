@echo.
@set PATH=%~dp0;%~dp0/bin:%PATH%

@set SERVER_IP=MY_SERVER_IP
@set loc_kcp_port=LOC_KCPTUN_PORT
@set loc_speeder_port=6001
@set pub_udp2raw_port=6002
@set loc_udp2raw_port=7004

@set GATEWAY=10.0.0.1
@route DELETE %SERVER_IP%  && route ADD %SERVER_IP% mask 255.255.255.255 %GATEWAY% METRIC 20
@start /b udp2raw_x86 -c -l0.0.0.0:%loc_udp2raw_port% -r%SERVER_IP%:%pub_udp2raw_port% -a -k "passwd" --raw-mode faketcp --cipher-mode xor --auth-mode none
@start /b speederv2_x86 -c -l0.0.0.0:%loc_kcp_port% -r0.0.0.0:%loc_udp2raw_port% -k "passwd" -f20:40 --mode 0
@start /b sslocal -c cl.json
@start /b client_linux_amd64 -c cli.json
