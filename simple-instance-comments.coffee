#
# Name:        simple-instance.coffee
# Description: Simple coffin template to create an ec2 instance with a Route 53
#              DNS name. Included inline are comments to the original JSON notation.
#

@Description 'Simple Coffin Cloudformation Stack ec2 + route 53'

# Cloudformation EC2 Resource Reference
# http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ec2-instance.html
#
# {
#   "Type" : "AWS::EC2::Instance",
#   "Properties" : {
#     "ImageId" : String,
#     "InstanceType" : String,
#     "KeyName" : String,
#     "SecurityGroups" : [ String, ... ],
#     "Tags" : [ EC2 Tag, ... ]
#   }
# }

# Coffin Resource Reference
# http://chrisfjones.github.io/coffin/
fqdn = 'ec2.example.com'

@AWS.EC2.Instance 'ec2instance'
  ImageId: 'ami-70f96e40' # Ubuntu 64-bit 12.04.02 EBS us-west2
  InstanceType: 't1.micro'
  KeyName: 'default'
  SecurityGroups: [ 'default' ]
  Tags: [ @Tag 'name', fqdn ]  # @Tag is a coffin builtin shortcut to EC2 Tags.

# Cloudformation Route53 Resource Reference
# http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-recordset.html#
#
# {
#  "Type" : "AWS::Route53::RecordSet",
#  "Properties" : {
#     "AliasTarget" : AliasTarget,
#     "Comment" : String,
#     "HostedZoneId" : String,
#     "HostedZoneName" : String,
#     "Name" : String,
#     "Region" : String,
#     "ResourceRecords" : [ String ],
#     "SetIdentifier" : String,
#     "TTL" : String,
#     "Type" : String,
#     "Weight" : Integer
#  }
# }

@AWS.Route53.RecordSet 'ec2instanceDns'
  HostedZoneId: 'ZQW8HSHA1G0KS'
  Name: fqdn
  TTL: '3600'
  Type: 'CNAME'
  ResourceRecords: [
    @GetAtt "ec2instance", 'PublicDnsName' # @GetAtt is an alias to FN:GetAtt
  ]


# Cloudformation Outputs Declaration Resource
# http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html
#
# "Outputs" : {
#     "URL" : {
#         "Value" : "http://aws.amazon.com/cloudformation"
#     }
# }

@Output "InstanceId", @Resources.ec2instance  # @Resources is an alias to @Ref
@Output "DNSName", @Resources.ec2instanceDns




