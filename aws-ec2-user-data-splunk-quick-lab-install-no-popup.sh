#!/usr/bin/env bash

# This is a simple shell script to use as "User Data" when launching an AWS EC2 instance serving as a Splunk quick Lab.
#
# It will install Splunk and perform a few configuration steps so that Splunk is accessible straight away without any of the actions usually required after a fresh install.
#
# It will also retrieve Splunk Apps and Add-ons from a provided S3 bucket and install them in the dedicated Splunk directory.
#
# The goal is to set up a throwable Splunk instance for Lab purposes without any dialog box to interfere.
#
# More info on github : https://github.com/d2si-spk/aws-ec2-user-data-splunk-quick-lab-install-no-popup

# Set the script to exit when a command fails
set -o errexit

# Set the script to produce a failure return code if any command errors between pipelines 
set -o pipefail

# Set the script to exit when it tries to use undeclared variables
set -o nounset

# Provide the name of the bucket you want to retrieve Splunk Apps and Add-ons from
readonly s3_bucket="<s3_bucket>"

# Provide the admin password you want to set
export password="<password>"

# Set $SPLUNK_HOME variable
export SPLUNK_HOME="/opt/splunk"

# Download the latest Splunk version

wget --quiet --output-document splunk-latest-linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=latest&product=splunk&filename=.tgz&wget=true'

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 1/18 - Downloaded latest Splunk build"

# Unpack Splunk tgz file in /opt

tar --extract --gzip --file splunk-latest-linux-x86_64.tgz --directory /opt

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 2/18 - Extracted Splunk to /opt/"

# Delete Splunk tgz file

rm --recursive --force splunk-latest-linux-x86_64.tgz

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 3/18 - Removed Splunk installation source"

# Customize global bash prompt with color, shortcut for $SPLUNK_HOME/bin directory, and auto-completion script so it can be used by both root and ec2-user users

{
  echo "export PS1='\[\033[1;32m\]\$(whoami)@\$(hostname): \[\033[0;37m\]\$(pwd)\$ \[\033[0m\]'"
  echo "export SPLUNK_HOME=\"/opt/splunk\""
  echo "export PATH=\${SPLUNK_HOME}/bin:\${PATH}"
  echo ". \${SPLUNK_HOME}/share/splunk/cli-command-completion.sh"
} >> /etc/bashrc

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 4/18 - Configured global bash prompt"

# Download Splunk Apps and Add-ons from S3 bucket

aws s3 cp s3://"${s3_bucket}"/ ./ --quiet --recursive --exclude "*" --include "*.tgz"  --include "*.tar.gz" --include "*.spl" --include "*.zip" || true

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 5/18 - Downloaded Apps & Add-ons from s3 bucket ${s3_bucket}"

# Unpack downloaded tgz files in /etc/apps

cat ./*.tgz | tar --extract --gzip --file - --ignore-zeros --directory "${SPLUNK_HOME}"/etc/apps || true

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 6/18 - Extracted Apps & Add-ons to ${SPLUNK_HOME}/etc/apps"

# Delete retrieved Apps and Add-ons

rm --recursive --force ./*.tgz ./*.tar.gz ./*.spl ./*.zip

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 7/18 - Removed Apps & Add-ons from source directory"

# Create directories for the 'user_data_no_popup_app' that will be configured through the script 

mkdir --parents "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/metadata

# Set metadata permissions for the App

{
  echo "[]"
  echo "access = read : [ * ], write : [ admin ]"
  echo "export = system"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/metadata/local.meta

# Set Splunk to monitor the output of User Data script  and index it in _internal index

{
  echo "[monitor:///var/log/cloud-init-output.log]" 
  echo "index = _internal"
  echo "sourcetype = aws:cloud-init"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/inputs.conf

{
  echo "[aws:cloud-init]"
  echo "TIME_FORMAT =%a, %d %b %Y %H:%M:%S %z"
  echo "BREAK_ONLY_BEFORE = ^Cloud-init|^[A-Za-z]{3}\,\s\d{1,2}\s[A-Za-z]{3}\s\d{4}\s\d{2}\:\d{2}\:\d{2}"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/props.conf

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 8/18 - Configured monitoring for User Data logs"

# Prevent Splunk Web from checking for newer versions

{
  echo "[settings]"
  echo "updateCheckerBaseURL = 0"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/web.conf

# Set user preferences to avoid being spammed with system messages

{
  echo "[general]"
  echo "render_version_messages = 0"
  echo "dismissedInstrumentationOptInVersion = 3" 
  echo "hideInstrumentationOptInModal = 1"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/user-prefs.conf

# Configure password policy to allow a password shorter than the default minimum of 8 characters

{
  echo "[splunk_auth]"
  echo "minPasswordLength = 1"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/authentication.conf

# Set a lower limit on disk usage

{
  echo "[diskUsage]"
  echo "minFreeSpace = 2000"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/server.conf

# Configure any ui-tour as already viewed to avoid popups

{
  echo "[default]"
  echo "viewed = 1"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/ui-tour.conf

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 9/18 - Set some configurations to avoid popups"

# Redirect Splunk Web port 8000 to port 80 to reach it only with IP address through Web browser

iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 10/18 - Redirected port 8000 to port 80"

# Fake a previous login to prevent Splunk from requesting password change

touch "${SPLUNK_HOME}"/etc/.ui_login

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 11/18 - Faked a previous UI login"

# Set Splunk to start the service as the user 'ec2-user' 

echo "SPLUNK_OS_USER=ec2-user" >> "${SPLUNK_HOME}"/etc/splunk-launch.conf

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 12/18 - Set ec2-user as the user to start the Splunk service with"

# Change the ownership of the Splunk directory to the ec2-user

chown -R ec2-user:ec2-user "${SPLUNK_HOME}"

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 13/18 - Changed ${SPLUNK_HOME} ownership to ec2-user"

# Start Splunk, accept license and set a admin password

sudo -E -u ec2-user bash -c '${SPLUNK_HOME}/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd ${password}'

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 14/18 - Set Splunk admin password"

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 15/18 - Accepted Splunk license"

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 16/18 - Started Splunk"

# Configure Splunk to start at boot time

"${SPLUNK_HOME}"/bin/splunk enable boot-start -user ec2-user

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 17/18 - Configured Splunk to start at boot time"

# Perform system update

yum --setopt=deltarpm=0 update --quiet --assumeyes

echo "$(date '+%a, %d %b %Y %H:%M:%S %z') - 18/18 - Performed a system update"
