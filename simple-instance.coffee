#
# Name:        simple-instance.coffee
# Description: Simple coffin template to create an ec2 instance with a Route 53
#              DNS name
#

@Description 'Simple Coffin Cloudformation Stack ec2 + route 53'

fqdn = 'ec2.example.com'

@AWS.EC2.Instance 'ec2instance'
  ImageId: 'ami-70f96e40' # Ubuntu 64-bit 12.04.02 EBS us-west2
  InstanceType: 't1.micro'
  KeyName: 'default'
  SecurityGroups: [ 'default' ]
  Tags: [ @Tag 'name', fqdn ]  # @Tag is a coffin builtin shortcut to EC2 Tags.

@AWS.Route53.RecordSet 'ec2instanceDns'
  HostedZoneId: 'ZQW8HSHA1G0KS'
  Name: fqdn
  TTL: '3600'
  Type: 'CNAME'
  ResourceRecords: [
    @GetAtt "ec2instance", 'PublicDnsName' # @GetAtt is an alias to FN:GetAtt
  ]

@Output "InstanceId", @Resources.ec2instance  # @Resources is an alias to @Ref
@Output "DNSName", @Resources.ec2instanceDns




