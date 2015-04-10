#! /bin/bash

# ----------------------------------------------------------------
# Environment
#

# Edgemarc under test LAN/WAN address
export EM_LAN=`ifconfig eth0 | awk '/^ *inet / {print $2}'`
export EM_WAN=`ifconfig eth1 | awk '/^ *inet / {print $2}'`

# Base ports on 'S' and 'C' interface
export SPORT=5080
export CPORT=5080

# Server Address 
export SADDR=10.10.10.40
export SADDR2=${SADDR%.*}.2
export SADDR3=${SADDR%.*}.3
export SPORT1=$SPORT
export PROXY2_ADDR=10.10.10.149

# Client Address
export CADDR=192.168.1.13
export CADDR2=${CADDR%.*}.2
export CADDR3=${CADDR%.*}.3

export CPORT1=$CPORT
export CPORT2=$((CPORT+10))
export CPORT3=$((CPORT+20))
export CPORT4=$((CPORT+30))




# -----------------------------------------------------------------
# FUNCTIONS 
#

# setvaue file var_name var_value
# ARG1=name of config file
# ARG2=variable name
# ARG3=variable value
setvalue() {
    unset replaced
    if [ -e "$1" ]; then
        replaced=`sudo sed -i "s/^$2=.*$/$2=$3/w /dev/stdout" $1`
    else
        touch "$1"
    fi
    # if name not found and the value is non-NULL then append
    if [[ -z "$replaced"  && -n "$3" ]]; then 
        echo "$2=$3" >> $1
    fi
}



# Mand Config
# -----------
mandconfig () {
    # Parameters
    PROXY_ADR=${1-$SADDR}
    PROXY_PRT=${2-$SPORT1}

    # Permissions
    [ -e sipdptargets ]    && sudo chmod 646 /etc/config/sipdptargets
    [ -e sipdprules ]      && sudo chmod 646 /etc/config/sipdprules
    [ -e sipclients.2 ]    && sudo chmod 646 /etc/config/sipclients.2
    [ -e local_defs.conf ] && sudo chmod 646 /etc/config/local_defs.conf
    [ -e siprouting.conf ] && sudo chmod 646 /etc/config/siprouting.conf

    # Configure the sip-proxy in EM
    sudo sed -i "s/\(SIP_CALLAGENT_IP=\).*$/\1$PROXY_ADR/" alg_defs.conf
    sudo sed -i "s/\(SIP_PORT=\).*$/\1$PROXY_PRT/" alg_defs.conf

    # MAND network
    setvalue intf.conf PRI_WAN_IP $EM_WAN
    setvalue intf.conf PRI_WAN_NETWORK `echo $EM_WAN | sed 's/[0-9]*$/0/'`
    setvalue intf.conf PRI_GATEWAY_IP  `echo $EM_WAN | sed 's/[0-9]*$/1/'`
    setvalue mand.conf private-ip $EM_LAN
    setvalue mand.conf public-ip $EM_WAN
    setvalue mand.conf public-ip6 
    setvalue mand.conf public-netmask 255.255.255.0
    setvalue mand.conf public-gateway "${EM_WAN%.*}.1"
    setvalue mand.conf landevice eth0
    setvalue mand.conf wandevice eth1
    setvalue mand.conf max-wan-rtp

    # Reset the files that we will be modifying
    cat /dev/null > sipdptargets
    cat /dev/null > sipdprules
    cat /dev/null > sipclients.2
    sudo rm -f b2bua2.conf
    sudo rm -f b2bua.conf
    sudo rm -f siprouting.conf

    setvalue alg_defs.conf SIP_USE_INBOUND_PROXIES off
    setvalue alg_defs.conf SIP_USE_ALLOWED_PROXIES off
    setvalue alg_defs.conf SIP_TRANSPARENT off
    setvalue alg_defs.conf SIP_MULTIHOME off
    setvalue alg_defs.conf SIP_SERVER_TRANSPORT 0
    setvalue alg_defs.conf ENABLE_ADVANCED_SIP off
    setvalue alg_defs.conf SIP_STALE_TIME 2440
    setvalue alg_defs.conf CONTACT_HDR_TXT 
    setvalue alg_defs.conf ALG_LOCKDOWN off
    setvalue alg_defs.conf SIP_EXP_ENABLE off
    setvalue alg_defs.conf SIP_SS_EXP_ENABLE off
    setvalue alg_defs.conf SIP_TRANSPARENT_REDUNDANCY off

    setvalue local_defs.conf SIP_PROXY_DOMAIN
    setvalue local_defs.conf OPTIONS_USER
    setvalue local_defs.conf LOCAL_MODE NORMAL
    setvalue local_defs.conf SUBSCRIBER_INFO off
    setvalue local_defs.conf ACTIVE_MONITOR 0
    sed -i '/DID_PARSE_RULE_.*/d' local_defs.conf
    sudo sed -i "s/SIP_PROXY=.*//" local_defs.conf # list of sip proxies

    setvalue ts_defs.conf  DANGL_RTP_TO 600
    setvalue ts_defs.conf  ENABLE_CAC off 

    # Remove RTP port range
    sudo sed -i "/^ALG_PRANGE_[A-Z]\+=.*/d" alg_defs.conf

    rm -f lastruleid.txt
    rm -f lasttargetid.txt
    unset TARGET_ID

    # SIPUA config reset
    sipuareset

    # SIP GW reset
    setvalue sipgw_defs.conf ENABLE_SIPGW off
    setvalue sipgw_defs.conf SIPGW_VIRTUAL_IP
    setvalue sipgw_pri_defs.conf ENABLE_SIPGW_PRI off
 
    # Turn off Test UA
    setvalue fxvua_defs.conf ENABLE_FXVUA off

    # Turn off High-Availability
    setvalue failover_defs.conf FAIL_ENABLE off
}


