# kernel.sh

from https://raw.githubusercontent.com/jinwyp/one_click_script/master/install_kernel.sh

# shadowsocks 密码生成方法
openssl rand -base64 32

# usage
服务器端执行： ./run.sh -i 服务器端ip -p 服务器端shadowsocks端口号 -w shadowsocks密码 -k kcptun服务器端端口号 -c start
