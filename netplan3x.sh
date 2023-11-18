#!/bin/bash
RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ "$EUID" -ne '0' ]]; then
    echo "$(tput setaf 1)Error: You must run this script as root!$(tput sgr0)"
    exit 1
fi
read _ _ gateway _ < <(ip route list match 0/0)
CIP=$(hostname -I | cut -d' ' -f1)

echo -e "I ${RED} installing utils ${NC} "
apt update
apt install -y curl net-tools htop

echo -e "I ${RED} Enable forwarding ${NC} "

sysctl -w net.ipv4.ip_forward=1
sysctl -p

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

chmod 600 /etc/netplan/99-netcfg-vmware.yaml
echo -e "I ${RED} Finish! Current routes: ${NC} "
ip route list


echo -e "I ${RED} 3x-ui installing ${NC} "
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
