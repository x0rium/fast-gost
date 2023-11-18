#!/usr/bin/env bash

# https://github.com/shadowsocks/shadowsocks-rust/releases
export SSVERSION=v1.17.0
export SSPORT=143
export SSPASSWORD="passme123"
export SSARCHIVE="shadowsocks-${SSVERSION}.x86_64-unknown-linux-gnu.tar.xz"
#export SSARCHIVE="shadowsocks-${SSVERSION}.aarch64-unknown-linux-gnu.tar.xz"

export PREFIX=/usr/local/bin
#export PREFIX=${HOME}/.local/bin

export CONFIGDIR=/etc
# TODO change to /etc/shadowsocks-rust/server.json
#export CONFIGDIR=${HOME}/.config/sslocal

wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/${SSVERSION}/${SSARCHIVE} -O ${SSARCHIVE}
tar -xvf ${SSARCHIVE} -C ${PREFIX}


# https://github.com/shadowsocks/v2ray-plugin/releases
 export V2RAY_VERSION=v1.3.2
 export V2RAY_ARCHIVE="v2ray-plugin-linux-amd64-${V2RAY_VERSION}.tar.gz"

 wget "https://github.com/shadowsocks/v2ray-plugin/releases/download/${V2RAY_VERSION}/${V2RAY_ARCHIVE}" -O ${V2RAY_ARCHIVE}
 tar -xvf ${V2RAY_ARCHIVE} -C ${PREFIX}
 mv ${PREFIX}/v2ray-plugin_linux_amd64 ${PREFIX}/v2ray-plugin


# https://github.com/teddysun/xray-plugin/releases
export XRAY_VERSION=v1.8.6
export XRAY_ARCHIVE="xray-plugin-linux-amd64-${XRAY_VERSION}.tar.gz"

wget "https://github.com/teddysun/xray-plugin/releases/download/${XRAY_VERSION}/${XRAY_ARCHIVE}" -O ${XRAY_ARCHIVE}
tar -xvf ${XRAY_ARCHIVE} -C ${PREFIX}
mv ${PREFIX}/xray-plugin_linux_amd64 ${PREFIX}/xray-plugin

### server:

cat <<EOF > ${CONFIGDIR}/ssserver.json
{
    "server": "0.0.0.0",
    "server_port": ${SSPORT},
    "password": "${SSPASSWORD}",
    "method": "chacha20-ietf-poly1305",
    "fast_open": true,
    "timeout": 300,
    "reuse_port": true

////   ,"plugin": "xray-plugin"
    ,"plugin_opts": "server"
    ,"plugin": "v2ray-plugin"
}
EOF

cat <<EOF > /etc/systemd/system/ssserver.service
[Unit]
Description=shadowsocks-rust server
After=network-online.target
[Service]
Type=simple
LimitNOFILE=32768
ExecStart=${PREFIX}/ssserver -c ${CONFIGDIR}/ssserver.json
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ssserver
systemctl restart ssserver
systemctl status ssserver
