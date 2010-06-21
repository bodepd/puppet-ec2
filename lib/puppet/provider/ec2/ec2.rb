#
# copyright and what-not. apache commons (and what-not)
#
# even though, if you use this code, you'll actually have to make it do something useful.
#
require 'aws'
Puppet::Type.type(:ec2).provide(:ec2) do

  # configure ec2 connection
  def self.new_ec2(username, password)
    opts = {
      :access_key_id => username,
      :secret_access_key => password
    }
    AWS::EC2::Base.new(opts)
  end

  # get all of the instances for a certain user.
  def self.user_instances(ec2)
    return unless reservations = ec2.describe_instances.reservationSet
    results = {}
    reservations.item.each do |instance|
    # ignore all groups that are not prefixed with PUPPET_ (namevars)
      namevars = instance.groupSet.item.select do |item|
        item.groupId =~ /^PUPPET_/
      end
      if namevars.size > 1 || instance.instancesSet.item.size > 1
        raise Exception, 'Puppet only allows 1 instance per group'
      end
      gid = namevars.shift.groupId
      instance.instancesSet.item.each do |instance|
        state = instance.instanceState.name
        if state == 'terminated' || state == 'shutting-down'
        # ignoring terminating states
        else
          if results.has_key?(gid)
            raise Exception, "duplicate group: #{gid}, was #{results[gid]} is #{instance.instanceId}"
          end
          results[gid] = new(
            :name => gid,
            :instance_id => instance.instanceId,
            :ensure => state.to_sym
          )
        end
      end
    end
    results
  end
  

  #
  # this is the method that is called for ralsh query and purging
  #
  # I could query based ENVIRONMENT variabels, just query the ec2 instances
  # for a certain user/password combo
  #
  #
  def self.instances
   raise Puppet::Error, 'instances does not make sense for ec2, must know a username and pw'
  end

  #
  # figure out which instances currently exist!
  #
  # this is a little complicated... for performance reasons.
  # I wanted to do a single operation to calculate all of the 
  # instance information
  def self.prefetch(resources)
    resources_by_user = {}
    users = {}
    resources.each do |name, resource|
      resources_by_user[resource[:user]] ||= []
      resources_by_user[resource[:user]] << resource
      users[resource[:user]] ||= resource[:password]
    end
    users.each do |user, password|
      resources = resources_by_user[user]
      ec2 = self.new_ec2(user, password)
      instances = self.user_instances(ec2)
      resources_by_user[user].each do |res|
        if instances and instances[res[:name]]
          res.provider = instances[res[:name]]
        end
      end
    end
  end

  # essentially doing a provider munge to prefix
  # identifying security groups with PUPPET
  # this is required to simply allow other groups.
  def initialize(resource)
    unless resource.instance_of?(Hash)
      resource[:name] = "PUPPET_#{resource[:name]}"
    end
    super(resource)
  end

  # create namevar security group and start instance.
  def create
    ec2 = self.class.new_ec2(@resource.value(:user), @resource.value(:password))
    group = @resource.value(:name)
    begin
      ec2.describe_security_groups({:group_name => group})
    rescue Exception => e
      ec2.create_security_group({ 
        :group_name => group,
        :group_description => @resource.value(:desc)
      })
    end
    # if instance in that security group exists, start it
    # otherwise just create a new instance 
    ec2.run_instances(
    { :image_id => @resource.value(:image),
      # security groups
      :security_group => group,
      :instance_type => @resource.value(:type)
    })
  end

  # see if the instance in in the running or pending state.
  def exists?
    @property_hash and [:running, :pending].include?(@property_hash[:ensure])
  end

  # terminate the ec2 instance
  def destroy 
    ec2 = self.class.new_ec2(@resource.value(:user), @resource.value(:password))
    ec2.terminate_instances({:instance_id => @property_hash[:instance_id]})
    ec2.delete_security_group({:group_name => @resource.value(:name)})
  end

end
