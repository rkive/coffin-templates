#
# Name::        elb.coffin
# Description:: Coffin template to create a Clodformation Stack with:
#                 * 3x Static instances in our VPC.
#                 * ELB w/ VPC subnets
#                 * Primarily to show how to do this without an autoscale group
#                 * Depends on: VPC & S3 stacks
#
# Copyright 2012, Aaron Bento
#
#

## Create 3 instances, one in each VPC Subnet
#
@AWS.EC2.Instance 'ec2instanceA'
  ImageId: 'ami-70f96e40' # Ubuntu 64-bit 12.04.02 EBS us-west2
  InstanceType: 't1.micro'
  KeyName: 'default'
  SecurityGroupIds: [ 'sg-34c2da58' ] # 'default' VPC Security Group
  Tags: [ @Tag 'name', 'ec2instanceA' ]  # @Tag is a coffin builtin shortcut to EC2 Tags.
  SubnetId: 'subnet-1c807374'
  IamInstanceProfile: 'chefBootstrapProfile'
  UserData:  @InitScript "#{path.resolve('.')}/support/simple-cloud-init.sh"

@AWS.EC2.Instance 'ec2instanceB'
  ImageId: 'ami-70f96e40' # Ubuntu 64-bit 12.04.02 EBS us-west2
  InstanceType: 't1.micro'
  KeyName: 'default'
  SecurityGroupIds: [ 'sg-34c2da58' ] # 'default' VPC Security Group
  Tags: [ @Tag 'name', 'ec2instanceB' ]  # @Tag is a coffin builtin shortcut to EC2 Tags.
  SubnetId: 'subnet-1280737a'
  IamInstanceProfile: 'chefBootstrapProfile'
  UserData:  @InitScript "#{path.resolve('.')}/support/simple-cloud-init.sh"

@AWS.EC2.Instance 'ec2instanceC'
  ImageId: 'ami-70f96e40' # Ubuntu 64-bit 12.04.02 EBS us-west2
  InstanceType: 't1.micro'
  KeyName: 'default'
  SecurityGroupIds: [ 'sg-34c2da58' ] # 'default' VPC Security Group
  Tags: [ @Tag 'name', 'ec2instanceC' ]  # @Tag is a coffin builtin shortcut to EC2 Tags.
  SubnetId: 'subnet-ea807382'
  IamInstanceProfile: 'chefBootstrapProfile'
  UserData:  @InitScript "#{path.resolve('.')}/support/simple-cloud-init.sh"


## Create our Loadbalancer.
## Break out the http_listner for better readability
http_listener =
  'LoadBalancerPort': '80'
  'InstancePort': '80'
  'Protocol': 'HTTP'

@AWS.ElasticLoadBalancing.LoadBalancer 'LoadBalancer'
  Subnets: [ 'subnet-1c807374', 'subnet-1280737a', 'subnet-ea807382' ]
  Listeners: [ http_listener ]
  HealthCheck:
    HealthyThreshold: 2
    Interval: 30
    Target: 'HTTP:80/healthcheck'
    Timeout: 5
    UnhealthyThreshold: 10
  SecurityGroups: [ 'sg-34c2da58' ]
  Instances: [ @Resources.ec2instanceA, @Resources.ec2instanceB, @Resources.ec2instanceC ]

