#!/bin/bash

# Download the latest Splunk version

wget -O splunk-latest-linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=latest&product=splunk&filename=.tgz&wget=true'

# Untar Splunk tgz file in /opt

sudo tar xvzf splunk-latest-linux-x86_64.tgz -C /opt

# Delete Splunk tgz file

sudo rm -rf splunk-latest-linux-x86_64.tgz

# Download content from S3 bucket

sudo aws s3 cp s3://<s3_bucket_name>/ ./ --recursive

# Untar downloaded tgz files in /etc/apps

cat *.tgz | sudo tar xvzf - -i -C /opt/splunk/etc/apps

# Customize bash prompt with color, shortcut for $SPLUNK_HOME/bin directory, and auto-completion script

echo 'export PS1="\e[0;32m[\u@\h \W]\$ \e[m"' >> ~/.bashrc
echo 'export SPLUNK_HOME=/opt/splunk' >> ~/.bashrc
echo 'export PATH=$PATH:$SPLUNK_HOME/bin' >> ~/.bashrc
echo '. $SPLUNK_HOME/share/splunk/cli-command-completion.sh'  >> ~/.bashrc

source ~/.bashrc

# Set Splunk Web to run on port 80 and block it from checking for newer version

echo '[settings]' | sudo tee /opt/splunk/etc/system/local/web.conf
echo 'httpport = 80' | sudo tee --append /opt/splunk/etc/system/local/web.conf
echo 'updateCheckerBaseURL = 0' | sudo tee --append /opt/splunk/etc/system/local/web.conf

# Set user preferences to avoid being spammed with system messages

echo '[general]' | sudo tee /opt/splunk/etc/system/local/user-prefs.conf
echo 'render_version_messages = 0' | sudo tee --append /opt/splunk/etc/system/local/user-prefs.conf
echo 'dismissedInstrumentationOptInVersion = 3'  | sudo tee --append /opt/splunk/etc/system/local/user-prefs.conf
echo 'hideInstrumentationOptInModal = 1' | sudo tee --append /opt/splunk/etc/system/local/user-prefs.conf

# Configure password policy to allow a password shorter than the default minimum of 8 characters

echo '[splunk_auth]' | sudo tee /opt/splunk/etc/system/local/authentication.conf
echo 'minPasswordLength = 1' | sudo tee --append /opt/splunk/etc/system/local/authentication.conf

# Fake a previous login to prevent Splunk from requesting password change

sudo touch /opt/splunk/etc/.ui_login

# Start Splunk and set a new password

sudo /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd <password>

# Configure Splunk to start at boot time

sudo /opt/splunk/bin/splunk enable boot-start

# Update the system

sudo yum update -y
