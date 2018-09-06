## AWS User Data to launch with EC2 Instance for a Splunk quick Lab install

This is a simple shell script to use as "User Data" when launching an AWS EC2 instance serving as a Splunk quick Lab.

It will install Splunk and perform a few configuration steps so that Splunk is accessible straight away without any of the actions usually required with a fresh install.

It will also retrieve Splunk Apps and Add-ons from a provided S3 bucket and install them in the dedicated Splunk directory.

The goal is to set up a throwable Splunk instance for Lab purposes without any dialog box to interfere.

### Prerequisites

To use this script as "User Data" with an EC2 instance, please consider the prerequisites below.

#### Provide the name of your S3 bucket

Edit this line of the script:

```
sudo aws s3 cp s3://<s3_bucket_name>/ ./ --recursive
```

Upload custom or downloaded Apps and Add-ons as tgz files to your S3 bucket.

#### Make sure your EC2 instance can download content from your S3 bucket

Either you can make your bucket public, or you can keep the bucket private and configure an IAM role that will grant S3 access from the EC2 instance.

If you choose the latter, you can simply attach the predefined policy named "AmazonS3FullAccess" to the created role.

Then, assign the created role to your EC2 instance.

#### Make sure your EC2 instance is reachable

Configure and assign a security group that will allow access to your EC2 instance on TCP ports 80 & 22.
