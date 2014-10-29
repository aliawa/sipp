#!/bin/bash


../sipp -i $SADDR -p $SPORT2 -m 1 -sf  uas_invite_only.sf
sleep 1
../sipp -i $SADDR -p $SPORT2  -sf  uas.sf


