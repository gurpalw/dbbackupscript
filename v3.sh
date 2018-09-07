#!/bin/bash
#Script to restore a sbx db to prod db for new SB environments.#
#
while getopts h:d:u: options; do
  case $options in
    h) dbhost=$OPTARG;;
    d) dbname=$OPTARG;;
    u) dbusername=$OPTARG;;
    esac
done
read -s -p "DB Password: " dbpassword
echo
read -p "Filename for dump: " filename
echo "Attempting to dump $dbname from $dbhost to $filename.sql.gz"
echo "mysqldump --verbose -h $dbhost --max_allowed_packet=1G --extended-insert --single-transaction --add-drop-database --opt $dbname --user=$dbusername --password=xxxxxx | gzip -1 > $filename.sql.gz"
set -o pipefail
mysqldump --verbose -h $dbhost --max_allowed_packet=1G --extended-insert --single-transaction --add-drop-database --opt $dbname --user=$dbusername --password=$dbpassword | gzip -1 > $filename.sql.gz
if [ $? -eq 0 ]; then
  echo "Successfully created dump."
  read -p "Enter host that you wish to restore: " restoredbhost
  read -p "Enter name of database you wish to restore to: " restoredbname
  echo "Enter Credentials for $restoredbhost"
  read -p "Username: " restoredbusername
  zcat < $filename.sql.gz | perl -pe 's/\sDEFINER=`[^`]+`@`[^`]+`//' | mysql -h $restoredbhost -u $restoredbusername -p $restoredbname
    if [ $? -eq 0 ]; then
      echo "Restore complete."
      exit 0
    else
      echo "Restore failed."
      exit 1
    fi
else
  echo "Something went wrong with the mysqldump."
  rm $filename.sql.gz
  exit 1
fi