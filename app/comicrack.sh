#!/bin/bash
# /bin/bash -x

# Import email and Telegram sending functions
source /app/var.sh
source /app/send_email.sh
source /app/telegram.sh

AUTHOR="Antonio J"
EMAIL="info@sgd.com.br"
PRN="$(basename $0)"
VERSION="00.00.04"

if [ -z "$2" ]; then
    WHEN="day"
else
    WHEN="$2"
fi

MYSQL_ROOT_PASSWORD=$COMICRACK_ROOT_PASSWORD
host_name="%"
db_server=$host_name
backup_dir="/windows/backup/$WHEN"
appdata_dir="/windows/appdata"
sql_file="$backup_dir/$MYSQL_DATABASE.sql"
zip_file="$backup_dir/$MYSQL_DATABASE.zip"
data="\n$PRN - $(date)\n----------------------------------------------------------------\n"
ERROR=""

if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
fi

function usage( )
{
    echo
    echo "$PRN: Required argument missing. $1"
    echo
    echo "Try $PRN -h for more information."
    echo "$PRN $VERSION http://www.ozz.net.br"
    echo "Copyright (C) 2012 - 2025 Ozz Sistemas Ltda"
    echo
    echo "This software compresses the entire directory tree into CBZ files."
    echo
    echo "Usage: $PRN [option]"
    echo
    echo "Where options include:"
    echo "-a Backup ComicRack data folder"
    echo "-b Backup ComicRack database"
    echo "-c Backup ComicRack database and data folder"    
    echo "-r Restore ComicRack database"  
    echo "-u Create ComicRack user and comicdb database"      
    echo "-h Show this help screen"      
    echo "-f Backup all databases from server"
    echo "-l Restore all databases to server"
    exit 0
}

echo -e $data
function dbCreate()
{
    echo "Creating ComicRack user and comicdb database"
    mysql -u root -p < /data/backup/comicdb.sql
    echo
}

function dbRestore( )
{
    local ERROR=""
    echo "Extracting SQL file from ZIP..."
    /usr/bin/unzip "$zip_file" -d /tmp/ || {
        ERROR="Error extracting SQL file: unzip failed for $zip_file"
        return 1
    }
    
    # Remove o comentário problemático do MariaDB
    sed -i 's|/\*M!999999\\- enable the sandbox mode \*/||g' /tmp/"$MYSQL_DATABASE".sql || {
        ERROR="Error removing sandbox comment from SQL file:\n$(cat /tmp/$MYSQL_DATABASE.sql)"
        return 1
    }
    
    # Ajusta o collation para compatibilidade
    sed -i "s/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g" /tmp/"$MYSQL_DATABASE".sql || {
        ERROR="Error modifying SQL file collation:\n$(cat /tmp/$MYSQL_DATABASE.sql)"
        return 1
    }
    
    # Substitui TYPE=InnoDB por ENGINE=InnoDB
    sed -i "s/TYPE=InnoDB/ENGINE=InnoDB/g" /tmp/"$MYSQL_DATABASE".sql || {
        ERROR="Error replacing TYPE with ENGINE in SQL file:\n$(cat /tmp/$MYSQL_DATABASE.sql)"
        return 1
    }
    
    echo "Restoring $MYSQL_DATABASE.sql"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < /tmp/"$MYSQL_DATABASE".sql || {
        ERROR="Error restoring database:\n$(cat /tmp/$MYSQL_DATABASE.sql)"
        return 1
    }
    
    echo "Deleting $MYSQL_DATABASE.sql"
    rm /tmp/"$MYSQL_DATABASE".sql || {
        ERROR="Error deleting SQL file"
        return 1
    }
    
    if [ -n "$ERROR" ]; then
        send_email "[COMICRACK] Error in the ${FUNCNAME[0]} function" "$ERROR"
    fi
}

