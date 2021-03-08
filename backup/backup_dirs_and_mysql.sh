#!/bin/bash

# save IFS variable
OLD_IFS=$IFS

# parametre pre adresar kam, sa bude zalohovat na lokalnom stroji
#-------------------------------------------------------------------------------------------------#
NAZOV_SERVRA='kj-radius-czech-tmobile'
IP='192.168.221.105'
#ZALOHOVANE_ADRESARE_ZOZNAM='/etc :/var/cache/bind'
ZALOHOVANE_ADRESARE_ZOZNAM='/etc /opt'
TAR_EXCLUDE="'/var/cache/bind/named.stats' '/tmp/*'"
DNESNY_DATUM=`date --rfc-3339=date`
ZALOHOVACI_ADRESAR_LOCAL='/var/backup'
ADRESAR_NA_TUTO_ZALOHU="$ZALOHOVACI_ADRESAR_LOCAL/$DNESNY_DATUM/$NAZOV_SERVRA"
LOG_FILE=$ADRESAR_NA_TUTO_ZALOHU/$NAZOV_SERVRA.log
SECONDS=0
#-------------------------------------------------------------------------------------------------#

# parametre pre ododslanie emailu
#-------------------------------------------------------------------------------------------------#
mail_to=rama@secar.cz
mail_from=manak@sherlog.cz
export smtp="127.0.0.1:25"
subject_dir_ok="$NAZOV_SERVRA dirs backup successful"
message_dir_ok="$NAZOV_SERVRA dirs backup successful"
subject_dir_err="!!! ERROR DIR BACKUP !!! - $NAZOV_SERVRA"
message_dir_err="!!! ERROR DIR BACKUP !!! - $NAZOV_SERVRA"
subject_sql_ok="$NAZOV_SERVRA MYSQL backup successful"
message_sql_ok="$NAZOV_SERVRA MYSQL backup successful"
subject_sql_err="!!! ERROR SQL BACKUP !!! - $NAZOV_SERVRA"
message_sql_err="!!! ERROR SQL BACKUP !!! - $NAZOV_SERVRA"

# parametre pre rsync a ssh - vacsinou uz netreba upravovat
#-------------------------------------------------------------------------------------------------#
SSH_USERNAME='rrastik'
SSH_PRIVATE_KEY_FILE='/home/rrastik/.ssh/id_rsa'
#RSYNC_COMMAND_WITH_PARAMETERS="rsync -arl -e \"ssh -i $SSH_PRIVATE_KEY_FILE\" $SSH_USERNAME@$IP:$ZALOHOVANE_ADRESARE_ZOZNAM $ADRESAR_NA_TUTO_ZALOHU" 
#TAR_COMMAND="tar -C $ADRESAR_NA_TUTO_ZALOHU -czf $ZALOHOVACI_ADRESAR_LOCAL/$DNESNY_DATUM/$NAZOV_SERVRA.tar ."  
#COPY_CMD="ssh -i $SSH_PRIVATE_KEY_FILE $SSH_USERNAME@$IP tar --ignore-failed-read -v -czf - $ZALOHOVANE_ADRESARE_ZOZNAM > $ADRESAR_NA_TUTO_ZALOHU/$NAZOV_SERVRA.tgz"
#-------------------------------------------------------------------------------------------------#

# parametre pre mysql
#-------------------------------------------------------------------------------------------------#
mysql_dump='false'
mysql_user='--user=root'
mysql_pass='--password='
mysql_host='--host=localhost'
mysql_prog='/usr/bin/mysql'
mysql_shdb='show databases'
mysqldump_prog='/usr/bin/mysqldump'
#-------------------------------------------------------------------------------------------------#

function make_tar_exclude(){
  local exclude_string=
  for exclude in $TAR_EXCLUDE; do
    local my_var=$(echo "$exclude" | sed 's/\(.*\)/--exclude=\1 /')
    exclude_string+="$my_var"
  done
  echo "ssh -i $SSH_PRIVATE_KEY_FILE $SSH_USERNAME@$IP tar --ignore-failed-read $exclude_string -v -czf - $ZALOHOVANE_ADRESARE_ZOZNAM > $ADRESAR_NA_TUTO_ZALOHU/$NAZOV_SERVRA.tgz"
}

# Check for dir on backup, if not found create it using the mkdir ##
[ ! -d "$ADRESAR_NA_TUTO_ZALOHU" ] && mkdir -p "$ADRESAR_NA_TUTO_ZALOHU" | tee -a $LOG_FILE
echo -e "$(date)\t Directory $ADRESAR_NA_TUTO_ZALOHU was created" 2>&1 | tee -a $LOG_FILE

# zapisu,kdy zacal skript
echo -e "$(date)\t Starting program at: $(date)" 2>&1 | tee -a $LOG_FILE

