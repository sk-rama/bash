#/bin/bash

# SECONDS is a bash special variable that returns the seconds since set.
SECONDS=0

function ProgressBar {
    # Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    # Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1 Progress : [########################################] 100%
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%% "
}

# Variables
_start=1

# This accounts as the "totalState" variable for the ProgressBar function
_end=100

# Proof of concept
for number in $(seq ${_start} ${_end})
do
    sleep 0.1
    ProgressBar ${number} ${_end}
done
printf '\nFinished!\n'


# real example:
# for (( start=1; start<=(end=500); start++ ))
# do
#     output=$(echo "aaafdasfwqertfsdafgdfgterqeqrfqsfadsafgads" | nc 127.0.0.1 9999)
#     ProgressBar ${start} ${end} 
# done

# echo "program was run $SECONDS seconds"
