#!/bin/bash



SIPP=../sipp
SIPP_SSL=../sipp_ssl
USERNAME=$1
PASSWORD="password"
LADDR=$2
LPORT=$3
EXPIRES=3600
AUTH_USER=$1

EM_ADDR=$4
TRANSPORT=u1

function start_uas() {
    $SIPP -i $LADDR -p $LPORT -sf uas_agent_check.sf -t $TRANSPORT
}





function set_register_uac() {
    echo "SEQUENTIAL"    > data_reg.csv
    echo -n "$USERNAME;" >> data_reg.csv
    echo -n "[authentication username=$AUTH_USER password=$PASSWORD];" >> data_reg.csv
    echo -n "$LPORT;"   >> data_reg.csv
    echo  "$EXPIRES" >> data_reg.csv
}



function register_uac() {
    $SIPP_SSL -i $LADDR  -p $LPORT -m 1 -inf data_reg.csv $EM_ADDR \
        -sf uac_register.sf \
        -t $TRANSPORT

    if [ "$?" -ne "0" ]; then 
        echo "call failed"
        exit
    fi
}


function usage() {
    echo 
    echo " UAS"
    echo " Usage:"
    echo "   $(basename $0) <local-user> <local-addr> <local-port> <remote-addr>"
    echo    
    echo
}




# -------------------------------------
#
#                 MAIN
#
# -------------------------------------

if [ $# -lt 3 ]; then
    usage
    exit 1
fi

set_register_uac
register_uac
sleep 1
start_uas


