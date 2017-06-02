#!/bin/bash

# Constants
SIPPDIR="$HOME/workspace/sipp"
SPATH="$SIPPDIR/scripts"
SCENARIOS="$SIPPDIR/scenario"
SIPP=$SIPPDIR/sipp_ssl
SIPP_SSL=$SIPPDIR/sipp_ssl
SIPP_OPT=""

# Configured
USERNAME="1024"
PASSWORD="password"
LPORT=5060
RPROT=5060
EXPIRES=3600
AUTH_USER=$USERNAME
RUSER="1028"
TRANSPORT="u1"
MODE=
REGISTER=
LADDR=
EM_ADDR=
RTPECHO=""
SHOWCMD=0

# Internal
UACSF="uac.sf"
MOPT=""


usage()
{
    echo 
    echo "Usage as UAS:"
    echo "  $(basename $0) -m uas|reg -i <local-ip> [options]"
    echo "Usage as UAC:"
    echo "  $(basename $0) -m uac -i <local-ip> -d <remote-ip[:port]> [options]"
    echo
    echo "OPTIONS:"
    echo "  -p <local-port>       default: $LPORT"
    echo "  -r <recv|send>        send/receive REGISTER  default:neither" 
    echo "  -t <tcp|udp>          default: udp"
    echo "  -a                    send/echo rtp"
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

    if [[ -n "$REGISTER" ]]; then
        if [[ "$REGISTER" != "send" && "$REGISTER" != "recv" ]]; then
            echo "Invalid register option"
            usage
            exit 1
        fi
    fi

    if [[ "$REGISTER" == "send" || "$MODE" == "uac" ]]; then
        if [[ -z $EM_ADDR ]]; then
            echo "Remote address must be provided with register send"
            echo "or UAC"
            exit
        fi
    fi
}




start_uas() {
    CMD="$SIPP -i $LADDR -p $LPORT \
        -t $TRANSPORT $RTP \
        $SIPP_OPT \
        -sf $SCENARIOS/uas.sf \
        $RTPECHO"
    [ $SHOWCMD -eq 1 ] && echo $CMD || $CMD
}

start_uac() {
    CMD="$SIPP -i $LADDR -p $LPORT -d 2000 -m 1 -r 17 -inf data_call.csv \
        -t $TRANSPORT \
        -sf $SCENARIOS/$UACSF $SIPP_OPT \
        $EM_ADDR"
    [ $SHOWCMD -eq 1 ] && echo $CMD || $CMD
}


set_call() {
    echo "SEQUENTIAL" > data_call.csv
    echo "$USERNAME;$RUSER" >> data_call.csv
}


set_register_uac() {
    $SPATH/set_uac_register $USERNAME $PASSWORD $RPROT
}

set_register_uas() {
    [ $1 == "1" ] && MOPT="-m 1"
    $SPATH/set_uas_register $PASSWORD 
}



register_uac() {
    CMD="$SIPP_SSL -i $LADDR  -p $LPORT -m 1 -inf data_reg.csv $EM_ADDR \
        -sf $SCENARIOS/uac_register.sf \
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
    CMD="$SIPP_SSL -i $LADDR  -p $LPORT $MOPT -inf data_registrar.csv \
        -sf $SCENARIOS/uas_register.sf \
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



# -------------------------------------
#
#                 MAIN
#
# -------------------------------------

# Process options
while getopts hr:m:u:i:p:d:t:aoc? option
do
    case "$option" in
        u) USERNAME=$OPTARG
           AUTH_USER=$OPTARG;;
        m) MODE=$OPTARG;;
        i) LADDR=$OPTARG;;
        p) LPORT=$OPTARG;;
        d) EM_ADDR=$OPTARG;;
        t) [ "$OPTARG" == "tcp" ] && TRANSPORT="t1" ;;
        r) REGISTER=$OPTARG;;
        a) RTPECHO="-rtp_echo"; UACSF="uac_pcap_play.sf" ;;
        o) SIPP_OPT=$OPTARG;;
        c) SHOWCMD=1;;
        h) usage; exit;;
        *) echo "Invalid option" 
           usage
           exit 1;;
    esac
done

verify_options

if [ "$REGISTER" == "send" ];then
    set_register_uac
    register_uac
elif [ "$REGISTER" == "recv" ];then
    set_register_uas 1
    register_uas
fi



if [[ "$MODE" == "uac" ]]; then
    set_call
    sleep 1
    start_uac
elif [[ "$MODE" == "uas" ]]; then
    start_uas
elif [[ "$MODE" == "reg" ]]; then
    set_register_uas
    register_uas
fi