# start of directory backups backup
echo -e "$(date)\t I will backup directories: $ZALOHOVANE_ADRESARE_ZOZNAM" 2>&1 | tee -a $LOG_FILE
echo -en "$(date)\t command started:\t" 2>&1 | tee -a $LOG_FILE; make_tar_exclude 2>&1 | tee -a $LOG_FILE
echo -e "\n$(date)"; echo -e "$(date)\t Output from previous command:" 2>&1 | tee -a $LOG_FILE
eval $(make_tar_exclude) 2>&1 | tee -a $LOG_FILE 

if [[ ${PIPESTATUS[0]} == 0 ]]; then
    echo -e "$message_dir_ok\nElapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec" | mailx -s "$subject_dir_ok" -r $mail_from $mail_to;
else
    echo -e "$message_dir_err" | mailx -s "$subject_dir_err" -r $mail_from $mail_to;
fi

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "$(date)\t Elapsed Time: $ELAPSED" 2>&1 | tee -a $LOG_FILE

#echo $RSYNC_COMMAND_WITH_PARAMETERS
#eval $RSYNC_COMMAND_WITH_PARAMETERS
#echo $TAR_COMMAND
#echo $RSYNC_TAR_COMMAND

# backup mysql
if [[ $mysql_dump == 'true' ]]; then
     echo -e "$(date)\t Started backup of MYSQL database" 2>&1 | tee -a $LOG_FILE
    # set evalation time of script to 0
    SECONDS=0
    # get mysql databases ( output from command)
    mysql_databases=`ssh -i $SSH_PRIVATE_KEY_FILE $SSH_USERNAME@$IP "$mysql_prog $mysql_user $mysql_pass $mysql_host -Bse 'show databases'" 2>&1 | tee -a $LOG_FILE`  
    IFS=$'\n';
    mysql_databases=($mysql_databases)
    IFS=$OLD_IFS;
    # if mysql_databases array not contain information_schema string
    if [[ ${mysql_databases[*]} =~ (^|[[:space:]])"information_schema"($|[[:space:]]) ]]; then
        echo -e "$(date)\t Ziskal jsem seznam databaz: ${mysql_databases[*]}" 2>&1 | tee -a $LOG_FILE
    else
        echo -e "$message_sql_err" | mailx -s "$subject_sql_err" -r $mail_from $mail_to;
        exit 1
    fi
    # Check for dir on backup, if not found create it using the mkdir ##
    [ ! -d "$ADRESAR_NA_TUTO_ZALOHU/mysql" ] && mkdir -p "$ADRESAR_NA_TUTO_ZALOHU/mysql" | tee -a $LOG_FILE
    for db in "${mysql_databases[@]}"; do
        echo -e "$(date)\t Start backup of database: $db" 2>&1 | tee -a $LOG_FILE
        ssh -i $SSH_PRIVATE_KEY_FILE $SSH_USERNAME@$IP $mysqldump_prog $mysql_user $mysql_pass --databases $db -c --add-drop-table --single-transaction > $ADRESAR_NA_TUTO_ZALOHU/mysql/$db.sql 2>&1 | tee -a $LOG_FILE;
        if [[ ${PIPESTATUS[0]} == 0 ]]; then
            dump_status+=("0");
            echo -e "$(date)\t Backup database $db is OK" 2>&1 | tee -a $LOG_FILE
        else
            dump_status+=("1");
            echo -e "$(date)\t Backup database $db is with ERROR !!!" 2>&1 | tee -a $LOG_FILE
        fi
        # dump entire mysql database
    done
    ssh -i $SSH_PRIVATE_KEY_FILE $SSH_USERNAME@$IP $mysqldump_prog $mysql_user $mysql_pass -c --all-databases --add-drop-table --single-transaction > $ADRESAR_NA_TUTO_ZALOHU/mysql/entire_db.sql 2>&1 | tee -a $LOG_FILE
    if [[ ${PIPESTATUS[0]} == 0 ]]; then
        dump_status+=("0");
        echo -e "$(date)\t Backup entire database is OK" 2>&1 | tee -a $LOG_FILE
    else
        dump_status+=("1");
        echo -e "$(date)\t Backup entire database is with ERROR !!!" 2>&1 | tee -a $LOG_FILE
    fi
   
    if [[ ${dump_status[*]} =~ (^|[[:space:]])"1"($|[[:space:]]) ]]; then
        echo -e "$message_sql_err" | mailx -s "$subject_sql_err" -r $mail_from $mail_to;
    else
        echo -e "$message_sql_ok\nElapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec" | mailx -s "$subject_sql_ok" -r $mail_from $mail_to;
    fi
    
    ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
    echo -e "$(date)\t Elapsed Time: $ELAPSED" 2>&1 | tee -a $LOG_FILE
fi
