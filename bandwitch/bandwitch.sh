#!/bin/bash
# Author: RaMa 
# Version: 0.7
# Script for measuring NIC bandwidth created
if [ $# -ne 1 ]; then
    echo "Your command line contains $# arguments."
    echo "You must provide ONE ethernet interface name.";
    echo Available interfaces: $(ls -I "lo" /sys/class/net/)
    echo "Example: ./$(basename "$0")" ens3
    exit 1;
fi

clear

EVERY=3
echo The page will give you numbers after first refresh so in $EVERY s.
NIC=$1
SPEED=$(cat /sys/class/net/$NIC/speed)
if [ $SPEED -lt 0 ]
then
  SPEED=$(ifconfig $NIC | grep -oP 'txqueuelen \K\w+')
fi

while true
do
  RX_Bytes=$(cat /sys/class/net/$NIC/statistics/rx_bytes)
  TX_Bytes=$(cat /sys/class/net/$NIC/statistics/tx_bytes)
  sleep $EVERY
  clear
  RX_Bytes_5=$(cat /sys/class/net/$NIC/statistics/rx_bytes)
  TX_Bytes_5=$(cat /sys/class/net/$NIC/statistics/tx_bytes)
  #echo RX: $RX_Bytes
  #echo RX_5: $RX_Bytes_5
  #echo TX: $TX_Bytes
  #echo TX_5: $TX_Bytes_5
  RX_Bytes_DIFF=$((RX_Bytes_5 - RX_Bytes))
  TX_Bytes_DIFF=$((TX_Bytes_5 - TX_Bytes))
  TOTAL_BC=$(echo "scale=4; ($RX_Bytes_DIFF + $TX_Bytes_DIFF)  / 1048576 " | bc)
  echo Bandwidth Speed: $SPEED Mbit/s  Utilization: $(echo "scale=4; (($TOTAL_BC * 8) / $SPEED) * 100 " | bc)%
  echo RX in $EVERY s: $RX_Bytes_DIFF Bytes
  echo TX in $EVERY s: $TX_Bytes_DIFF Bytes
  echo Total in $EVERY s: $TOTAL_BC MBytes

  echo ""
  echo "Press [CTRL+C] to stop.."
done
