#!/bin/bash

# Author: Sheikh Wasiu Al Hasib
# Description: This script will archive large table data into archived table
# Created At: 2022-Sep-09
# Updated At: 2022-Sep-14

 ARCHIVED_FILE_PATH=/var/log/backup/archive.log    #************ THIS IS DEFAULT LOG LOCATION YOU CAN CHANGE ************
 RETENTION_DAYS=$1                                 #************ YOU CAN PASS RETENTION DAYS AS ARGUMENT, THIS WILL WORK AS A GLOBAL (DEFAULT WILL IGNORE)****************
 CHANGE_DB_PORT=$2                                 #************ YOU CAN PASS DB PORT AS ARGUMENT,THIS WILL WORK AS A GLOBAL (DEFAULT WILL IGNORE) ************************

 if [ -z $ARCHIVED_FILE_PATH ]
 then
         touch $ARCHIVED_FILE_PATH
         chown postgres:postgres $ARCHIVED_FILE_PATH
 fi

echo   | tee -a  $ARCHIVED_FILE_PATH >/dev/null
echo ================  Archived Date: $(date) =============== | tee -a  $ARCHIVED_FILE_PATH >/dev/null

 #************************************************
 #************INFO: STANDBY CHECKER***************
 #************************************************

 IS_STANDBY=$(psql -p 5678 -U postgres -Aqxtc 'select pg_is_in_recovery()'| cut -d '|' -f 2)
 if [ $IS_STANDBY = 't' ]
 then
         echo CreatedAt:$(date) This is standby node | tee -a  $ARCHIVED_FILE_PATH >/dev/null
         exit 0;
 fi



 #****************************************************************
 #************INFO: STANDBY ARCHIVE DURATION CHECKER***************
 #*****************************************************************

function _archive_info(){

        # Here start time $1 and end time $2

        START_TIME="$1"
        END_TIME="$2"
        IP=$(hostname -I | cut -d ' ' -f 1)
        HOSTNAME_INFO=$(hostname)

        StartDate=$(date -u -d "$1" +"%s")  # Start time
        FinalDate=$(date -u -d "$2" +"%s")  # End time
        backup_duration=$(date -u -d "0 $FinalDate sec - $StartDate sec" +"%H:%M:%S" )

        echo NOTICE: ArichivedStartTime:${START_TIME} ArchivedEndTime:${END_TIME} TotalDuration:${backup_duration} | tee -a  $ARCHIVED_FILE_PATH >/dev/null

}



 #***********************************************
 #************INFO: DATA ARCHIVER ***************
 #***********************************************

 function  _db_large_table_archive(){
                        db_name=$1
                        db_user=$2                                      #****************** INFO: NEED TO ADD PRODUCTION DB USER *******************
                        db_pass=$3                                      #****************** INFO: NEED TO ADD PRODUCTION DB PASSWORD *******************
                        db_prod_table=$5                                #****************** INFO: NEED TO CHANGE PRODUCTION TABLE *******************
                        db_archive_table=$6                             #****************** INFO: NEED TO CHANGE ARICHIVED TABLE *******************

                        #echo $db_name;
                        #echo $db_user;
                        #echo $db_pass;
                        #echo $db_prod_table;
                        #echo $db_archive_table;
                        #echo $DB_PORT;

                        if [ -z $CHANGE_DB_PORT ]
                        then
                                DB_PORT=$7                              #****************** INFO: NEED TO CHANGE RETENTION DAYS *******************
                        else
                                DB_PORT=$CHANGE_DB_PORT                 #****************** INFO: NEED TO CHANGE RETENTION DAYS *******************
                        fi


                        if [ -z $RETENTION_DAYS ]
                        then
                                db_retention_days=$4                    #****************** INFO: NEED TO CHANGE RETENTION DAYS *******************
                        else
                                db_retention_days=$RETENTION_DAYS       #****************** INFO: NEED TO CHANGE RETENTION DAYS *******************
                        fi

                        #***************************************************************
                        #*****************CHECK DATABASE EXISTANCE ************************
                        #***************************************************************
                        IS_DB_EXISTS=$(psql -p $DB_PORT  -XtAc "SELECT datname FROM pg_database WHERE datname='${db_name}'")

                        #***************************************************************
                        #*****************CHECK TABLE EXISTANCE ************************
                        #***************************************************************
                        IS_PROD_TBL_EXISTS=$(psql -p $DB_PORT  -XtAc \
                                "SELECT table_name FROM INFORMATION_SCHEMA.TABLES \
                                WHERE table_name='${db_prod_table}'  AND\
                                table_schema='public'");

                        #***************************************************************
                        #*****************CHECK DATA AVAILABILITY************************
                        #***************************************************************
                        ARCHIVE_DATA_COUNT=$(psql -p $DB_PORT -d $db_name  -XtAc "\
                                        SELECT count(*) FROM ${db_prod_table} \
                                        WHERE updated_at<TO_DATE(TO_CHAR(now()- interval  '1 days' * ${db_retention_days}, 'yyyy-mm-dd'),'YYYY-MM-DD')");

                        if [[ -n $IS_DB_EXISTS ]] && [[ -n $IS_PROD_TBL_EXISTS ]]
                        then
                                echo Database name: $db_name | tee -a  $ARCHIVED_FILE_PATH >/dev/null
                                echo Prod table name: $db_prod_table | tee -a  $ARCHIVED_FILE_PATH >/dev/null
                                echo Archiver table name: $db_archive_table | tee -a  $ARCHIVED_FILE_PATH >/dev/null
                                echo Table data retention days: $db_retention_days | tee -a  $ARCHIVED_FILE_PATH >/dev/null
                                echo Archive data count: $ARCHIVE_DATA_COUNT | tee -a  $ARCHIVED_FILE_PATH >/dev/null
                                echo Archiving in progress...... | tee -a  $ARCHIVED_FILE_PATH

                                PGBASSWORD=$db_pass psql -U $db_user -d $db_name -w -p $DB_PORT -c  "CALL data_archiver('$db_retention_days','$db_prod_table','$db_archive_table')"

                                echo Archiving end | tee -a  $ARCHIVED_FILE_PATH
                        else
                                echo ERROR: Human bugs, please check your database name or prod table name at this script: $0. It does not exists | tee -a $ARCHIVED_FILE_PATH >/dev/null
                        fi
 }



 #******************************************************
 #************INFO: DATA ARCHIVING CALLER***************
 #******************************************************

 if [ $IS_STANDBY == 'f' ]
 then
        #**********************************SAMPLE EXAMPLE*****************************************************************************************
        #*******Example:function _db_large_table_archive 'db_name' 'prod_user' 'prod_pass' 'table_retention_days' 'prod_table' 'archived_table' 'db_port'
        #*****************************************************************************************************************************************

         # paramater: database name
         # paramater: database user
         # paramater: database password
         # paramater: retention days
         # paramater: production main database
         # paramater: archived table name
         # paramater: database port

        #**************************************************************************************
        #***********************REDCUBE  TABLE archiver************************
        #**************************************************************************************
        START_TIME=$(date +"%H:%M:%S")
	_db_large_table_archive  'db_test' 'db_user_test' 'MyPass@132' 120 'demo_table' 'archive_demo_table' 5678
        END_TIME=$(date +"%H:%M:%S")
        _archive_info $START_TIME $END_TIME


#       START_TIME=$(date +"%H:%M:%S")
#       _db_large_table_archive  'test_db' 'user_test' 'MyPass4321' 199 'demo_table' 'archived_demo_table' 5678
#       END_TIME=$(date +"%H:%M:%S")
#       _archive_info $START_TIME $END_TIME
 fi
