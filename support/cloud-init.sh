#!/bin/bash -ex
#
# This script installs Chef, performs minimal hostname configuration, chef runlist
# config, and registers with Hosted or Chef server.

# These values are passed in from our Coffin template.
HOSTNAME="#{@Params.hostname}"
HOSTEDZONEID="#{@Params.HostedZoneId}"
HOSTEDZONENAME="#{@Params.HostedZoneName}"

CHEF_ENVIRONMENT="#{@Params.chefenvironment}"
CHEF_RUNLIST=#{@Params.chefrunlist}
CHEF_SERVER_URL="#{@Params.chefserverurl}"
CHEF_VALIDATION_NAME="#{@Params.chefvalidationname}"
CHEF_VALIDATION_PEM="#{@Params.chefvalidationpem}"

# Grab some Metadata info
EC2HOSTNAME=`curl -s http://169.254.169.254/latest/meta-data/public-hostname`
INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
FQDN="$HOSTNAME-$INSTANCE_ID.$HOSTEDZONENAME"

CHEFDIR="/etc/chef"
BOTODIR="/usr/local/bin/"

# Download and install the Chef Omnibus installer
# Latest version info can be found at http://www.opscode.com/chef/install/
PACKAGE="chef_11.4.0-1.ubuntu.11.04_amd64.deb"
curl -o /opt/$PACKAGE https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/11.04/x86_64/$PACKAGE
dpkg --install /opt/$PACKAGE

# Set the system hostname.
hostname $FQDN
echo $FQDN > /etc/hostname
echo $FQDN > /etc/mailname

(
cat <<EOP
127.0.0.1 $FQDN $HOSTNAME localhost
169.254.169.254 metadata
EOP
) > /etc/hosts

# Grab boto for AMI IAM Role maagic
apt-get install git -y
git clone https://github.com/boto/boto.git /tmp/boto
cd /tmp/boto;python setup.py install


# Create an alias record to the ec2 public hostname.
$BOTODIR/route53 add_record $HOSTEDZONEID $FQDN CNAME $EC2HOSTNAME

mkdir -p $CHEFDIR
$BOTODIR/fetch_file -o $CHEFDIR/validation.pem $CHEF_VALIDATION_PEM
(
cat <<EOP
log_level :debug
log_location '/var/log/chef-client.log'
chef_server_url "$CHEF_SERVER_URL"
validation_client_name "$CHEF_VALIDATION_NAME"
environment "$CHEF_ENVIRONMENT"
node_name "$FQDN"
EOP
) > $CHEFDIR/client.rb
(
cat <<EOP
{"run_list":["role[base]","$CHEF_RUNLIST"]}
EOP
) > $CHEFDIR/runlist.json

# Perform two runs. The first to ensure that we are registered with server if the runlist fails.
chef-client --once --log_level debug --logfile /var/log/chef-client-registration.log
chef-client -j /etc/chef/runlist.json --once --log_level debug --logfile /var/log/chef-client-runlist.log
rm -rf $CHEFDIR/validation.pem

touch ~/cloud-init-complete
