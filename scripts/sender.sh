#! /bin/sh

i=0
while true
do
	datafile=$(printf "call%03d.data" $i)
	if [ ! -e $datafile ] 
	then
		exit
	fi

	port=$(sed -n '2p' $datafile| cut -d\; -f2)
	audio_port=$((9000+3*i))

	echo call $i
	../sipp -i 192.168.1.152 -m 1 -inf $datafile -sf uac_uses_csv_1.sf -t t1 -bg -p $port -mp $audio_port  192.168.1.231 -trace_screen
	i=$((i+1))
done


