#!/bin/bash
RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ "$EUID" -ne '0' ]]; then
    echo "$(tput setaf 1)Error: You must run this script as root!$(tput sgr0)"
    exit 1
fi
PASS=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
USER=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)

echo -e "I ${RED} Change BBR config ${NC} "

echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p


echo -e "I ${RED} Gost installing ${NC} "
bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install

echo -e "I ${RED} installing utils ${NC} "
apt update
apt install -y curl net-tools



echo -e "I ${RED} Creating GOST config template ${NC} "

mkdir /etc/gost

cat <<EOF | sudo tee /etc/gost/gost.yaml
services:
- name: service-1
  addr: ":51080"
  resolver: resolver-0
  handler:
    type: socks5
    auth:
      username: $USER
      password: $PASS
    metadata:
      udp: true
  listener:
    type: tcp

resolvers:
- name: resolver-0
  nameservers:
  - addr: tcp://8.8.8.8
  - addr: tls://8.8.8.8:853
  - addr: https://1.0.0.1/dns-query


log:
  output: stderr
  level: error
  format: json
  rotation:
    maxSize: 100
    maxAge: 10
    maxBackups: 3
    localTime: false
    compress: false
EOF

echo -e "I ${RED} Add gost service to autoload ${NC} "
cat <<EOF | sudo tee /etc/systemd/system/gost.service
[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gost
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable gost
systemctl start gost


echo -e "I ${RED} Restarting gost service ${NC} "
service gost restart


echo -e "${RED}Finished! ${NC} \n Username: $USER  \n Password: $PASS"
