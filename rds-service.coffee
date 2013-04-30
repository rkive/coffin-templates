#
# Name::        rds-service.coffin
# Description:: Simple Coffin template to create a Clodformation Stack with:
#                 * MySQL RDS instance
#                 * RDS Security Group instance
#                 * Route53 entry

@Description 'MySQL RDS + R53 DNS entry.'

# Some Parameters used by Chef.
@Param.String 'environment'

# Standard RDS Parameters
@Param.String 'r53ZoneId',       Default: 'Zxxxxxxxxxxx'
@Param.String 'r53ZoneName',     Default: 'example.com'
@Param.String 'keyName',         Default: 'default'
@Param.String 'securityGroup',   Default: 'default'
@Param.String 'DBName',          Default: 'development'
@Param.String 'diskSize',        Default: '5'
@Param.String 'DBInstanceClass', Default: 'db.m1.small'

## Create an MySQL RDS instances.
## TODO: Break this out into a substack
@AWS.RDS.DBInstance "MySqlRds",
  Engine: 'MySQL'
  DBName: @Params.DBName
  Port: '3306'
  AllocatedStorage: @Params.diskSize
  MasterUsername: 'admin'
  MasterUserPassword: 'SuperDuperSecure'
  DBInstanceClass: @Params.DBInstanceClass
  DBSecurityGroups: [ @Params.securityGroup ]

@AWS.RDS.DBSecurityGroup "MySqlRdsSecurityGroup",
  GroupDescription: "Security Group for RDS #{name}"
  DBSecurityGroupIngress:
    EC2SecurityGroupName: @Params.securityGroup
    EC2SecurityGroupOwnerId: @Params.accountID

@AWS.Route53.RecordSet "MySqlRdsDns",
  HostedZoneId: @Params.r53ZoneId
  Name: @Join '.', @Params.name, @Params.environment, @Params.r53ZoneName
  Type: 'CNAME'
  TTL: '60'
  ResourceRecords: [ @GetAtt name, 'Endpoint.Address' ]

@Output "rdsdnsname", @Resources.MySqlRdsDns