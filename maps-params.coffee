#
# Name:        maps-params.coffee
# Description: Simple coffin template to illustrate using @Mapping and @Param
#
#

@Description 'Simple Coffin Cloudformation Stack ec2 + route 53'

@Param.String 'InstanceSize',  Default: 't1.micro'
@Param.String 'InstanceStore', Default: 'ebs'
@Param.String 'SecurityGroup', Default: 'default'
@Param.String 'KeyName',       Default: 'default'
@Param.String 'HostedZoneId',  Default: 'Zxxxxxxxxxxx'

# Assume 64-bit and use Ubuntu default AMI's.
@Mapping 'RegionType2AMI'
  'us-west-2':
    ebs:      'ami-70f96e40'
    instance: 'ami-eefa6dde'
  'us-east-1':
    ebs:      'ami-d0f89fb9'
    instance: 'ami-2efa9d47'

# Create our instance
@AWS.EC2.Instance 'ec2instance',
  ImageId:        @FindInMap('RegionType2AMI', Ref: @Region, 'ebs')
  InstanceType:   @Params.InstanceSize
  KeyName:        @Params.KeyName
  SecurityGroups: [ @Params.SecurityGroup ]
  Tags:           [ @Tag 'name', Ref: @Region ]

@AWS.Route53.RecordSet 'ec2instanceDns'
  HostedZoneId: @Params.InstanceSize
  Name: 'ec2.example.com'
  TTL: '3600'
  Type: 'CNAME'
  ResourceRecords: [ @GetAtt "ec2instance", 'PublicDnsName' ]

@Output 'region',     Ref: @Region
@Output 'ebsAMI',     @FindInMap('RegionType2AMI', Ref: @Region, 'ebs')
@Output "InstanceId", @Resources.ec2instance
