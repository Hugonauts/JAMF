#!/bin/bash
####################################################################################################
#
# THIS SCRIPT IS NOT AN OFFICIAL PRODUCT OF JAMF SOFTWARE
# AS SUCH IT IS PROVIDED WITHOUT WARRANTY OR SUPPORT
#
# BY USING THIS SCRIPT, YOU AGREE THAT JAMF SOFTWARE
# IS UNDER NO OBLIGATION TO SUPPORT, DEBUG, OR OTHERWISE
# MAINTAIN THIS SCRIPT
#
####################################################################################################
#
# DESCRIPTION
# This is a self destruct script that will delete all patch notifications in Jamf Pro.
# Requires a user that has READ and DELETE privys for Notifications. It will read in
# parameters, so no need to change anything in the script.
#
# Script created Oct 2020 and modeled off Ryan Peterson's Delete All Classes script at https://github.com/yoopersteeze/jamfScripts/blob/master/API/DELETE/deleteAllClasses.sh
#
####################################################################################################
#
# READ IN PARAMETERS (NO NEED TO CHANGE ANYTHING HERE)
#
####################################################################################################
echo "#####################"
echo "###!!! WARNING !!!###"
echo "#####################"
echo "This is a self destruct stript that will delete all Patch Notifications."
echo "Please ensure you have a database backup."
echo "There is no magic undo button other than restoring to a backup when the Notifications were in existance."
read -p "Are you sure you want to continue? [ y | n ]  " answer
if [[ $answer != 'y' ]]; then
	echo "Exiting script!"
	exit 1
fi

read -p "Jamf Pro URL: " server
read -p "Jamf Pro Username: " username
read -s -p "Jamf Pro Password: " password
echo ""
####################################################################################################
#
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
####################################################################################################
#Convert the creds, courtesy Bill Smith
encodedCredentials=$( printf "$username:$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "$server/uapi/auth/tokens" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

#Trim the trailing slash off if necessary courtesy of github dot com slash iMatthewCM
if [ $(echo "${server: -1}") == "/" ]; then
	server=$(echo $server | sed 's/.$//')
fi

#Engage the JPAPI!
echo "Deleting all Patch Notifications now!"
curler=$(curl -s -H "accept: application/json" -H "Authorization: Bearer $token" "$server/api/notifications/alerts")
Ident=$( /usr/bin/awk '/id/{print $3}' <<< "$curler"  | sed 's/.$//' )
#room for improvement here as id exists twice within the json structure, but this just makes extra curls in the for loop that won't work
for alert in $Ident;do
if [[ $alert != -1 ]]; then
	curl -s -H "Authorization: Bearer $token" -H "accept: application/json" "$server/api/notifications/alerts/PATCH_UPDATE/$alert" -X DELETE
fi 
done
