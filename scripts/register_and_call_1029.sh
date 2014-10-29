#! /bin/bash

# register 1029
./sipp 192.168.1.200  -m 1 -s 2408881029 -i 192.168.1.166 -t t1 -sf registerOK.sn -p 5070 

# register 1027
./sipp 192.168.1.200  -m 1 -s 2408881027 -i 192.168.1.166 -t t1 -sf registerOK.sn


# call 1029
./sipp 192.168.1.200 -m 1 -s 2408881029 -i 192.168.1.166 -t t1 -inf database.csv -sf uac.sn

