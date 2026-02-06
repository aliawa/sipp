#!/bin/bash

# Constants
SIPP_DIR="/home/aawais/workspace/sipp"
SCRIPTS_DIR="$SIPP_DIR/scripts"
SCENARIO_DIR="$SIPP_DIR/scenario"
# SIPP=$SIPP_DIR/sipp_ssl
SIPP=sipp
TMP_DIR=/home/aawais/tmp


# Fixed Configuration
USERNAME="1024"
PASSWORD="password"
LPORT=5060
EXPIRES=3600
AUTH_USER=$USERNAME
RUSER="1028"
TRANSPORT="u1"

# External Parameters
MODE=
LADDR=
SIPSRVR=
SHOWCMD=0
SIPP_OPT=""

# Internal
RTPECHO=""
UACSF="uac.sf"
UASSF="uas.sf"
MOPT=""

usage()
{
    echo 
    echo "Usage as UAS:"
    echo "  $(basename $0) -m uas|uas_reg -i <local-ip> [options]"
    echo "Usage as UAC:"
    echo "  $(basename $0) -m uac|uac_reg -i <local-ip> -d <remote-ip[:port]> [options]"
    echo
    echo "OPTIONS:"
    echo "  -p <local-port>       default: $LPORT"
    echo "  -t <tcp|udp|tls>      default: udp"
    echo "  -a <send/recv>        send/echo rtp"
    echo "  -o <sipp option>      sipp option in quotes"
    echo "  -c                    Show command"
    echo
    echo "MORE OPTIONS:"
    echo "  -u <local-user>       default: 1024"
    echo "  -h                    display help"
    echo 
}


verify_options() {
    if [[ -z "$LADDR" ]]; then
        echo "Local address is mandatory"
        usage
        exit 1
    fi

    if [[ "$MODE" == "uac_reg" || "$MODE" == "uac" ]]; then
        if [[ -z $SIPSRVR ]]; then
            echo "Remote address must be provided with UAC"
            exit 1
        fi
    fi
}




start_uas() {
    CMD="$SIPP -i $LADDR -p $LPORT \
        -t $TRANSPORT $RTP \
        $SIPP_OPT \
        -sf $SCENARIO_DIR/$UASSF \
        $RTPECHO"
    [ $SHOWCMD -eq 1 ] && echo $CMD || $CMD
}

start_uac() {
    CMD="$SIPP -i $LADDR -p $LPORT -d 2000 -m 1 -r 17 -inf $TMP_DIR/data_call.csv \
        -t $TRANSPORT \
        -sf $SCENARIO_DIR/$UACSF \
        $RTPECHO \
        $SIPP_OPT \
        $SIPSRVR"
    [ $SHOWCMD -eq 1 ] && echo $CMD || $CMD
}


set_call() {
    echo "SEQUENTIAL" > $TMP_DIR/data_call.csv
    echo "$USERNAME;$RUSER" >> $TMP_DIR/data_call.csv
}


set_register_uac() {
    $SCRIPTS_DIR/set_uac_register -d $TMP_DIR $USERNAME $PASSWORD 
}

set_register_uas() {
    [ $1 == "1" ] && MOPT="-m 1"
    $SCRIPTS_DIR/set_uas_register -d $TMP_DIR $PASSWORD 
}



register_uac() {
    CMD="$SIPP -i $LADDR  -p $LPORT -m 1 -inf $TMP_DIR/data_reg.csv $SIPSRVR \
        -sf $SCENARIO_DIR/uac_register.sf \
        -t $TRANSPORT $SIPP_OPT"

    if [ $SHOWCMD -ne 1 ]; then
        $CMD
        if [ "$?" -ne "0" ]; then 
            echo "registeration failed"
            exit
        fi
    else
        echo $CMD
    fi

}


register_uas() {
    CMD="$SIPP -i $LADDR  -p $LPORT $MOPT -inf $TMP_DIR/data_registrar.csv \
        -sf $SCENARIO_DIR/uas_register.sf \
        -t $TRANSPORT $SIPP_OPT" 

    if [ $SHOWCMD -ne 1 ]; then
        $CMD

        if [ "$?" -ne "0" ]; then 
            echo "registeration failed"
            exit
        fi
    else
        echo $CMD
    fi
}


settransport() {
    case $1 in 
        "tcp") TRANSPORT=t1;;
        "udp") TRANSPORT=u1;;
        "tls") TRANSPORT="l1 -tls_cert $SCENARIO_DIR/cacert.pem -tls_key $SCENARIO_DIR/cakey.pem";;
    esac
}


# -------------------------------------
#
#                 MAIN
#
# -------------------------------------

# Process options
while getopts hr:m:u:i:p:d:t:a:oc? option
do
    case "$option" in
        u) USERNAME=$OPTARG
           AUTH_USER=$OPTARG;;
        m) MODE=$OPTARG;;
        i) LADDR=$OPTARG;;
        p) LPORT=$OPTARG;;
        d) SIPSRVR=$OPTARG;;
        t) settransport $OPTARG;;
        a) AUDIO=$OPTARG;;
        o) SIPP_OPT=$OPTARG;;
        c) SHOWCMD=1;;
        h) usage; exit;;
        *) echo "Invalid option" 
           usage
           exit 1;;
    esac
done

verify_options


case "$MODE" in
    uac)
        set_call
        sleep 1
        if [[ "$AUDIO" == "send" ]]; then 
            UACSF="uac_pcap_play.sf"
        elif [[ "$AUDIO" == "recv" ]]; then  
            RTPECHO="-rtp_echo -d 8000"
        fi
        start_uac
        ;;
    uas)
        if [[ "$AUDIO" == "send" ]]; then 
            UASSF="uas_pcap_play.sf"
        elif [[ "$AUDIO" == "recv" ]]; then  
            RTPECHO="-rtp_echo"
        fi
        start_uas
        ;;
    uas_reg)
        set_register_uas
        register_uas
        ;;
    uac_reg)
        set_register_uac
        register_uac
        ;;
esac