function dbBackup( )
{
    local ERROR=$ERROR

    echo "Backup database $MYSQL_DATABASE"
    echo "mysqldump -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE --add-drop-table --quote-names --add-drop-database --compatible=mysql40"
    mysqldump -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE --add-drop-table --quote-names --add-drop-database --compatible=mysql40 > $sql_file || {
        ERROR="Error creating database dump:\n$(cat $sql_file)"
        return 1
    }
    
    rm -fr $zip_file || {
        ERROR="Error removing old ZIP file:\n$(cat $zip_file)"
        return 1
    }
    
    /usr/bin/zip -j -9 $zip_file $sql_file || {
        ERROR="Error creating ZIP file:\n$(cat $zip_file)"
        return 1
    }
    
    rm $sql_file || {
        ERROR="Error deleting SQL file:\n$(cat $sql_file)"
        return 1
    }
    
    if [ ! -z "$ERROR" ]; then
        send_email "[COMICRACK] Error in the ${FUNCNAME[0]} function" "$ERROR"
    fi
}

function appDataBackup( )
{
    local ERROR=$ERROR
    
    rm -fr "$backup_dir/AppData.zip" || {
        ERROR="Error removing old AppData ZIP file:\n$(cat $backup_dir/AppData.zip)"
        return 1
    }
    
    /usr/bin/zip -9 -r "$backup_dir/AppData.zip" "$appdata_dir" || {
        ERROR="Error creating AppData ZIP file:\n$(cat $backup_dir/AppData.zip)"
        return 1
    }
    
    if [ ! -z "$ERROR" ]; then
        send_email "[COMICRACK] Error in the ${FUNCNAME[0]} function" "$ERROR"
    fi
}

function dbBackupAll( )
{
    local ERROR=$ERROR
    local all_sql="/tmp/all.sql"
    local all_zip="$backup_dir/all.sql.zip"

    echo "Backing up all databases"
    mysqldump -uroot -p$MYSQL_ROOT_PASSWORD --all-databases --add-drop-table --quote-names --add-drop-database --compatible=mysql40 > $all_sql || {
        ERROR="Error creating full database dump:\n$(cat $all_sql)"
        return 1
    }
    
    rm -fr $all_zip || {
        ERROR="Error removing old all.sql ZIP file:\n$(cat $all_zip)"
        return 1
    }
    
    /usr/bin/zip -j -9 $all_zip $all_sql || {
        ERROR="Error creating all.sql ZIP file:\n$(echo $all_zip)"
        return 1
    }
    
    rm $all_sql || {
        ERROR="Error deleting all.sql file:\n$(cat $all_sql)"
        return 1
    }
    
    if [ ! -z "$ERROR" ]; then
        send_email "[COMICRACK] Error in the ${FUNCNAME[0]} function" "$ERROR"
    fi
}

function dbRestoreAll( )
{
    local ERROR=""
    local all_zip="${backup_dir}/all.sql.zip"
    
    echo "Extracting all.sql file from ZIP..."
    /usr/bin/unzip "$all_zip" -d /tmp/ || {
        ERROR="Error extracting all.sql file: unzip failed for $all_zip"
        return 1
    }
    
    sed -i "s/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g" /tmp/all.sql || {
        ERROR="Error modifying all.sql file:\n$(cat /tmp/all.sql)"
        return 1
    }
    
    echo "Restoring all databases"
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < /tmp/all.sql || {
        ERROR="Error restoring databases:\n$(cat /tmp/all.sql)"
        return 1
    }
    
    echo "Deleting all.sql"
    rm /tmp/all.sql || {
        ERROR="Error deleting all.sql file"
        return 1
    }
    
    if [ -n "$ERROR" ]; then
        send_email "[COMICRACK] Error in the ${FUNCNAME[0]} function" "$ERROR"
    fi
}

# Execute options based on passed parameters

while getopts "abcfhlru" OPT; do
    case "$OPT" in
    "a") appDataBackup
         exit 0
        ;;
    "b") dbBackup
         exit 0
        ;;   
    "c") dbBackup
         appDataBackup
         exit 0
        ;;         
    "r") dbRestore
         exit 0
        ;;
    "u") dbCreate
         exit 0
        ;;        
    "h") usage
         exit 0
        ;;      
    "f") dbBackupAll
         exit 0
        ;;
    "l") dbRestoreAll
         exit 0
        ;;
    "?") usage
         exit 0
        ;;     
    esac
done

[ $# == 0 ] && usage "You need to choose at least one option."

exit 0
