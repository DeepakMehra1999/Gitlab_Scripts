#! /bin/bash

#Use source to import variables from an input file
source ./gitlab_input_file.txt

#present working directory
pwd=$(pwd)

#Use below code, that will automatically convert Yes/yes to yes
backup=$Backup
Backup=${backup,,}


pull=$Pull
Pull=${pull,,}

restore=$Restore
Restore=${restore,,}


#Use below statements to execute the scripts according to values in an input file
if [ "$Backup" == "yes" ];then
        sudo bash gitlab_backup_script.sh
elif [ "$Pull" == "yes" ];then
        sudo bash gitlab_pull_backup_script.sh
elif [ "$Restore" == "yes" ];then
        sudo bash gitlab_restore_script.sh
else
        echo "Please specify the valid input in an input file"
fi
