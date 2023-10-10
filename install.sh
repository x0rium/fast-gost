#!/bin/bash
RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ "$EUID" -ne '0' ]]; then
    echo "$(tput setaf 1)Error: You must run this script as root!$(tput sgr0)"
    exit 1
fi
read _ _ gateway _ < <(ip route list match 0/0)
CIP=$(hostname -I | cut -d' ' -f1)

echo -e "I ${RED} Gost installing ${NC} "
bash <(curl -fsSL https://github.com/go-gost/gost/raw/master/install.sh) --install

echo -e "I ${RED} installing utils ${NC} "
apt update
apt install -y curl net-tools

echo -e "I ${RED} Add service ${NC} "
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


echo -e "I ${RED} Creating GOST config template ${NC} "

mkdir /etc/gost

cat <<EOF | sudo tee /etc/gost/gost.yaml
services:
- name: service-1
  addr: "$CIP:51080"
  interface: "$CIP"
  resolver: resolver-0
  handler:
    type: socks5
    auth:
      username: user1
      password: pass1
    metadata:
      udp: true
  listener:
    type: tcp

- name: service-2
  addr: "2.2.2.137:51080"
  interface: "2.2.2.137"
  resolver: resolver-0
  handler:
    type: socks5
    auth:
      username: user2
      password: pass2
    metadata:
      udp: true
  listener:
    type: tcp

- name: service-3
  addr: "2.2.2.141:51080"
  interface: "2.2.2.141"
  resolver: resolver-0
  handler:
    type: socks5
    auth:
      username: user3
      password: pass3
    metadata:
      udp: true
  listener:
    type: tcp

- name: service-4
  addr: "2.2.2.143:51080"
  interface: "2.2.2.143"
  resolver: resolver-0
  handler:
    type: socks5
    auth:
      username: user4
      password: pass4
    metadata:
      udp: true
  listener:
    type: tcp

- name: service-5
  addr: "2.2.2.151:51080"
  interface: "2.2.2.110"
  resolver: resolver-0
  handler:
    type: socks5
    auth:
      username: user5
      password: pass5
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

echo -e "I ${RED} Replace netplan 99 config ${NC} "

cat <<EOF | sudo tee /etc/netplan/99-netcfg-vmware.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens160:
      dhcp4: no
      dhcp6: no
      addresses:
        - $CIP/24
      routes:
        - to: 0.0.0.0/0
          via: $gateway
          metric: 101
        - to: 0.0.0.0/0
          via: $gateway
          table: 101
      routing-policy:
        - from: $CIP
          table: 101
      nameservers:
        addresses:
          - 8.8.8.8


    ens161:
      addresses:
        - 2.2.2.137/24
      routes:
        - to: 0.0.0.0/0
          via: $gateway
          metric: 102
        - to: 0.0.0.0/0
          via: $gateway
          table: 102
      routing-policy:
        - from: 2.2.2.137
          table: 102
      nameservers:
        addresses:
          - 8.8.8.8

    ens192:
      addresses:
        - 2.2.2.141/24
      routes:
        - to: 0.0.0.0/0
          via: $gateway
          metric: 103
        - to: 0.0.0.0/0
          via: $gateway
          table: 103
      routing-policy:
        - from: 2.2.2.141
          table: 103
      nameservers:
        addresses:
          - 8.8.8.8

    ens224:
      addresses:
        - 2.2.2.143/24
      routes:
        - to: 0.0.0.0/0
          via: $gateway
          metric: 104
        - to: 0.0.0.0/0
          via: $gateway
          table: 104
      routing-policy:
        - from: 2.2.2.143
          table: 104
      nameservers:
        addresses:
          - 8.8.8.8

    ens256:
      addresses:
        - 2.2.2.151/24
      routes:
        - to: 0.0.0.0/0
          via: $gateway
          metric: 105
        - to: 0.0.0.0/0
          via: $gateway
          table: 105
      routing-policy:
        - from: 2.2.2.151
          table: 105
      nameservers:
        addresses:
          - 8.8.8.8
EOF

echo -e "I ${RED} Finish! Current routes: ${NC} "
ip route list