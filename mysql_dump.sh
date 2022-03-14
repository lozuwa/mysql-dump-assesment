#!/usr/bin/env bash
# Description: Mysql database dumper.
# How to use: Run ./mysql_dump.sh -c $PATH_TO_CRED_FILE -d $DB_NAME -p $PATH_TO_DUMP
# Implementation:
#   - Minimal user interface.
#   - backup function has the code to do the full dump and minimal dump.
# TODOs:
#   - Documentation on the contents of $PATH_TO_CRED_FILE
#   - Make sure you can read from $PATH_TO_CRED_FILE
#   - Make sure you can write to $PATH_TO_DUMP
#   - Make sure $DB_NAME exists.
#   - Make sure there is enough space in $PATH_TO_DUMP disk.

set -o errexit
set -o pipefail
set -o nounset

help() {
  echo "Usage:                                                                           "
  echo "  ./mysql_dump.sh [options]                                                      "
  echo "  -c Path to a file that contains username and password to connect to a mysql db."
  echo "  -d Name of the database to dump.                                               "
  echo "  -p Output path where to dump the dump files (must be a folder).                "
  exit 0
}

backup() {
  # Notes:
  #  - Have a readable date in the name of the dumped files in the format e.g: DBNAME_03-13-2022-1647228430_FULL.sql.gz
  FULL_BACKUP_FILENAME="$(echo $3)_$(date +"%m-%d-%Y")-$(date +%s)_FULL.sql.gz"
  MINIMIZED_BACKUP_FILENAME="$(echo $3)_$(date +"%m-%d-%Y")-$(date +%s)_MINIMIZED.sql.gz"
  # Mysqldump notes:
  #   - --opt enabled by default. Produces reloadable dump.
  #   - --quick Reduces memory usage by avoiding memory buffer of all tables. Instead it grabs a row at a time.
  #   - --single-transaction Avoid blocking operations in case the db is being used at the same time.
  #   - --passsword was read from a plain text file that should be located in a secure path (root user protected suggested).
  #   - piped gzip used to compress the output of the dump. Reduces I/O.
  #   - Steps to take dumps:
  #     - Find the table names that we want to filter out (log_.*).
  #     - Create a string with the --ignore-table command for all the log_.* tables.
  #     - Dump table structure to full backup and minimized gzip files (quick operation no impact on running twice).
  #     - Dump all table data except log_.* prefixed tables to minimized gzip file.
  #     - Append minimized backup gzip to full backup gzip.
  #     - Add log_.* prefixed tables to full backup gzip.
  table_names=($(mysql -BN --user=$1 --password=$2 -e "select table_name from information_schema.tables where table_schema=\"$3\" and table_name like \"log_%\";"))
  ignore_command=""
  for table_name in "${table_names[@]}"; do
    ignore_command+="--ignore-table=$3.${table_name} "
  done;

  echo "Dumping data schemas."
  mysqldump --no-data --user=$1 --password=$2 $3 | gzip > "${FULL_BACKUP_FILENAME}"
  mysqldump --no-data --user=$1 --password=$2 $3 | gzip > "${MINIMIZED_BACKUP_FILENAME}"

  echo "Dumping all data except log_.* prefix tables."
  echo "Ignoring tables ${ignore_command}"
  mysqldump --no-create-info "${ignore_command}" --opt --quick --single-transaction --user=$1 --password=$2 $3 | gzip >> "${MINIMIZED_BACKUP_FILENAME}"
  cat "${MINIMIZED_BACKUP_FILENAME}" >> "${FULL_BACKUP_FILENAME}"

  echo "Adding log_.* prefix tables to full backup."
  for table_name in "${table_names[@]}"; do
    echo $table_name
    mysqldump --no-create-info --opt --quick --single-transaction --user=$1 --password=$2 $3 $table_name | gzip >> "${FULL_BACKUP_FILENAME}"
  done;
}

############################################
################### MAIN ###################
############################################
CREDENTIALS_PATH=""
DATABASE_NAME=""
PATH_TO_DUMP=""
while getopts c:d:p:e option; do
  case "${option}" in
  c) CREDENTIALS_PATH=${OPTARG} ;;
  d) DATABASE_NAME=${OPTARG} ;;
  p) PATH_TO_DUMP=${OPTARG} ;;
  h) help ;;
  esac
done
if [[ ! -f "${CREDENTIALS_PATH}" ]]; then
  echo "Provide a valid filepath to a credentials file."
  help
  exit 1;
fi;
CREDENTIALS=($(cat "${CREDENTIALS_PATH}"))
if [[ "${#CREDENTIALS[@]}" != 2 ]]; then
  echo "Credentials file should have username and password."
  help
  exit 1;
fi;
if [[ -z "${DATABASE_NAME}" || -z "${PATH_TO_DUMP}" ]]; then
  echo "Provide database name and path to dump files to."
  help
  exit 1;
fi;

backup "${CREDENTIALS[0]}" "${CREDENTIALS[1]}" "${DATABASE_NAME}" "${PATH_TO_DUMP}"
