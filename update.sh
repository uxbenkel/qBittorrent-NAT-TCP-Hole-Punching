#!/bin/sh

# Natter/NATMap
private_port=$4 # Natter: $3; NATMap: $4
public_port=$2 # Natter: $5; NATMap: $2

# qBittorrent.
qb_web_port='8080'
qb_username='admin'
qb_password='adminadmin'
qb_ip='localhost'
now_time=$(date +%Y-%m-%d)' '$(date +%H:%M:%S)

# wrap text info
text="<b>natmap 打洞成功通知</b>

qBittorrent 端口已更新为：$public_port"

# bot parameter
bot_api='bot_api'
chat_id='chat_id'
url="https://api.telegram.org/bot${bot_api}/sendMessage"

echo "[$now_time] Update qBittorrent listen port to $public_port..."

# Update qBittorrent listen port.
qb_cookie=$(curl -s -i --header "Referer: http://$qb_ip:$qb_web_port" --data "username=$qb_username&password=$qb_password" http://$qb_ip:$qb_web_port/api/v2/auth/login | grep -i set-cookie | cut -c13-48)
curl -X POST -b "$qb_cookie" -d 'json={"listen_port":"'"$public_port"'"}' "http://$qb_ip:$qb_web_port/api/v2/app/setPreferences"

echo "[$now_time] Update iptables..."

# Use iptables to forward traffic.
LINE_NUMBER=$(iptables -t nat -nvL --line-number | grep "$private_port" | head -n 1 | awk '{print $1}')
if [ "$LINE_NUMBER" != "" ]; then
    iptables -t nat -D PREROUTING "$LINE_NUMBER"
fi
iptables -t nat -I PREROUTING -p tcp --dport "$private_port" -j REDIRECT --to-port "$public_port"

echo "[$now_time] Done."

#发送消息
curl -s -X POST ${url} -d chat_id=${chat_id} -d text="${text}" -d parse_mode=HTML >/dev/null 2>&1

echo "[$now_time] Message has been sent."