#! /bin/sh

i=0

while [ "$i" -lt 100 ]
do 
	echo call $i
	port=$((5060+i))
	audio_port=$((9000+3*i))
	../sipp -i 192.168.1.152 -inf ~/tmp/call$i.csv -m 1 -d 30000 \
	-sf uac_uses_csv.sf -t t1 -r 10 -l 10 -trace_err -bg \
	 -mp $audio_port -p $port 192.168.1.190
	i=$((i+1))
done
