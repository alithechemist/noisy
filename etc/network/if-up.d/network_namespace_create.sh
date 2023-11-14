#!/bin/bash
#
#
set -x
#
NS=regular-dns
IF=wlp0s20f3

mkdir -p /etc/netns/${NS}
echo "nameserver 8.8.8.8" > /etc/netns/${NS}/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/netns/${NS}/resolv.conf

ip netns del ${NS}
ip link delete veth1


ip netns add ${NS}
ip link add veth1 type veth peer name vpeer1
ip link set vpeer1 netns ${NS}
ip addr add 10.200.1.1/24 dev veth1
ip link set veth1 up
ip netns exec ${NS} ip addr add 10.200.1.2/24 dev vpeer1
ip netns exec ${NS} ip link set vpeer1 up
ip netns exec ${NS} ip link set lo up
ip netns exec ${NS} ip route add default via 10.200.1.1
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -P FORWARD DROP
iptables -F FORWARD
iptables -A FORWARD -i ${IF} -o veth1 -j ACCEPT
iptables -A FORWARD -i veth1 -o ${IF} -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.200.1.2/24 -o ${IF} -j MASQUERADE
