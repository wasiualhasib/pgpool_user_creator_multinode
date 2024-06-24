#!/bin/bash

#       Author: Sheikh Wasiu Al Hasib
#       Name: pgpool_usercreate
#       Date: 15-May-2022
#       Description: Instead of manually create user from different node, just run this script and pass user information and password


############################## Script Manual #######################
#       1. Create pgpool user
#       2. Give pool user , dbname, VIP if any one component not given then abort this program
#       3. Check given user is already available in db or not
#       4. If db user not available then notify to create db user
#       5. If db user available then proceed for user creation to all node.



#============================ USER INPUT ===================================
read -p  "Please enter your new user:" username
#read -p  "Please enter pgpool user:" pooluser
#read -p  "Please enter pgpool dbname:" pgdb
#read -p  "Please enter pgpool VIP:" vip



#============================ DEFAULT INPUT VARIABLE =========================
pooluser='pgpool'                                          # Our case pgpool use is pgpool
pgdb='postgres'                                            # default db is postgres
vip='192.168.43.100'                                       # VIP must be valid before execute,MUST NEED TO CHANGE ACCORDING TO SERVER
server_list=(192.168.43.101 192.168.43.102 192.168.43.103) # Correct pgpool server information MUST NEED TO CHANGE ACCORDING TO SERVER
pgpoolPass='MyPass1234'                            # You need to manually change it.MUST NEED TO CHANGE ACCORDING TO SERVER
pool_pass_file_path=/etc/pgpool-II/pool_passwd
pool_keypath=/var/lib/pgsql/.pgpoolkey
LOGDIR=/var/log/script_log
LOGFILE=$LOGDIR/script.log
IS_AVAILABLE=0;


# YYYY-MM-DD
TIMESTAMP=$(date +%F)
# YYYY
YEAR=$(date +%Y)                        # Year e.g. 2018
# Month
MONTH=$(date +%B)               # Month e.g. January
# WEEKDAY
WEEKDAY=$(date +%A)             # WEEDDAY e.g. Wednesday
# HOUR AND MINUTE
HOUR_MIN=$(date +"%H-%M")       # HOUR and MIN e.g. 20:00



#========================== LOG FILE CHECK ===========================
if [ ! -d $LOGDIR ]
then
         sudo mkdir -p $LOGDIR
         sudo chown postgres:postgres $LOGDIR
fi

if [ ! -f $LOGFILE ]
then
        touch $LOGFILE
        if [ $? -eq 0 ]
        then
                echo Time: $(date) , Message: File created
        fi
fi


echo Time: $(date)================== pgpool user creation script started=============== | tee -a $LOGFILE

#========================= VARIABLE INPUT VALIDITY CHECK =====================
if [ -z $pooluser ] || [ -z $pgdb ] || [ -z $vip ] || [ -z $server_list ] || [ -z $pgpoolPass ] || [ -z $pool_pass_file_path ]
then
        echo Time : $(date) , Message: necessary pgpool information not provided, please provide pgpooluser, pgdb,vip, poolpass,pool_pass_file_path
        exit 1
fi

db_usercheck=$(PGPASSWORD=$pgpoolPass psql -AXqtc "SELECT 1 FROM pg_roles WHERE rolname='$username' " -d $pgdb -U $pooluser -p 9999 -h $vip)
pgpool_usercheck=$(cat $pool_pass_file_path | cut -d ':' -f 1 | grep -w ${username})

function _pgpool_user_creation(){
                       for ip in ${server_list[@]}
                       do


                                ssh -T -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null postgres@${ip} -i ~/.ssh/id_rsa ls /tmp > /dev/null
                                if [ $? -ne 0 ]; then
                                        echo Time:$(date) ,Message:passwordless SSH to postgres@${ip} failed. Please setup passwordless SSH | tee -a $LOGFILE
                                       exit 1
                                fi

                                ssh -t postgres@$ip pg_enc -m -k $pool_keypath -u $username -p

                                if  [ $? -eq 0 ]
                                then
                                        echo Time: $(date) , Message: pgpool user $username successfully created at server: $ip | tee -a $LOGFILE
                                fi

                                ssh postgres@$ip cat $pool_pass_file_path | awk -F ':' -v var=$username '$1==var { print $0 }'
                       done
                       echo Time: $(date), Message: ================pgpool user creation all steps completed successfully=============== | tee -a $LOGFILE
                       exit 0
               }

if [ ! -z  $db_usercheck  ]
then
        echo User available at db
        if [ -z $pgpool_usercheck ]
        then
                _pgpool_user_creation $server_list
        else
                echo Time:$(date) ,Message:pgpool user already available, $pool_pass_file_path | tee -a $LOGFILE
                read -p "Do you want to reset the password (y/n)?" is_reset_pass
                if [ $is_reset_pass == 'y' ]
                then
                        echo ======================NOTICE===============
                        echo 1. Reset password of this user at database
                        echo 2. Reset password at pgpool if available
                        echo 3. Change password at pgbouncer if availabe
                        echo =============================================
                        sleep 2

                        read -p "Did you reset password at database(y/n)?" is_db_reset_password

                        if [ $is_db_reset_password == 'y' ]
                        then
                                 _pgpool_user_creation $server_list
                        else
                                echo Time: $(date) ,Message:Please reset your db password first| tee -a $LOGFILE
                                exit 0
                        fi
                else
                        exit 0
                fi

        fi

else
        echo Time:$(date) ,Message:User not available at database, User need to create at databsae level first | tee -a $LOGFILE
fi
