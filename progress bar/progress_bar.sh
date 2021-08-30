#/bin/bash

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

for (( c=1; c<=(end=500); c++ ))
do
    output=$(echo "aaafdasfwqertfsdafgdfgterqeqrfqsfadsafgads" | nc 127.0.0.1 9999)
    ProgressBar ${c} ${end} 
done

echo "program was run $SECONDS seconds"
