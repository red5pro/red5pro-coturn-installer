#!/bin/bash
#
# r5watchinstall.sh
#
# Coturn Installation Script
#
# port requirements:
# tcp: 3478
# udp: 3478
#
# /etc/iptables/rules.v4:
# -A INPUT -p udp --dport 3478 -j ACCEPT
# -A INPUT -p tcp -m state --state NEW -m tcp --dport 3478 -j ACCEPT
#
# usage:
# ./r5coturninstall.sh $FQDN
# example: 
# ./r5coturninstall.sh turnserver.example.org
#

FQDN=$1
# $FQDN validation
if [ -z "$FQDN" ]; then
  echo "usage: r5coturninstall.sh FQDN or EXTERNAL_IP"
  echo "example: ./r5coturninstall.sh turnserver.example.org"
  echo "example: ./r5coturninstall.sh 10.0.0.1"
  exit 1
fi

# install coturn ppa
. /etc/lsb-release
if [ "$DISTRIB_RELEASE" = "22.04" ]; then
  echo "... configuring coturn ppa for ubuntu 22.04 ..."
  add-apt-repository ppa:ubuntuhandbook1/coturn
fi

# update apt
echo "... updating apt ..."
apt update

# install coturn server
if [ ! -f /etc/turnserver.conf ]; then
  echo "... installing coturn server ..."

  apt install -y coturn
  echo "" >> /etc/turnserver.conf
  echo "listening-ip=0.0.0.0" >> /etc/turnserver.conf
  echo "external-ip=$FQDN" >> /etc/turnserver.conf
  echo "realm=red5.net" >> /etc/turnserver.conf
  echo "listening-port=3478" >> /etc/turnserver.conf
  sed -i 's/#TURNSERVER_ENABLED=1/TURNSERVER_ENABLED=1/g' /etc/default/coturn
  systemctl enable coturn
  systemctl restart coturn
else
  echo "... coturn server already installed ..."
fi
if [ ! -f /etc/turnserver.conf ]; then
  echo "... coturn server installation failed ..."
  exit 2
fi

# configure red5 for local coturn server
if [ -d /usr/local/red5pro/webapps/live/script ]; then
  echo "... configuring red5pro for local coturn ..."
  sed -i 's/stun.address.*/stun.address='"$FQDN"':3478/g' /usr/local/red5pro/conf/webrtc-plugin.properties
  # 10.3 added new settings location
  if [ ! -f /usr/local/red5pro/conf/network.properties ]; then
    sed -i 's/var iceServers.*/var iceServers = [{ urls: "stun:'"$FQDN"':3478" }];/g' /usr/local/red5pro/webapps/live/script/r5pro-publisher-failover.js
    sed -i 's/var iceServers.*/var iceServers = [{ urls: "stun:'"$FQDN"':3478" }];/g' /usr/local/red5pro/webapps/live/script/r5pro-subscriber-failover.js
    sed -i 's/var iceServers.*/var iceServers = [{ urls: "stun:'"$FQDN"':3478" }];/g' /usr/local/red5pro/webapps/live/script/r5pro-viewer-failover.js
  else
    sed -i 's/stun.address.*/stun.address='"$FQDN"':3478/g' /usr/local/red5pro/conf/network.properties
  fi
  systemctl restart red5pro
else
  echo "... red5pro not installed properly webapps/live/script is missing ..."
  exit 3
fi

echo "... installation complete ..."
