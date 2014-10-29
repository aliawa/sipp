BEGIN{
   n = split("0 6 12 24 0 0 6 12 24 24 24 0 6 12 24 21 14 28 1 1 2 4 4 4 4 4 4 4 6 1 1 2 4 4 4 4 4 4 4 12", reftimes) 
   line=1
   printf "%5s %5s %11s \n",  "#", "delay", "reference"
   printf "%5s %5s %11s \n",  "-----", "-----", "----------" 
}

NR>=43 {
    # only process first 40 lines after the 2 header lines
    exit
}


{
    if ( strtonum($2) == 0){
        # skip this line
        next
    }

    if (prev == 0){
        # first entry
        prev=$2
    }
    delay= $2-prev

    errorStr="";
    
    # Check delay
    if (delay > reftimes[line]+1 || delay < reftimes[line]-1) {
        errorStr ="delay";
    }
    if ((line <= 11  && $3 != 3600) || (line > 11 && $3 != 20)) {
        errorStr="expires";
    }

    if ( length(errorStr) ) {
        errorStr = "error " errorStr;
    }

    printf "%5d %5d %10d %s\n",  line, delay, reftimes[line], errorStr
    line++;
    prev=$2
}



