#!/bin/bash



# Constants
#SIPPDIR="$HOME/workspace/sipp"
SIPPDIR="/home/aawais/workspace/sipp"
SPATH="$SIPPDIR/scripts"
SCENARIOS="$SIPPDIR/scenario"
#SIPP=$SIPPDIR/sipp_ssl
SIPP=sipp
#SIPP_SSL=$SIPPDIR/sipp_ssl
SIPP_SSL=sipp
TMPDIR=/home/aawais/tmp
#TMPDIR=$HOME/tmp

# Configured
USERNAME="1024"
PASSWORD="password"
LPORT=5060
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
SIPP_OPT=""
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
    # echo "  -r <recv|send>        send/receive REGISTER  default:neither" 
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
        -sf $SCENARIOS/$UASSF \
        $RTPECHO"
    [ $SHOWCMD -eq 1 ] && echo $CMD || $CMD
}

start_uac() {
    CMD="$SIPP -i $LADDR -p $LPORT -d 2000 -m 1 -r 17 -inf $TMPDIR/data_call.csv \
        -t $TRANSPORT \
        -sf $SCENARIOS/$UACSF \
        $RTPECHO \
        $SIPP_OPT \
        $EM_ADDR"
    [ $SHOWCMD -eq 1 ] && echo $CMD || $CMD
}


set_call() {
    echo "SEQUENTIAL" > $TMPDIR/data_call.csv
    echo "$USERNAME;$RUSER" >> $TMPDIR/data_call.csv
}


set_register_uac() {
    $SPATH/set_uac_register -d $TMPDIR $USERNAME $PASSWORD 
}

set_register_uas() {
    [ $1 == "1" ] && MOPT="-m 1"
    $SPATH/set_uas_register -d $TMPDIR $PASSWORD 
}



register_uac() {
    CMD="$SIPP_SSL -i $LADDR  -p $LPORT -m 1 -inf $TMPDIR/data_reg.csv $EM_ADDR \
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
    CMD="$SIPP_SSL -i $LADDR  -p $LPORT $MOPT -inf $TMPDIR/data_registrar.csv \
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


settransport() {
    case $1 in 
        "tcp") TRANSPORT=t1;;
        "udp") TRANSPORT=u1;;
        "tls") TRANSPORT="l1 -tls_cert $SCENARIOS/cacert.pem -tls_key $SCENARIOS/cakey.pem";;
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
        d) EM_ADDR=$OPTARG;;
        t) settransport $OPTARG;;
        r) REGISTER=$OPTARG;;
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

#if [ "$REGISTER" == "send" ];then
#    set_register_uac
#    register_uac
#elif [ "$REGISTER" == "recv" ];then
#    set_register_uas 1
#    register_uas
#fi
#

RTPECHO=""
UACSF="uac.sf"

case "$MODE" in
    uac)
        set_call
        sleep 1
        if [[ "$AUDIO" == "send" ]]; then 
            UACSF="uac_pcap_play.sf"
            echo "UACSF set to $UACSF"
        elif [[ "$AUDIO" == "recv" ]]; then  
            RTPECHO="-rtp_echo -d 8000"
            echo "RTPECHO set to $RTPECHO"
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



