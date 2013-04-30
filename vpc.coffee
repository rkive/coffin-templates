#
# Name::        vpc.coffin
# Description:: Coffin template to create a Clodformation Stack with:
#                 * VPC
#                 * 3x Subnets
#                 * Internet Gateway
#                 * Routeing Table
#                 * Network ACL's
#                 * Resource connections between above items.
#
# Copyright 2012, Aaron Bento
#
#
@Description "Cloudformation Stack containing all VPC's"

stack_name = 'Test VPC Stack 10.2/16'

####### VPC ######
# Our foundation for everything
#
@AWS.EC2.VPC "vpcWest02",
  CidrBlock: "10.2.0.0/16"
  Tags: [ @Tag 'Name', stack_name ]



###### Subnets ######
# We are going to need at least 1 subent for each AZ we choose to use.
# Since we want to sit in at least 3 AZ's, we'll start out with 3 subnets.
#
@AWS.EC2.Subnet 'vpcWest02Subnet00',
  VpcId: @Resources.vpcWest02
  AvailabilityZone: 'us-west-2a'
  CidrBlock: "10.2.0.0/24"
  Tags: [ @Tag 'Name', stack_name ]

@AWS.EC2.Subnet 'vpcWest02Subnet01',
  VpcId: @Resources.vpcWest02
  AvailabilityZone: 'us-west-2b'
  CidrBlock: "10.2.1.0/24"
  Tags: [ @Tag 'Name', stack_name ]

@AWS.EC2.Subnet 'vpcWest02Subnet02',
  VpcId: @Resources.vpcWest02
  AvailabilityZone: 'us-west-2c'
  CidrBlock: "10.2.2.0/24"
  Tags: [ @Tag 'Name', stack_name ]



###### Internet Gateways #######
#
# Internet Gateway's have no setable properties, but you need to create one.
@AWS.EC2.InternetGateway 'vpcWest02Gateway',
  Tags: [ @Tag 'Name', stack_name ]

# Connect the dots, la la la. In this case the dots are VPC & Gateway.
@AWS.EC2.VPCGatewayAttachment 'vpcWest02GatewayAttachment',
  VpcId: @Resources.vpcWest02
  InternetGatewayId: @Resources.vpcWest02Gateway



###### Route Table #######
# We now need to Create a route table that we'll attach routes to.
#
@AWS.EC2.RouteTable 'vpcWest02RouteTable',
  VpcId: @Resources.vpcWest02
  Tags: [ @Tag 'Name', stack_name ]

# Connect the dots, la la la. In this case the dots are Gateway & Route Table.
@AWS.EC2.Route 'vpcWest02RouteDefault',
  RouteTableId: @Resources.vpcWest02RouteTable
  DestinationCidrBlock: '0.0.0.0/0'
  GatewayId: @Resources.vpcWest02Gateway



###### Network Access Control Layer #######
# We need to define Network ACL's, but we are going set them wide open.
# We'll control traffic at the SecurityGroup & Instance level.
#
@AWS.EC2.NetworkAcl 'vpcWest02NetworkAclIngress',
  VpcId: @Resources.vpcWest02
  Tags: [ @Tag 'Name', stack_name ]

# Add inbound wide-open
@AWS.EC2.NetworkAclEntry 'vpcWest02NetworkAclIngressEntry100',
  NetworkAclId: @Resources.vpcWest02NetworkAclIngress
  RuleNumber: '100'
  Protocol: '6'
  RuleAction: 'allow'
  Egress: 'false'
  CidrBlock: '0.0.0.0/0'
  PortRange:
    From: '0'
    To: '65535'

# Add outbound wide-open
@AWS.EC2.NetworkAclEntry 'vpcWest02NetworkAclEgressEntry100',
  NetworkAclId: @Resources.vpcWest02NetworkAclIngress
  RuleNumber: '100'
  Protocol: '6'
  RuleAction: 'allow'
  Egress: 'true'
  CidrBlock: '0.0.0.0/0'
  PortRange:
    From: '0'
    To: '65535'

# Connect the dots, la la la. In this case the dots are subnet & Network ACL.
@AWS.EC2.SubnetNetworkAclAssociation 'vpcWest02SubnetNetworkAclAssociation00',
  SubnetId: @Resources.vpcWest02Subnet00
  NetworkAclId: @Resources.vpcWest02NetworkAclIngress

@AWS.EC2.SubnetNetworkAclAssociation 'vpcWest02SubnetNetworkAclAssociation01',
  SubnetId: @Resources.vpcWest02Subnet01
  NetworkAclId: @Resources.vpcWest02NetworkAclIngress

@AWS.EC2.SubnetNetworkAclAssociation 'vpcWest02SubnetNetworkAclAssociation02',
  SubnetId: @Resources.vpcWest02Subnet02
  NetworkAclId: @Resources.vpcWest02NetworkAclIngress