mandserverlst () {
    sed -i "/SIP_PROXY_DOMAIN/d" local_defs.conf
    sed -i "/SIP_PROXY/d" local_defs.conf
    echo "SIP_PROXY_DOMAIN=$1">> local_defs.conf
    echo "SIP_PROXY=$SADDR:$SPORT1" >> local_defs.conf
}

#
# create mand client list entry
# ARG1=DID
# ARG2=PORT or IP:PORT
# ARG3=TRANPORT
#
mandclient () {
    if [ -z "${2//[0-9]/}" ]; then
        PORT=${2:-5060}
        IP=$CADDR
    else
        IP=${2%:*}
        if [ $"{2:${#IP}:1}" = ":" ]; then
            PORT=${2##*:}
        else 
            PORT=5060
        fi
    fi
    case "$3" in
        "udp") trp=0;;
        "tcp") trp=1;;
        "tls") trp=2;;
        *) trp=0;;
    esac
    echo "* $IP $PORT $1 uri=sip:$1@$IP:$PORT ndm=1 user=$1 nat=0 trn=0 trp=$trp blaport=5060" >> sipclients.2
}




# Just add a target
# ARG1=Target-Address 
# ARG2=Target-Port 
# n=name
# m=members
# i=internal
trunktarget() {
    TGT_ID=$(date +%N | sed 's/^0*//')
    sudo echo "* $TGT_ID $*" >> /etc/config/sipdptargets
    echo "LAST_TARGET_ID=$TGT_ID" > lasttargetid.txt
    echo $TGT_ID
}




# Type         [io] (0:inbound, 1:outbound, 2:redirect 3:inbound-target) 
# Party        [p]  (0:called, 1:calling)
# Default      [d]  (1:default)
# AddString    [a]  (the string to add)
# StriprDigits [s]  (number of digits to strip from left)
# B2BUA        [b]  (0:don't use, 1:use)
# Pattern      [r]       
addrule() {
    if [ -e "lasttargetid.txt" ]
    then
        . lasttargetid.txt
    fi
    if [ -e "lastruleid.txt" ]
    then
        . lastruleid.txt
        if [ -n "$LAST_RULE_ID" ]
        then
            RID=$((LAST_RULE_ID+1))
        fi
    fi
    TGT_ID=${TARGET_ID:-$LAST_TARGET_ID}
    if [ -z "$TGT_ID" ]
    then
        echo "ERROR: No Target id"
        return
    fi

    RULE_ID=${RID:-$(date +%s)}
    echo "LAST_RULE_ID=$RULE_ID" > lastruleid.txt
    REDIR=${REDIR:-'>'}
    eval sudo echo "\* $RULE_ID $TGT_ID $*" $REDIR /etc/config/sipdprules
}


appendrule() {
    export REDIR=">>"
    addrule $*
    export REDIR=">"
}




