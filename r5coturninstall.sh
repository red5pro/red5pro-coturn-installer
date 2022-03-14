#!/bin/bash
#
# r5watchinstall.sh
#
# Coturn Install Script
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
  echo "usage: r5wcoturninstall.sh FQDN or EXTERNAL_IP"
  echo "example: ./r5coturninstall.sh turnserver.example.org"
  echo "example: ./r5coturninstall.sh 10.0.0.1"
  exit
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
  exit
fi
meet.google.com/tbf-mkpo-aog