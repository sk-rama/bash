#!/bin/bash


#parametre pre adresar kam, sa bude zalohovat na lokalnom stroji
#-------------------------------------------------------------------------------------------------#
NAZOV_SERVRA='ns1.secar.cz'
IP='212.158.133.41'
#ZALOHOVANE_ADRESARE_ZOZNAM='/etc :/var/cache/bind'
ZALOHOVANE_ADRESARE_ZOZNAM='/etc /var/cache/bind'
TAR_EXCLUDE="'/var/cache/bind/named.stats' '/tmp/*'"
DNESNY_DATUM=`date --rfc-3339=date`
ZALOHOVACI_ADRESAR_LOCAL='/var/backup'
ADRESAR_NA_TUTO_ZALOHU="$ZALOHOVACI_ADRESAR_LOCAL/$DNESNY_DATUM/$NAZOV_SERVRA"
LOG_FILE=$ADRESAR_NA_TUTO_ZALOHU/$NAZOV_SERVRA.log
SECONDS=0
#-------------------------------------------------------------------------------------------------#



#parametre pre rsync a ssh - vacsinou uz netreba upravovat
#-------------------------------------------------------------------------------------------------#
SSH_USERNAME='rrastik'
SSH_PRIVATE_KEY_FILE='/home/rrastik/.ssh/id_rsa'
RSYNC_COMMAND_WITH_PARAMETERS="rsync -arl -e \"ssh -i $SSH_PRIVATE_KEY_FILE\" $SSH_USERNAME@$IP:$ZALOHOVANE_ADRESARE_ZOZNAM $ADRESAR_NA_TUTO_ZALOHU" 
#TAR_COMMAND="tar -C $ADRESAR_NA_TUTO_ZALOHU -czf $ZALOHOVACI_ADRESAR_LOCAL/$DNESNY_DATUM/$NAZOV_SERVRA.tar ."  
#COPY_CMD="ssh -i $SSH_PRIVATE_KEY_FILE $SSH_USERNAME@$IP tar --ignore-failed-read -v -czf - $ZALOHOVANE_ADRESARE_ZOZNAM > $ADRESAR_NA_TUTO_ZALOHU/$NAZOV_SERVRA.tgz"
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

# start of backup
echo -e "$(date)\t I will backup directories: $ZALOHOVANE_ADRESARE_ZOZNAM" 2>&1 | tee -a $LOG_FILE
echo -en "$(date)\t command started:\t" 2>&1 | tee -a $LOG_FILE; make_tar_exclude 2>&1 | tee -a $LOG_FILE
echo -e "\n$(date)"; echo -e "$(date)\t Output from previous command:" 2>&1 | tee -a $LOG_FILE
eval $(make_tar_exclude) 2>&1 | tee -a $LOG_FILE 

ELAPSED="Elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min $(($SECONDS % 60))sec"
echo -e "$(date)\t Elapsed Time: $ELAPSED" 2>&1 | tee -a $LOG_FILE

#echo $RSYNC_COMMAND_WITH_PARAMETERS
#eval $RSYNC_COMMAND_WITH_PARAMETERS
#echo $TAR_COMMAND
#echo $RSYNC_TAR_COMMAND
