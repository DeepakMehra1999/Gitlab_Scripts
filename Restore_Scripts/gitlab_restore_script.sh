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

#Please specfiy the folder name you want to take for final restore task
final_gitlab_backup_folder=final_gitlab_backup_folder

#make a directory and store recent backup in this folder
mkdir -p $dir/$final_gitlab_backup_folder

#move to /app and give permission to above created directory
cd $dir
sudo chmod 777 $final_gitlab_backup_folder


#take most recent gitlab backup folder in a variable
recently_transfered_folder_after_taking_backup_from_server1=$(ls -t $path_of_folder_where_backup_files_are_already_present | head -1)

#move to folder where gitlab folder present in which backup folder is present
#cd $path_of_folder_where_backup_files_are_already_present/$recently_transfered_folder_after_taking_backup_from_server1



#store the recent backup tar file path in a separate variable
latest_tar=$(ls -t $path_of_folder_where_backup_files_are_already_present/$recently_transfered_folder_after_taking_backup_from_server1/*.tar | head -1)
latest_rb_file=$(ls -t $path_of_folder_where_backup_files_are_already_present/$recently_transfered_folder_after_taking_backup_from_server1/*.rb | head -1)
latest_json_file=$(ls -t $path_of_folder_where_backup_files_are_already_present/$recently_transfered_folder_after_taking_backup_from_server1/*.json | head -1)



#move recent backup to final_gitlab_backup_folder
cp $latest_tar $dir/$final_gitlab_backup_folder
cp $latest_rb_file $dir/$final_gitlab_backup_folder
cp $latest_json_file $dir/$final_gitlab_backup_folder



#store the file name in separate variables
gitlab_backup_file_name=$(basename "$latest_tar")
gitlab_backup_rb_file=$(basename "$latest_rb_file")
gitlab_backup_json_file=$(basename "$latest_json_file")



#move to the final gitlab backup folder
cd $dir/$final_gitlab_backup_folder



#remove date and time from filenames
gitlab_backup_file_name_after_removing_datetime=$(echo $gitlab_backup_file_name | cut -d "_" -f1-7)
gitlab_backup_rb_file_name_after_removing_datetime=$(echo $gitlab_backup_rb_file | cut -d "_" -f1)
gitlab_backup_json_file_name_after_removing_datetime=$(echo $gitlab_backup_json_file | cut -d "_" -f1)

#Now add required extensions to above files
mv "$gitlab_backup_file_name" "$gitlab_backup_file_name_after_removing_datetime.tar"
mv "$gitlab_backup_rb_file" "$gitlab_backup_rb_file_name_after_removing_datetime.rb"
mv "$gitlab_backup_json_file" "$gitlab_backup_json_file_name_after_removing_datetime.json"

cp "$gitlab_backup_file_name_after_removing_datetime.tar" $path_of_backup_directory
cp "$gitlab_backup_rb_file_name_after_removing_datetime.rb" $path_of_gitlab_files
cp "$gitlab_backup_json_file_name_after_removing_datetime.json" $path_of_gitlab_files

#Give rwx permissions to gitlab.rb and gitlab-secrets.json
sudo chmod 777 $path_of_gitlab_files/gitlab.rb
sudo chmod 777 $path_of_gitlab_files/gitlab-secrets.json

#Now add host_ip of this server to gitlab.rb file
sed -i "32d" $path_of_gitlab_files/gitlab.rb
sed -i "32i\ external_url 'http://$host_ip'" $path_of_gitlab_files/gitlab.rb


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

#checking gitlab status
sudo gitlab-ctl status
if [ $? -eq 0 ]; then
    echo "${green} ---------------------------------------"
    echo "${green}         Gitlab is running fine"
    echo " ---------------------------------------"
else
    echo "${red}************Gitlab is not in running state****************"
    exit
fi

#store the recent backup tar file path in a separate variable
latest_tar_filepath_of_gitlab_backup=$(ls -t $dir/$final_gitlab_backup_folder/*.tar | head -1)

#store it's file name in another variable
latest_tar_file_of_gitlab_backup=$(basename "$latest_tar_filepath_of_gitlab_backup")

#store the current version of gitlab in a variable
current_version_of_gitlab=$(sudo gitlab-rake gitlab:env:info | awk 'NR == 15 {print $2}')

#store version of gitlab backup file in a variable
version_of_gitlab_backup_file=$(echo $latest_tar_file_of_gitlab_backup | cut -d '_' -f 5)

#compare them they are equal or not
if [ $current_version_of_gitlab != $version_of_gitlab_backup_file ]; then
        echo "$red Restore process will not start"
        echo "$red Current version of gitlab installed in a server doesn't match with the version of gitlab backup tar file"
        exit
fi

#Check if ‘NA’ folder exists in /opt/gitlab/embedded/services/gitlab-rails/
if [ -d "$path_of_NA_directory" ]
then
        sudo chown root:root "$path_of_NA_directory"
else
        sudo mkdir "$path_of_NA_folder_directory"/NA
        sudo chown root:root "$path_of_NA_folder_directory"
        sudo chmod 777 "$path_of_NA_folder_directory "/NA
fi


#store file name in specific format
backup_file_name_in_required_format=$(echo $latest_tar_file_of_gitlab_backup | cut -d '_' -f -5)

#If everything above fine, go with the restore process
echo "yes" | sudo gitlab-backup restore BACKUP=$backup_file_name_in_required_format
#echo "yes" | Do you want to continue (yes/no)?

gitlab-ctl reconfigure


#Now remove this final_gitlab_backup_folder
rm -rf $dir/$final_gitlab_backup_folder

#remove gitlab backup tar file from /var/opt/gitlab/backups
rm -rf $path_of_backup_directory/*

echo "${green}**********Restore process Completed***********"
echo "Please log in to the GitLab UI and verify that the backup has been Successfully restored."