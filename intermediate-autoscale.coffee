#
# Name:        intermediate-autoscale.coffee
# Description: A more involved example illustrating the creation of an autoscaler group
#              This example also reads informetion from a chef environment file
#              for most of it's default parameters. Be sure you export CHEF_REPO_PATH
#              to your current chef-repo directory.
#
chef_environment = @ARGV[0] || "development"
chef_env_file    = "#{process.env.CHEF_REPO_PATH}/environments/#{chef_environment}.json"
chef_env         = JSON.parse fs.readFileSync(chef_env_file)

cloud_env = chef_env.cloudformation

## Small Function to string some chef roles together.
roles               = ['webserver']
build_run_list = (roles) ->
  runlist = ("\"role[#{r}]\"" for r in roles)
  return runlist.join ','

## The core Cloudformation template
@Description 'Autoscale Group(w/LaunchConfig) + ELB + Route53'

# Params specific to this template.
@Param.String 'chefenvironment',       Default: chef_env.name
@Param.String 'chefrunlist',           Default: build_run_list roles

@Param.String 'IamInstanceProfile',    Default: cloud_env.webserver.iam_instance_profile
@Param.String 'InstanceSize',          Default: cloud_env.webserver.instance_size
@Param.String 'InstanceStore',         Default: cloud_env.webserver.instance_store
@Param.String 'SecurityGroup',         Default: cloud_env.webserver.security_group
@Param.String 'KeyName',               Default: cloud_env.webserver.keypair
@Param.String 'HealthCheckUrl',        Default: cloud_env.webserver.HealthCheckUrl
@Param.String 'HostedZoneId',          Default: cloud_env.r53.zone_id
@Param.String 'HostedZoneName',        Default: cloud_env.r53.zone_name
@Param.String 'minAutoScaleInstances', Default: cloud_env.webserver.minAutoScaleInstances
@Param.String 'maxAutoScaleInstances', Default: cloud_env.webserver.maxAutoScaleInstances

@Param.String 'hostname',              Default: cloud_env.webserver.hostname

@Param.String 'chefserverurl',         Default: cloud_env.chef.server_url
@Param.String 'chefvalidationname',    Default: cloud_env.chef.validation_name
@Param.String 'chefvalidationpem',     Default: cloud_env.chef.validation_pem

## Assume 64-bit and use Ubuntu default AMI's.
@Mapping 'RegionType2AMI'
  'us-west-2':
    ebs:      'ami-70f96e40'
    instance: 'ami-eefa6dde'
  'us-east-1':
    ebs:      'ami-d0f89fb9'
    instance: 'ami-2efa9d47'

## Create our Loadbalancer.
## Break out the http_listner for better readability
http_listener =
  'LoadBalancerPort': '80'
  'InstancePort': '80'
  'Protocol': 'HTTP'

@AWS.ElasticLoadBalancing.LoadBalancer 'LoadBalancer'
  AvailabilityZones:    @GetAZs(Ref: @Region)
  Listeners: [ http_listener ]
  HealthCheck:
    HealthyThreshold: 3
    Interval: 10
    Target:  @Params.HealthCheckUrl
    Timeout: 9
    UnhealthyThreshold: 3

## Security Group to allow Traffic from the ELB to all autoscaled instances.
@AWS.EC2.SecurityGroup 'ELBSecurityGroup'
  GroupDescription: "Allow port 80 between ELB and Autoscaled Instances"
  SecurityGroupIngress: [
    IpProtocol: 'tcp'
    FromPort: '80'
    ToPort: '80'
    SourceSecurityGroupOwnerId: @GetAtt 'LoadBalancer', 'SourceSecurityGroup.OwnerAlias'
    SourceSecurityGroupName:    @GetAtt 'LoadBalancer', 'SourceSecurityGroup.GroupName'
  ]

## Create our launch config to create our instances.
## Also attach to ELBSecurityGrouprop and a cloud-init bootscript.
@AWS.AutoScaling.LaunchConfiguration 'LaunchConfiguration',
  ImageId:            @FindInMap('RegionType2AMI', Ref: @Region, 'ebs')
  InstanceType:       @Params.InstanceSize
  KeyName:            @Params.KeyName
  SecurityGroups:     [ @Params.SecurityGroup, @Resources.ELBSecurityGroup ]
  IamInstanceProfile: @Params.IamInstanceProfile
  UserData:           @InitScript "#{path.resolve('.')}/support/cloud-init.sh"

## Autoscaler Group will include the launchconfig and attach to the ELB.
@AWS.AutoScaling.AutoScalingGroup 'AutoScalingGroup',
  AvailabilityZones:       ['us-west-2a', 'us-west-2b','us-west-2c' ]
  MinSize:                 @Params.minAutoScaleInstances
  MaxSize:                 @Params.maxAutoScaleInstances
  LaunchConfigurationName: @Resources.LaunchConfiguration
  LoadBalancerNames:       [ @Resources.LoadBalancer ]

## Scaling Policy attaches to the above AutoScalingGroup
@AWS.AutoScaling.ScalingPolicy 'ScalingPolicy',
  AdjustmentType:      'ChangeInCapacity'
  AutoScalingGroupName: @Resources.AutoScalingGroup
  Cooldown:             "60"
  ScalingAdjustment:    "1"

## Let's create a A record alias to the ELB end-point.
fqdn = @Join '.', @Params.hostname, @Params.HostedZoneName
@AWS.Route53.RecordSet 'Route53Alias'
  Comment:      "A Record to the LoadBalancer"
  HostedZoneId: @Params.HostedZoneId
  Name:         fqdn
  Type:         'A'
  AliasTarget:
    HostedZoneId: @GetAtt 'LoadBalancer', 'CanonicalHostedZoneNameID'
    DNSName:      @GetAtt 'LoadBalancer', 'CanonicalHostedZoneName'

## Some outputs when querying the stack.
@Output 'region',            Ref: @Region
@Output 'LoadBalancerDNS',   @Resources.Route53Alias
