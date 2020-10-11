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

# Do you need to retrieve Splunk Apps & Add-ons for an S3 bucket
readonly retrieve_s3_data="false"

# If the retrieve_s3_data is set to "true", provide the name of the bucket you want to retrieve files from
readonly s3_bucket="<s3_bucket>"

# Provide the Splunk admin password you want to set
export password="<password>"

# Set $timestamp variable for logging
timestamp=$(date '+%a, %d %b %Y %H:%M:%S %z')

# Set $SPLUNK_HOME variable
export SPLUNK_HOME="/opt/splunk"

# Download the latest Splunk version
wget --quiet --output-document splunk-latest-linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=latest&product=splunk&filename=.tgz&wget=true'

echo "${timestamp} - 1/20 - Downloaded latest Splunk build"

# Unpack Splunk tgz file in /opt
tar --extract --gzip --file splunk-latest-linux-x86_64.tgz --directory /opt

echo "${timestamp} - 2/20 - Extracted Splunk to /opt/"

# Delete Splunk tgz file
rm --recursive --force splunk-latest-linux-x86_64.tgz

echo "${timestamp} - 3/20 - Removed Splunk installation source"

# Customize global bash prompt with color, shortcut for $SPLUNK_HOME/bin directory, and auto-completion script so it can be used by both root and ec2-user users

{
  echo "export PS1='\[\033[1;32m\]\$(whoami)@\$(hostname): \[\033[0;37m\]\$(pwd)\$ \[\033[0m\]'"
  echo "export SPLUNK_HOME=\"/opt/splunk\""
  echo "export PATH=\${SPLUNK_HOME}/bin:\${PATH}"
  echo ". \${SPLUNK_HOME}/share/splunk/cli-command-completion.sh"
} >> /etc/bashrc

echo "${timestamp} - 4/20 - Configured global bash prompt"

# If variable retrieve_s3_data is set to "true", proceed

if [ "$retrieve_s3_data" = "true" ]; then

	# Download Splunk Apps and Add-ons from S3 bucket

	aws s3 cp s3://"${s3_bucket}"/ ./ --quiet --recursive --exclude "*" --include "*.tgz" --include "*.tar.gz" --include "*.spl" --include "*.zip" || true

	echo "${timestamp} - 5/20 - Downloaded Apps & Add-ons from s3 bucket ${s3_bucket}"

	# Unpack downloaded tgz files in /etc/apps

	cat ./*.tgz | tar --extract --gzip --file - --ignore-zeros --directory "${SPLUNK_HOME}"/etc/apps || true

	echo "${timestamp} - 6/20 - Extracted Apps & Add-ons to ${SPLUNK_HOME}/etc/apps"

	# Delete retrieved Apps and Add-ons

	rm --recursive --force ./*.tgz ./*.tar.gz ./*.spl ./*.zip

	echo "${timestamp} - 7/20 - Removed Apps & Add-ons from source directory"

fi

# If variable retrieve_s3_data is set to "false", proceed

if [ "$retrieve_s3_data" = "false" ]; then

	echo "${timestamp} - 5-7/20 - Choice was made to not retrieve files from AWS"

fi

# Create directories for the 'user_data_no_popup_app' that will be configured through the script 

mkdir --parents "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/metadata

# Set metadata permissions for the App

{
  echo "[]"
  echo "access = read : [ * ], write : [ admin ]"
  echo "export = system"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/metadata/local.meta

# Set Splunk to monitor the output of User Data script and index it in _internal index

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

echo "${timestamp} - 8/20 - Configured monitoring for User Data logs"

# Prevent Splunk Web from checking for newer versions

{
  echo "[settings]"
  echo "updateCheckerBaseURL = 0"
} > "${SPLUNK_HOME}"/etc/apps/user_data_no_popup_app/local/web.conf

# Set user preferences to avoid being spammed with system messages

{
  echo "[general]"
  echo "render_version_messages = 0"
  echo "dismissedInstrumentationOptInVersion = 4" 
  echo "hideInstrumentationOptInModal = 1"
  echo "notification_python_3_impact = false"
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

echo "${timestamp} - 9/20 - Set some configurations to avoid popups"

# Fake a previous login to prevent Splunk from requesting password change

touch "${SPLUNK_HOME}"/etc/.ui_login

echo "${timestamp} - 10/20 - Faked a previous UI login"

# Change the ownership of the Splunk directory to the ec2-user

chown -R ec2-user:ec2-user "${SPLUNK_HOME}"

echo "${timestamp} - 11/20 - Changed ${SPLUNK_HOME} ownership to ec2-user"

# Start Splunk, accept license and set a admin password

echo "${timestamp} - 12/20 - Set Splunk admin password"

echo "${timestamp} - 13/20 - Accepted Splunk license"

echo "${timestamp} - 14/20 - Started Splunk"

sudo -E -u ec2-user bash -c '${SPLUNK_HOME}/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "${password}"'

# Configure Splunk to start at boot time

echo "${timestamp} - 15/20 - Set Splunk to start at boot time"

sudo "${SPLUNK_HOME}"/bin/splunk enable boot-start -systemd-managed 0 -user ec2-user

# Install iptables-services

sudo yum --setopt=deltarpm=0 install iptables-services --quiet --assumeyes

echo "${timestamp} - 16/20 - Installed iptables-services"

# Redirect port 80 to port 8000 using iptables

sudo iptables --table nat --append PREROUTING --protocol tcp --dport 80 --jump REDIRECT --to-port 8000

echo "${timestamp} - 17/20 - Redirected port 80 to port 8000 using iptables"

# Save iptables configuration to make it persistent

echo "${timestamp} - 18/20 - Saved iptables configuration to make it persistent"

sudo service iptables save

# Enable iptables-services at boot time

echo "${timestamp} - 19/20 - Enabled iptables-services at boot time"

sudo systemctl enable iptables

# List installed Apps

echo "${timestamp} - 20/20 - Installed Apps list:"

sudo -E -u ec2-user bash -c '${SPLUNK_HOME}/bin/splunk display app -auth admin:"${password}"'
