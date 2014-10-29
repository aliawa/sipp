#!/bin/bash

CALLER=$1
COMMAND=$2
IP=$3
PORT=$4

cat << MARKER
 CALLER=$CALLER
 COMMAND=$COMMAND
 IP=$IP
 PORT=$PORT
MARKER


if [[ "$COMMAND" == "start" ]]; then
    IFACE=$(ip route show | grep $IP | awk '{print $3}')
    echo "sudo tcpdump -nni $IFACE -s0 -w $CALLER.pcap dst host $IP and dst port $PORT"
    sudo tcpdump -nni $IFACE -s0 -w $CALLER.pcap dst host $IP and dst port $PORT &
    echo $! > $CALLER.pid
else
    echo "kill  -9 $(cat $CALLER.pid)"
    sudo kill  -9 $(cat $CALLER.pid)
    rm -f $CALLER.pid
fi






