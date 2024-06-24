
# PGPOOL USER CREATION MULTINODE

### First login as a postgres user


### COPY file to desired direcory
`cp pgpool_usercreator /data/pgpool_usercreation_directory/`

### change directory to desired direcory
`cd /data/pgpool_usercreation_directory/`

### change permission of pgpool_user_creator_v2.sh into executable 
`chmod u+x pgpool_usercreation`


### Export path of that file into .bash_profile file

vim .bash_profile

	`export PATH=$PATH:/data/pgpool_usercreation_directory/`


### Using source command tell OS that it is accessable from postgres user

source ~/.bash_profile


Now you will be able to create pgpool user creation for multinode.




