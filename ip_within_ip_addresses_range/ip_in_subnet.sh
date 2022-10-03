#! /bin/bash

# Set DEBUG=1, in order to see it iterate through the calculations.
# DEBUG=1

MAXCDN_ARRAY="192.168.0.0/24 192.168.0.0/16 192.168.1.0/24 172.16.32.0/16"

IP=192.168.0.5

function in_subnet {
    # Determine whether IP address is in the specified subnet.
    #
    # Args:
    #   sub: Subnet, in CIDR notation.
    #   ip: IP address to check.
    #
    # Returns:
    #   1|0
    #
    local ip ip_a mask netmask sub sub_ip rval start end

    # Define bitmask.
    local readonly BITMASK=0xFFFFFFFF

    # Set DEBUG status if not already defined in the script.
    [[ "${DEBUG}" == "" ]] && DEBUG=0

    # Read arguments.
    IFS=/ read sub mask <<< "${1}"
    IFS=. read -a sub_ip <<< "${sub}"
    IFS=. read -a ip_a <<< "${2}"

    # Calculate netmask.
    netmask=$(($BITMASK<<$((32-$mask)) & $BITMASK))

    # Determine address range.
    start=0
    for o in "${sub_ip[@]}"
    do
        start=$(($start<<8 | $o))
    done

    start=$(($start & $netmask))
    end=$(($start | ~$netmask & $BITMASK))

    # Convert IP address to 32-bit number.
    ip=0
    for o in "${ip_a[@]}"
    do
        ip=$(($ip<<8 | $o))
    done

    # Determine if IP in range.
    (( $ip >= $start )) && (( $ip <= $end )) && rval=1 || rval=0

    (( $DEBUG )) &&
        printf "ip=0x%08X; start=0x%08X; end=0x%08X; in_subnet=%u\n" $ip $start $end $rval 1>&2

    echo "${rval}"
}


echo "We use own function for ip in ip range"
for subnet in $MAXCDN_ARRAY
do
    if [[ $(in_subnet $subnet $IP) -eq 1 ]]
        then
            echo "${IP} is in ${subnet}"
        else
            echo "${IP} is not in ${subnet}"
    fi
done


echo "we use a grepcdir for ip in ip range"
for subnet in $MAXCDN_ARRAY
do
    # grepcidr 192.168.1.0/24 <(echo "192.168.1.1")
    output_grepcidr=$( grepcidr ${subnet} <(echo ${IP}) )
    if [[ ${output_grepcidr} = ${IP} ]]
        then
            echo "${IP} is in ${subnet}"
        else
            echo "${IP} is not in ${subnet}"
    fi
done
