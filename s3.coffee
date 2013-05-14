#
# Name::        s3.coffin
# Description:: Coffin template to create a Clodformation Stack with:
#                 * S3 bucket
#                 * IAM Profile Role
#                 * Role Permissions to access S3 Bucket
#
# Copyright 2012, Aaron Bento
#
#
@Description "Cloudformation Stack containing s3 bucket and IAMProfile"

# First the bucket. Yup, that easy.
@AWS.S3.Bucket 'rkiveChefBootstrap'

## We are going to now create an IAM Profile Role that will allow an EC2 instance
## to access a set of automaticly rotatating API Access and Secret Keys. This
## will allow us to avoid putting AWS credentials into our scripts and git repos.
##
## We'll then give permisions to that role to access the S3 bucket which has
## the chef bootstrap artifacts.

# This allows EC2 instances to assume this role. It is required and can't change.
assumeRoleStatement = {
  "Statement": [{
    "Action": [ "sts:AssumeRole" ],
    "Effect": "Allow",
    "Principal": {
       "Service": [ "ec2.amazonaws.com" ]
    }
  }]
}

# Define a bit of JSON for our s3 policy. We keep it in JSON so we can copy/paste
# from the console a bit easier.
s3_policy = {
  "PolicyName": "chefBootstrapReadonly",
  "PolicyDocument": {
    "Statement": [{
      "Effect": "Allow",
      "Action": [ "s3:Get*", "s3:List*" ],
      "Resource": [
        @Join '', 'arn:aws:s3:::', @Resources.rkiveChefBootstrap
        @Join '', 'arn:aws:s3:::', @Resources.rkiveChefBootstrap, '/*'
      ]
    }]
  }
}


# IAM Role itself. We use to above blocks of JSON.
@AWS.IAM.Role 'chefBootstrapReadonlyRole'
  AssumeRolePolicyDocument: assumeRoleStatement
  Path: '/'
  Policies: [ s3_policy ]

# Create the Profile and assign the IAM role to it. EC2 instances will use this.
@AWS.IAM.InstanceProfile 'chefBootstrapProfile'
  Path: '/'
  Roles: [ @Resources.chefBootstrapReadonlyRole ]