#
# b2bua config
# ARG1=Refer2ReInvite[rr]           (0:no 1:yes)
# ARG2=Invite Authentication[ia]    (0:no 1:yes)
# ARG3=contacts[c]                  sip:user1@domain1+sip:user2@domain2+... 
#                                   user=ss:Use the to from the original INVITE
#                                   domain=locadomain: Send to softswitch
#
b2buaconf() {
    if [ -e lastruleid.txt ]
    then
        . lastruleid.txt
    fi

#    conts=""
#    if [ $3 != "x" ]
#    then
#        conts="c=$3"
#    fi
    if [ $RULE_ID == "" ]
    then
        RULE_ID=$(date +%s)
    fi
    sudo echo "* 1$RULE_ID $*" >> b2bua2.conf 
}




#
# B2BUA in 8.8 branch config
#
b2bua88_config() {
    echo "* $CADDR $CPORT1 1024 uri=sip:1024@$CADDR:$CPORT;transport=udp ndm=1 user=1024 nat=0 trn=0 b2bua=17" > sipclients.2
    echo "* 1" > b2bua.conf
}

#
# A target with b=1 set. So that a WAN call will be sent to B2BUA
b2bua88_target_config() {
    echo "* $CADDR $CPORT1 1024 uri=sip:1024@$CADDR:$CPORT;transport=udp ndm=1 user=1024 nat=0 trn=0 b2bua=17" > sipclients.2
    echo "* 1" > b2bua.conf
}




# Configure the sip-proxy in EM
# $1 = sip proxy address
# $2 = sip proxy port
sipproxy() {
    sudo sed -i "s/\(SIP_CALLAGENT_IP=\).*$/\1$1/" alg_defs.conf
    sudo sed -i "s/\(SIP_PORT=\).*$/\1$2/" alg_defs.conf
}




# Configure the SIP UA
# arguments are the port dids
# $1 = Address of UA
# $2 = Register off or on
# $3 ... = dids for each port
sipuaconf() {
    sudo chmod 666 sipua_defs.conf
    if [ -e /var/ewn_model ]; then
        source /var/ewn_model
    fi

    maxport=0

    setvalue sipua_defs.conf SIPUA_VIRTUAL_IP $1
    setvalue sipua_defs.conf ENABLE_SIPUA on
    setvalue sipua_defs.conf ENABLE_REGISTER $2
    shift 2

    i=0
    while [ $i -lt  $MODEL_FXS_PORTS ]
    do
        setvalue sipua_defs.conf SIPUA_USER_NAME$i $1
        setvalue sipua_defs.conf SIPUA_DISP_NAME$i $1
        setvalue sipua_defs.conf SIPUA_USER_AUTH_NAME$i $1
        if [ -n "$1" ]
        then
            let "maxport+=1"
        fi
        let "i+=1"
        shift
    done

    setvalue sipua_defs.conf SIPUA_MAX_PORT $maxport
}



# Clear settings created by sipuaconf
sipuareset() {
    if [ ! -e sipua_defs.conf ]; then
        return 1
    fi

    MODEL_FXS_PORTS=0
    if [ -e /var/ewn_model ]; then
        source /var/ewn_model
    fi

    setvalue sipua_defs.conf SIPUA_VIRTUAL_IP 
    setvalue sipua_defs.conf ENABLE_SIPUA off
    setvalue sipua_defs.conf ENABLE_REGISTER off
    setvalue sipua_defs.conf SIPUA_MAX_PORT 0

    #Reset extended huntgroups
    setvalue sipua_defs.conf B2BUA_ID 
    setvalue sipua_defs.conf SIPUA_HUNT_MODE_ENABLE off
    setvalue sipua_defs.conf SIPUA_HUNT_MODE_ENABLE0 off
    setvalue sipua_defs.conf SIPUA_CONTACT_LST_VALUE
    setvalue sipua_defs.conf SIPUA_HUNT_USER_INDEX 
    sudo sh -c 'echo "MODEL_FXS_PORTS=0" >> /var/ewn_model'


    i=0
    while [ $i -lt  $MODEL_FXS_PORTS ]
    do
        setvalue sipua_defs.conf SIPUA_USER_NAME$i
        setvalue sipua_defs.conf SIPUA_DISP_NAME$i
        setvalue sipua_defs.conf SIPUA_USER_AUTH_NAME$i
        let "i+=1"
    done

    # Reset PRI net
    setvalue sipua_pri_defs.conf ENABLE_SIPUA_PRI off
}


