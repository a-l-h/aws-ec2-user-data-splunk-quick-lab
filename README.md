# AWS EC2 User Data script to launch a quick Splunk lab install

This is a simple shell script to use as 'User Data' when launching an Amazon Linux AMI based AWS EC2 instance serving as a Splunk quick Lab.

It will install Splunk and perform a few configuration steps so that Splunk is accessible straight away without any of the actions usually required with a fresh install.

It will also retrieve Splunk Apps and Add-ons from a provided S3 bucket and install them.

The goal is to set up a throwable Splunk instance for lab purposes without any dialog box to interfere.

## Use the User Data script

### Adjust the script to your needs

#### Define a password for Splunk admin account

Set `password` variable

```shell
# Provide the Splunk admin password you want to set
export password="<password>"
```

#### If you want to retrieve files from an S3 bucket

1. Set `retrieve_s3_data` variable to true 

```shell
# Do you need to retrieve Splunk Apps & Add-ons for an S3 bucket
readonly retrieve_s3_data="true"
```

2. Set `s3_bucket` variable to the name of your S3 bucket

```shell
# Provide the name of the bucket you want to retrieve Splunk Apps and Add-ons from
readonly s3_bucket="<s3_bucket>"
```

### Adjust the AWS side

Launch an AWS EC2 based on Amazon Linux 2 AMI.

#### Make sure your EC2 instance is reachable

1. [Configure a security group to allow inbound HTTP and SSH traffic](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/authorizing-access-to-an-instance.html#add-rule-authorize-access).

2. [Assign the security to your EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/authorizing-access-to-an-instance.html#assign-security-group-to-instance).

#### If you want to retrieve files from an S3 bucket

1. [Allow connection to your S3 bucket from your EC2 instance](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-instance-access-s3-bucket/).

2. [Upload custom or downloaded Apps and Add-ons as tgz|tar.gz|spl|zip files to your S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/upload-objects.html).

### Copy the script in the User data field

[Copy the modified script in the User data field when launching an instance from the Launch Instance Wizard](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-console).

**Launch EC2 quick steps**

1. Launch instance - Pick an 'Amazon Linux 2' AMI
2. [Optional] Configure instance details - Specify IAM role if you are retrieving data from S3
2. Configure instance details - Copy script in User data field
3. [Optional] Add tags
4. Configure Security Group - Assign the Security Group allowing HTTP & SSH
5. Launch - Pick the right key pair

### Access Splunk Web

When your EC2 instance is launched, you should be able to access Splunk Web from your browser

```
http://<EC2 Public IP | Public DNS>
```

### SSH Access

[Connect to your EC2 via SSH](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html).

Not that Splunk runs as ``ec2-user``.

#### Notes

### Indexing cloud-init output

The output of the User Data script is written in /var/log/cloud-init-output.log.

The script configures Splunk to monitor this log file and index it in the internal index under the 'aws:cloud-init' sourcetype so that data could be explored from Splunk if needed:

```
index="_internal" sourcetype="aws:cloud-init" | reverse
```

### Splunk behavior on boot

Splunk is configured to start at boot time. Hence, whenever you start your instance, Splunk starts.
