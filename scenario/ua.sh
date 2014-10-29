#!/bin/bash



SIPP=../sipp
SIPP_SSL=../sipp_ssl
USERNAME=
PASSWORD="password"
LADDR=
LPORT=
EXPIRES=3600
AUTH_USER=
RUSER=
EM_ADDR=
TRANSPORT=u1
MODE=


usage()
{
    echo "Usage:"
    echo "$(basename $0) -m uac -u <local-user> -i <local-address> -p <local-port> -r <remote-user> -d <remote_address>"
    echo "$(basename $0) -m uas -u <local-user> -i <local-address> -p <local-port> -d <remote_address>"
    echo
}


verify_options() {
    if [[ -z "$LADDR" || -z "$LPORT" || -z "$USERNAME" || -z "$EM_ADDR" ]]; then
        echo "mandatory parameter missing"
        usage
        exit 1
    fi
    
    if [[ "$MODE" == "uac" ]]; then
       if [[ -z "$RUSER" ]];then
           echo "remote-user is required in uac mode"
           usage
           exit 1
       fi
   fi

   if [[ "$MODE" != "uac"  && "$MODE" != "uas" ]]; then
       echo "$MODE in not a valid mode"
       usage
       exit 1
   fi
}




function start_uas() {
    $SIPP -i $LADDR -p $LPORT -sf uas_reinvite_sender_agent_check.sf
}


function start_uac() {
    $SIPP -i $LADDR -p $LPORT -d 2000 -m 1 -r 17 -inf data_call.csv $EM_ADDR \
        -t $TRANSPORT \
        -sf uac_reinvite_receiver.sf
}


function set_call() {
    echo "SEQUENTIAL" > data_call.csv
    echo "$USERNAME;$RUSER" >> data_call.csv
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





# -------------------------------------
#
#                 MAIN
#
# -------------------------------------

# Process options
while getopts m:u:i:p:d:r:? option
do
    case "$option" in
        u) USERNAME=$OPTARG
           AUTH_USER=$OPTARG;;
        m) MODE=$OPTARG;;
        i) LADDR=$OPTARG;;
        p) LPORT=$OPTARG;;
        r) RUSER=$OPTARG;;
        d) EM_ADDR=$OPTARG;;
        *) echo "Invalid option" 
           usage
           exit 1;;
    esac
done

verify_options
set_register_uac
register_uac
sleep 1
set_call

if [[ "$MODE" == "uac" ]]; then
    start_uac
else
    start_uas
fi



