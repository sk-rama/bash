# README.md
---

This script parse postfix mail log and find all lines with failed SASL login like this:

Oct 22 11:20:56 fw2 postfix/smtpd[22556]: warning: unknown[141.98.10.136]: SASL LOGIN authentication failed: authentication failure

Than script extract all ip addresess from all such lines, count unique ip addresses and process only ip's that exceed treshold value. That ip's are added to netfilter ipset with given name.

Arguments:
```bash
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_log_file_fullpath="/var/log/mail/mail-ipset.log"
_arg_ipset_name="postfix"
_arg_ipset_timeout="4294967"
_arg_timeout="3600"
_arg_attempts="20"
_arg_script_log="/var/log/mail/ip_to_ipset_postfix.log"
_arg_clear_postfix_log_file="off"
```
