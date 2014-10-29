#! /bin/sh

n=$(cat reg.data | wc -l)
n=$((n-1))
../sipp -i 192.168.1.152 -m $n -inf reg.data -sf uac_register_OK_1.sf -t t1 192.168.1.231 


