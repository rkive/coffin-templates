#!/bin/bash -ex
#
# This script installs Chef, performs minimal chef configuration, and registers
# with Hosted Chef server.

# Download and install the Chef Omnibus installer
# Latest version info can be found at http://www.opscode.com/chef/install/
PACKAGE="chef_11.4.0-1.ubuntu.11.04_amd64.deb"
curl -o /opt/$PACKAGE https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/11.04/x86_64/$PACKAGE
dpkg --install /opt/$PACKAGE

# Grab boto for AMI IAM Role maagic
apt-get install git -y
git clone https://github.com/boto/boto.git /tmp/boto
cd /tmp/boto;python setup.py install

CHEFDIR="/etc/chef"
BOTODIR="/usr/local/bin/"
S3BUCKET="s3://rkiveChefBootstrap/"

mkdir -p $CHEFDIR
$BOTODIR/fetch_file -o $CHEFDIR/validation.pem $S3BUCKET/validation.pem
$BOTODIR/fetch_file -o $CHEFDIR/client.rb $S3BUCKET/client.rb
$BOTODIR/fetch_file -o $CHEFDIR/runlist.json $S3BUCKET/runlist.json

# Perform two runs. The first to ensure that we are registered with server if the runlist fails.
chef-client --once --log_level debug --logfile /var/log/chef-client-registration.log
chef-client -j /etc/chef/runlist.json --once --log_level debug --logfile /var/log/chef-client-runlist.log
rm -rf $CHEFDIR/validation.pem

touch /home/ubuntu/cloud-init-complete
