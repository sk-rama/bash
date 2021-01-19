# README.md
---

This script parse postfix mail log in arg ```_arg_log_file_fullpath``` and find all lines with failed SASL login like this:

```
Oct 22 11:20:56 fw2 postfix/smtpd[2556]: warning: unknown[141.98.10.136]: SASL LOGIN authentication failed: authentication failure
Oct 22 09:31:34 fw2 postfix/smtpd[8259]: warning: unknown[61.132.87.130]: SASL PLAIN authentication failed: authentication failure
Oct 22 09:31:34 fw2 postfix/smtpd[8259]: warning: SASL authentication failure: Password verification failed
```

Than script extract all ip addresess from all such lines, count unique ip addresses and process only ip's that exceed treshold value in ```_arg_attempts```. That ip's are added to netfilter ipset with name ```_arg_ipset_name```.

**Arguments and default values:**
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

**example**

```bash
ip_to_ipset_postfix.sh --log-file-fullpath=/var/log/mail/mail.log --ipset-name=postfix --timeout=3600 --attempts=200 --script-log=/var/log/mail/ip_to_ipset_postfix.log
```

This script:

 * parse log file ```/var/log/mail/mail.log```
 * add parsed ip addresses to netfilter ipset with name ```postfix```
 * add to ipset postfix with time ```3600``` seconds - after this time is ip automatically deleted from ipset
   * On older linxu system is maximum ipset time argument 4294967 seconds
 * ip must have 200 failed attempts
 * output log file for this script is ```/var/log/mail/ip_to_ipset_postfix.log``` file

You can add ```_arg_ipset_timeout``` parameter to this script. This is a default ipset timout parameter when is ipset created. When you set ```_arg_clear_postfix_log_file``` boolean parameter, postfix log file in ```_arg_log_file_fullpath``` is cleared after script end. Default is not use this parameter (log file is untouched).

```bash
./ip_to_ipset_postfix.sh --help
The general script's help msg
Usage: ./ip_to_ipset_postfix.sh [-l|--log-file-fullpath <arg>] [-n|--ipset-name <arg>] [-i|--ipset-timeout <arg>] [-t|--timeout <arg>] [-a|--attempts <arg>] [-s|--script-log <arg>] [-c|--(no-)clear-postfix-log-file] [-v|--version] [-h|--help]
        -l, --log-file-fullpath: Full Path To Postfix Log File (default: '/var/log/mail/mail-ipset.log')
        -n, --ipset-name: IPSET Name (default: 'postfix')
        -i, --ipset-timeout: Default timeout (in seconds) for created ipset - default 49 days (default: '4294967')
        -t, --timeout: How long (in seconds) ip address will be in ipset (default: '3600')
        -a, --attempts: How Many Attempts are Allowed (default: '20')
        -s, --script-log: Full Path To This Script Log File (default: '/var/log/mail/ip_to_ipset_postfix.log')
        -c, --clear-postfix-log-file, --no-clear-postfix-log-file: on/off - clear postfix log file (off by default)
        -v, --version: Prints version
        -h, --help: Prints help
``` 

You can start this script from crontab file:

```bash
*/5 *    * * *   root    ( /etc/rc-local/skripty/ip_to_ipset_postfix/ip_to_ipset_postfix.sh --log-file-fullpath=/var/log/mail/mail-ipset.log --ipset-name=postfix --timeout=3600 --attempts=20 --script-log=/var/log/mail/ip_to_ipset_postfix.log --clear-postfix-log-file > /dev/null 2>&1 )

8 */2    * * *   root    ( /etc/rc-local/skripty/ip_to_ipset_postfix/ip_to_ipset_postfix.sh --log-file-fullpath=/var/log/mail/mail.log --ipset-name=postfix --timeout=3600 --attempts=200 --script-log=/var/log/mail/ip_to_ipset_postfix.log > /dev/null 2>&1 )
```
