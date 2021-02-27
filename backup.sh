#!/bin/sh

if [[ ! -z "${CA_CRT}" ]]
then
  printf '%s\n' "$CA_CRT" > ca_crt.pem
  cat ca_crt.pem
fi

# Check if db file is accessible and exit otherwise
if [ ! -e "$DB_FILE" ]
then 
  echo "Database $DB_FILE not found!\nPlease check if you mounted the bitwarden_rs volume with '--volumes-from=bitwarden'"!
  exit 1;
fi

if [ $TIMESTAMP = true ]
then
  FINAL_BACKUP_FILE="$(echo "$BACKUP_FILE")_$(date "+%F-%H%M%S")"
else
  FINAL_BACKUP_FILE=$BACKUP_FILE
fi

/usr/bin/sqlite3 $DB_FILE ".backup $FINAL_BACKUP_FILE"
if [ $? -eq 0 ]
then 
  echo "$(date "+%F %T") - Backup successful"
  echo "$FINAL_BACKUP_FILE"
  echo "$BACKUP_FILE"
  BF_NAME=`basename $FINAL_BACKUP_FILE`
  echo "$BF_NAME"
  if [[ -z "${CA_CRT}" ]]
  then
    curl -T ${FINAL_BACKUP_FILE} -u ${WEBDAV_USER}:${WEBDAV_PASSWORD} ${WEBDAV_URL}/${BF_NAME}
  else 
    curl -T ${FINAL_BACKUP_FILE} --cacert ca_crt.pem -u ${WEBDAV_USER}:${WEBDAV_PASSWORD} ${WEBDAV_URL}/${BF_NAME}
  fi
else
  echo "$(date "+%F %T") - Backup unsuccessful"
fi

if [ ! -z $DELETE_AFTER ] && [ $DELETE_AFTER -gt 0 ]
then
  find $(dirname "$BACKUP_FILE") -name "$(basename "$BACKUP_FILE")*" -type f -mtime +$DELETE_AFTER -exec rm -f {} \; -exec echo "Deleted {} after $DELETE_AFTER days" \;
fi
