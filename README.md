# AWS User Data to launch with EC2 Instance for a Splunk quick Lab install

This is a simple shell script to use as "User Data" when launching an AWS EC2 instance serving as a Splunk quick Lab.

It will install Splunk and perform a few configuration steps so that Splunk is accessible straight away without any of the actions usually required with a fresh install.

It will also retrieve Splunk Apps and Add-ons from a provided S3 bucket and install them.

The goal is to set up a throwable Splunk instance for Lab purposes without any dialog box to interfere.

## Getting Started

Follow these instructions to use the script.

### Prerequisites

To use this script as "User Data" to launch an EC2 instance, please consider these prerequisites:

## Provide the name of your S3 bucket:

```
sudo aws s3 cp s3://<s3_bucket_name>/ ./ --recursive
```

## Make sure your EC2 instance will be able to download content from your S3 bucket:

Either you can make your bucket public, or you can keep the bucket private and configure an IAM role that will grant S3 access from the EC2 instance.

If you choose the latter, you can simply attach the predefined policy named "AmazonS3FullAccess" to the created role.

Then you will have to pick the created role when configuring instance details for your EC2 instance.

## Make sure your EC2 instance is reachable on TCP ports 80 & 22 when configuring the security group for the EC2 instance.
