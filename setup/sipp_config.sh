#! /bin/bash


# ----------------------------------------------
# Environment
# C Interface usually used for clients 
# S Interface usually used for servers 
#
export SADDR=`ifconfig eth1 | awk -F "[: \t]+" '/inet addr:/ {print $4}'`
export CADDR=`ifconfig eth0 | awk -F "[: \t]+" '/inet addr:/ {print $4}'`
# ----------------------------------------------
# Additional address required by some scenarios
# Create the interfaces first and then assign 
# appropriate values
#
export CADDR2=
export CADDR3=
export SADDR2=
export SADDR3=
# ----------------------------------------------
# Base ports on 'S' and 'C' interface
#
export SPORT=5080
export CPORT=5080
# ----------------------------------------------
# Ports on S interface
#
export SPORT1=$SPORT
export SPORT2=$((SPORT+10))
export SPORT3=$((SPORT+20))
export SPORT4=$((SPORT+30))
# ----------------------------------------------
# Ports on C interface
#
export CPORT1=$CPORT
export CPORT2=$((CPORT+10))
export CPORT3=$((CPORT+20))
export CPORT4=$((CPORT+30))
export EWUA_SIPPORT=1025

# ----------------------------------------------
# Edgemarc under test LAN address
#
export EM_LAN=
export EM_WAN=
# ----------------------------------------------
# A second proxy address
# Used in limit proxy and transparent mode tests
# Important: This address should *not* be on the same
# machine as CADDR other wise the packets will just
# go to the loopback interface.
# 
export PROXY2_ADDR=10.10.10.149 
export PROXY2_PORT=5080




# -----------------------------------------------------------------
#
#                              FUNCTIONS 
#
# -----------------------------------------------------------------


#
# create data_call.csv in the format
# ARG1;ARG2;ARG3;...
#
sippconfig() {
    echo "SEQUENTIAL" > data_call.csv
    echo -n "$1" >> data_call.csv
    shift
    while [ "$#" -ne 0 ]
    do
        echo -n ";$1" >> data_call.csv
        shift
    done
    echo >> data_call.csv 
}



