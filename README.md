
# PGPOOL USER CREATION MULTINODE

### COPY file to desired direcory
`cp pgpool_usercreator /data/pgpool_usercreation_directory/`

### change directory to desired direcory
`cd /data/pgpool_usercreation_directory/`

### change permission of pgpool_user_creator_v2.sh into executable 
`chmod u+x pgpool_usercreation`



vim .bash_profile

	`export PATH=$PATH:/data/pgpool_usercreation_directory/`

source ~/.bash_profile


Now you will be able to create pgpool user creation for multinode.




