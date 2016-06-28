#!/bin/bash


SIPPDIR="$HOME/workspace/sipp"
SPATH="$SIPPDIR/scripts"
SCENARIOS="$SIPPDIR/scenario"
SIPP=$SIPPDIR/sipp_ssl
SIPP_SSL=$SIPPDIR/sipp_ssl

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
UACSF="uac.sf"

usage()
{
    echo 
    echo "Usage as UAS:"
    echo "  $(basename $0) -m uas -i <local-ip> [options]"
    echo "Usage as UAC:"
    echo "  $(basename $0) -m uac -i <local-ip> -d <remote-ip[:port]> [options]"
    echo
    echo "OPTIONS:"
    echo "  -p <local-port>       default: $LPORT"
    echo "  -r <recv|send>        send/receive REGISTER  default:neither" 
    echo "  -t <tcp|udp>          default: udp"
    echo "  -u <local-user>       default: 1024"
    echo "  -r <remote-user>      default: 1028"
    echo "  -a                    send/echo rtp"
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
    $SIPP -i $LADDR -p $LPORT \
        -t $TRANSPORT $RTP \
        -sf $SCENARIOS/uas.sf
}


start_uac() {
    $SIPP -i $LADDR -p $LPORT -d 2000 -m 1 -r 17 -inf data_call.csv \
        -t $TRANSPORT \
        -sf $SCENARIOS/$UACSF \
        $EM_ADDR
}


set_call() {
    echo "SEQUENTIAL" > data_call.csv
    echo "$USERNAME;$RUSER" >> data_call.csv
}


set_register_uac() {
    $SPATH/set_uac_register $USERNAME $PASSWORD $RPROT
}

set_register_uas() {
    $SPATH/set_uas_register $PASSWORD 
}



register_uac() {
    $SIPP_SSL -i $LADDR  -p $LPORT -m 1 -inf data_reg.csv $EM_ADDR \
        -sf $SCENARIOS/uac_register.sf \
        -t $TRANSPORT

    if [ "$?" -ne "0" ]; then 
        echo "registeration failed"
        exit
    fi

}


register_uas() {
    $SIPP_SSL -i $LADDR  -p $LPORT -m 1 -inf data_registrar.csv \
        -sf $SCENARIOS/uas_register.sf \
        -t $TRANSPORT

    if [ "$?" -ne "0" ]; then 
        echo "registeration failed"
        exit
    fi
}



# -------------------------------------
#
#                 MAIN
#
# -------------------------------------

# Process options
while getopts hr:m:u:i:p:d:r:t:a? option
do
    case "$option" in
        u) USERNAME=$OPTARG
           AUTH_USER=$OPTARG;;
        m) MODE=$OPTARG;;
        i) LADDR=$OPTARG;;
        p) LPORT=$OPTARG;;
        v) RUSER=$OPTARG;;
        d) EM_ADDR=$OPTARG;;
        o) RPROT=$OPTARG;;
        t) [ "$OPTARG" == "tcp" ] && TRANSPORT="t1" ;;
        r) REGISTER=$OPTARG;;
        a) RTPECHO="-rtpecho"; UACSF="uac_pcap_play.sf" ;;
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
    set_register_uas
    register_uas
fi


set_call

if [[ "$MODE" == "uac" ]]; then
    sleep 1
    start_uac
elif [[ "$MODE" == "uas" ]]; then
    start_uas
fi



