#!/bin/bash

NO_DIDS=250
REG_RATE=10
WAIT_TIME=10

bold=`tput bold`
normal=`tput sgr0`


waitForProcess() {
    while kill -0 $1 2>/dev/null; do
        sleep 1
    done
}

checkAndReportErrors() {
    if [ -e "uac_register.sf_${1}_errors.log" ]; then
        echo "Iteration:$2 completed with ${bold}Errors${normal}"
    else
        echo "Iteration:$2 completed"
    fi
}



for i in 1 2 3 4 5 6 7 8 9 10
do
    echo
    echo "Registering ${bold}$NO_DIDS${normal} DIDs at ${bold}$REG_RATE ${normal}REGISTERS/sec. Iteration:$i"

    PID_STR=$(../sipp_ssl -i  $CADDR -p $CPORT1 -bg -m $NO_DIDS -r $REG_RATE -inf data_reg.csv  -trace_err $EM_LAN -sf uac_register.sf)
    
    # wait for background sipp to end
    PID=${PID_STR//[^0-9]/}
    waitForProcess $PID
    checkAndReportErrors $PID $i

    echo
    echo "Waiting for $WAIT_TIME seconds ..."
    sleep $WAIT_TIME
done
