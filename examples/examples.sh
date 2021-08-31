# run commands parallel with 4 forkings and 1000 times
time seq 1 10000 | xargs -I{} -P4 sh -c 'echo "{}" | nc 192.168.221.54 9999 > /dev/null'
