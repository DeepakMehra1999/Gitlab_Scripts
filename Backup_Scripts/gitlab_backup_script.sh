#! /bin/bash

#Use source to import variables from an input file
source ./gitlab_input_file.txt

#present working directory
pwd=$(pwd)

#path of directory where backup folder is present
path_of_backup_folder_directory="/var/opt/gitlab/"

#path of backup directory
path_of_backup_directory="/var/opt/gitlab/backups"

#path of directory where NA folder is present
path_of_NA_folder_directory="/opt/gitlab/embedded/service/gitlab-rails/"

#path of NA directory
path_of_NA_directory="/opt/gitlab/embedded/service/gitlab-rails/NA"

#path where gitlab.rb and gitlab-secrets.json present
path_of_gitlab_files="/etc/gitlab"

#path of git-data directory
git_data_dir="/git-data"


#check if gitlab is in running state or not
echo "******************************************************"
echo "******************************************************"
echo "******************************************************"
echo "**************Checking Gitlab Status******************"
echo "******************************************************"
echo "******************************************************"
echo "******************************************************"

# Declaring variables to add color coding
red=`tput setaf 1`
green=`tput setaf 2`

#Check the status of gitlab
sudo gitlab-ctl status
if [ $? -eq 0 ]; then
        echo "${green} ---------------------------------------"
        echo "${green}         Gitlab is running fine"
        echo " ---------------------------------------"
else
    echo "${red} Gitlab is not in running state"
    exit
fi

#check if gitlab backups folder has required perm.
#check the ownership of backups directory it is git or not
owner_check_of_backups=$(ls -l  $path_of_backup_folder_directory | grep backups | awk '{print $3}')


if [ "$owner_check_of_backups" != "git" ]
then
        sudo chown git:git -R backups
fi

#check if the git-data folder has required permissions.
#move to the /app directory
cd $dir

owner_check_of_gitdata=$(ls -l | grep git-data | awk '{print $3}')
if [ "$owner_check_of_gitdata" != "git" ]
then
        sudo chown git:git -R git-data
fi

if [ -d "$path_of_NA_directory" ]
then
        sudo chown root:root "$path_of_NA_directory"
else
        sudo mkdir "$path_of_NA_folder_directory"/NA
        sudo chown root:root "$path_of_NA_folder_directory"
        sudo chmod 777 "$path_of_NA_folder_directory"/NA
fi

#Every directory has required permissions now, start taking backup
sudo gitlab-backup create

#give rwx permissions to all the files in a default backups folder
sudo chmod -R 777 $path_of_backup_directory


#check /app directory present or not in an external server if exists than
#create a directory where you want to store gitlab backup file and gitlab-secetets.json ,gitlab.rb at one place
if [ -d "$dir" ]; then
        sudo mkdir -p $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
else
        sudo mkdir -p $path_of_backup_folder_directory/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
fi


#give permissions to gitlab.rb and gitlab-secrets.json files
sudo chmod 777 $path_of_gitlab_files/gitlab.rb
sudo chmod 777 $path_of_gitlab_files/gitlab-secrets.json



#copy the file gitlab.rb and gitlab-secrets.json to final_gitlab_folder
if [ -d "$dir" ]; then
        cp $path_of_gitlab_files/gitlab.rb $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
        cp $path_of_gitlab_files/gitlab-secrets.json $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
else
        cp $path_of_gitlab_files/gitlab.rb $path_of_backup_folder_directory/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
        cp $path_of_gitlab_files/gitlab-secrets.json  $path_of_backup_folder_directory/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
fi

#store the recent backup file path in a variable from all backup files present
recent_backup_file_path=$(find $path_of_backup_directory -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")

#move the recent gitlab backup file in a final gitlab folder
if [ -d "$dir" ]; then
        cp "$recent_backup_file_path" $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
else
        cp "$recent_backup_file_path" $path_of_backup_folder_directory/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
fi

#move to the final_gitlab_folder
if [ -d "$dir" ]; then
        cd $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
else
        cd $path_of_backup_folder_directory/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
fi


#store recent gitlab backup file in a separate variable
gitlab_backup_file_name=$(basename "$recent_backup_file_path")

#take separate variable to store file name without involving its extension tar
gitlab_backup_file_name_without_using_tar=$(basename $gitlab_backup_file_name .tar)

#Now rename all 3 files according to the timestamp
mv gitlab.rb  gitlab'_'$(date +"%Y-%m-%d_%H-%M-%S")'.rb'
mv gitlab-secrets.json gitlab-secrets'_'$(date +"%Y-%m-%d_%H-%M-%S")'.json'
mv $gitlab_backup_file_name $gitlab_backup_file_name_without_using_tar'_'$(date +"%Y-%m-%d_%H-%M-%S")'.tar'


#move to the directory where all the scripts are present
cd $pwd

#transfer your final_backup_folder to the 2nd server
sudo sshpass -p "$host_password_of_server2" scp -oStrictHostKeyChecking=no -r $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y") "$host_user_of_server2"@"$host_ip_of_server2":$path_where_you_want_to_move_backup


#if value of backup location is S3 in an input file, push the backup to S3 bucket else store it in a local file system
if [ "$backup_location" == 'S3' ];then
        bash gitlab_push_backup_script.sh
        rm -rf $path_of_backup_directory/*
        #rm -rf $dir/$final_gitlab_folder'_'$(date +"%d-%m-%Y")
elif [ "$backup_location" == 'LF' ];then
        echo "Backup is completed"
        rm -rf $path_of_backup_directory/*
else
        echo "Input the valid backup location"
fi


