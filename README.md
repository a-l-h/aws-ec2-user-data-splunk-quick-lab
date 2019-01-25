## AWS User Data to launch with EC2 Instance for a Splunk quick Lab install

This is a simple shell script to use as "User Data" when launching an AWS EC2 instance serving as a Splunk quick Lab.

It will install Splunk and perform a few configuration steps so that Splunk is accessible straight away without any of the actions usually required with a fresh install.

It will also retrieve Splunk Apps and Add-ons from a provided S3 bucket and install them in the dedicated Splunk directory.

The goal is to set up a throwable Splunk instance for Lab purposes without any dialog box to interfere.

### Prerequisites

To use this script as "User Data" with an EC2 instance, please consider the prerequisites below.

#### Choose if you want to retrieve files from an S3 bucket or not

Set variable 'retrieve_s3_data' to yes or no:

```
# Do you need to retrieve Splunk Apps & Add-ons for an S3 bucket
readonly retrieve_s3_data="<yes|no>"
```

#### If yes, provide the name of your S3 bucket

Set 's3_bucket' variable to the name of your S3 bucket:

```
# Provide the name of the bucket you want to retrieve Splunk Apps and Add-ons from
readonly s3_bucket="<s3_bucket>"
```

#### Define a password for Splunk admin account

Set 'password' variable to the desired password:

```
# Provide the admin password you want to set
export password="<password>"
```

Upload custom or downloaded Apps and Add-ons as tgz|tar.gz|spl|zip files to your S3 bucket.

#### Make sure your EC2 instance can download content from your S3 bucket

You should first configure an IAM role that will grant access from the EC2 to your S3 bucket.

The predefined "AmazonS3FullAccess" policy should then be attached to the created role. 

Finally, the created role should be assigned to your EC2 instance.

#### Make sure your EC2 instance is reachable

Configure and assign a security group that will allow access to your EC2 instance on TCP ports 8000 & 22.

#### Notes

### Indexing cloud-init output

The output of the User Data script is written in /var/log/cloud-init-output.log.

The script configures Splunk to monitor this log file and index it in the '_internal' index under the 'aws:cloud-init' sourcetype so that data could be explored from Splunk.

### Splunk is run with ec2-user

This could be important to know while accessing the instance via ssh.

### Access Splunk on port 8000

Splunk default Web port is 8000. It has been left as-is to avoid messing with iptables.

### Splunk behavior on boot

Since a major change in version 7.2.2 (https://splk.it/2TeoAh7), enabling boot-start the way it was done in the script caused unexpected issues.

Hence, Splunk has not been configured to start at boot. I am looking for a viable solution.
