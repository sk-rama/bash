#!/bin/bash

host_name="jsdi01"
domain_name="secar.cz"
system_email="spravce@secar.cz"
postfix_file_main="/etc/postfix/main.cf"
postfix_file_aliases="/etc/aliases"
postfix_file_recipient_canonical="/etc/postfix/hash/recipient_canonical"
postfix_file_sender_canonical="/etc/postfix/hash/sender_canonical"

dollar="$"


aliases_content=$(cat << EOF
@${host_name},,${system_email}
@${host_name}.${domain_name},,${system_email}\n
EOF
)


recipient_canonical_content=$(cat << EOF
@localhost,,${system_email}
@${host_name},,${system_email}
@${host_name}.${domain_name},,${system_email}\n
EOF
)


sender_canonical_content=$(cat << EOF
@localhost,,${host_name}@${domain_name}
@${host_name},,${host_name}@${domain_name}
@${host_name}.${domain_name},,${host_name}@${domain_name}\n
EOF
)


postfix_main_config=$(cat << EOF
# See /usr/share/postfix/main.cf.dist for a commented, more complete version
 
smtpd_banner = ${dollar}myhostname ESMTP
biff = no
 
# appending .domain is the MUA's job.
append_dot_mydomain = no
 
# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h
 
myhostname = ${host_name}.${domain_name}
mydomain = ${dollar}myhostname
myorigin = ${dollar}myhostname
virtual_alias_maps = hash:/etc/aliases
sender_canonical_maps = hash:/etc/postfix/hash/sender_canonical
recipient_canonical_maps = hash:/etc/postfix/hash/recipient_canonical
mydestination =
relayhost = [192.168.221.207]:25
mynetworks = 127.0.0.0/8
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = 127.0.0.1
local_recipient_maps =
 
compatibility_level = 3 
 
smtpd_recipient_restrictions = permit_mynetworks,reject
EOF
)




##
## P O S T F I X
##

$(mkdir -p /etc/postfix/hash)


### change aliases
# create alias file if not exists
$(touch ${postfix_file_aliases})

# clear aliases file
$(cat /dev/null > ${postfix_file_aliases})

# write content to file
temp_aliases=$(printf "${aliases_content}" | column -s ',,' -x -t)
$(echo "${temp_aliases}" > "${postfix_file_aliases}")

# make postmap
$(postmap "${postfix_file_aliases}")



### create canonical maps

# create dir if not exists
$(mkdir -p /etc/postfix/hash)
# create canonical files if not exists
$(touch ${postfix_file_recipient_canonical})
$(touch ${postfix_file_sender_canonical})

# clear canonical files
$(cat /dev/null > ${postfix_file_recipient_canonical})
$(cat /dev/null > ${postfix_file_sender_canonical})

# write content to canonical files
temp_rcpt=$(printf "${recipient_canonical_content}" | column -s ',,' -x -t)
temp_dest=$(printf "${sender_canonical_content}" | column -s ',,' -x -t)
$(echo "${temp_rcpt}" > "${postfix_file_recipient_canonical}")
$(echo "${temp_dest}" > "${postfix_file_sender_canonical}")

# make postmap
$(postmap "${postfix_file_recipient_canonical}")
$(postmap "${postfix_file_sender_canonical}")



### edit /etc/postfix/main.cf file

# clear postfix main.cf file
$(cat /dev/null > ${postfix_file_main})

# write content to file
$(echo "${postfix_main_config}" > "${postfix_file_main}")


### restart postfix daemon
$(systemctl restart postfix.service)
