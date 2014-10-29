$SIPP_BIN -i $CADDR -p $CPORT1 -sf uas_reinvite_4xx.sf -bg
$SIPP_BIN -i $SADDR -p $SPORT2 -m 1 -inf data_call.csv  $EM_WAN -3pcc 127.0.0.1:30000 -sf uac_reinvite_slave.sf -nd -bg
$SIPP_BIN -i $SADDR -p $SPORT1 -d 30000 -m 1 -inf data_call.csv  $EM_WAN -3pcc 127.0.0.1:30000 -sf uac_reinvite_master.sf -bg
wait

