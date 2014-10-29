BEGIN {
   line=1
   delay_expected=0;
   expires_expected=0;
   time_prev=0;

   print
   printf "%-5s %-16s %-17s \n",  "After", "|Delay", "|Expires"
   printf "%-5s %-5s %-8s %-5s %-8s \n",  " ", "|Actual","Expected","|Actual","Expected"
   for (i=0;i<40;++i){
       printf "-"
   }
   print
}


{
    if ( strtonum($2) == 0){
        # skip this line
        next
    }

    if (time_prev != 0){
        delay = $2-time_prev;

        # Check errors
        errorStr=""
        if (delay > delay_expected+1 || delay < delay_expected-1) {
            errorStr="error"
        }
        if ($3 != expires_expected){
            errorStr="error"
        }

        printf "%5d | %5d %8d | %5d %8d %8s\n", resp, delay, delay_expected, $3, expires_expected, errorStr
    }

    resp=substr($1,0,3)
    time_prev=$2
    delay_expected=$4
    expires_expected=$5
    line++;
}



