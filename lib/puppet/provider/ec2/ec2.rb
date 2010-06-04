#
# copyright and what-not. apache commons (and what-not)
#
# even though, if you use this code, you'll actually have to make it do something useful.
#
require 'AWS'

Puppet::Type.type(:ec2).provide(:ec2) do

  @doc = "
This is the provider for noder that builds nodes on ec2

  there will likely be a virtual shit-ton (VST) of documentation added later
"

  #
  # get connection for ec2
  # this would be so much easier if I didnt have to support multple user accounts.
  #
  def self.ec2_connection(username, password)
    @ec2 ||= {}
    opts = {
      :access_key_id => username,
      :secret_access_key => password
    }
    @ec2[username] ||= AWS::EC2::Base.new(opts)
  end


  # for each ec2 instance
  #   -  build up the group hash
  def self.id_instances()
    # all instances
    @instances ||= {}
    @ec2.each do |k, v|
      instance_per_group(v)  
    end
  end

  #
  # parse a single ec2 connection 
  # build up a hash of group names -> instance ids
  #
  def self.instance_per_group(ec2)
    reservations = ec2.describe_instances.reservationSet
    if reservations
      reservations.item.each do |instance|
        # ignore all groups that are not prefixed with PUPPET_ (namevars)
        namevars = instance.groupSet.item.select do |item|
          item.groupId =~ /^PUPPET_/
        end
        if namevars.size > 1 || instance.instancesSet.item.size > 1
          raise Exception, 'Puppet only allows 1 instance per group'
        end
        namevars.each do |group|
          gid = group.groupId
          instance.instancesSet.item.each do |instance|
            state = instance.instanceState.name
            if state == 'terminated' || state == 'shutting-down' 
              # ignoring terminating states
            else 
              if @instances.has_key?(gid)
                raise Exception, "duplicate group #{gid}, was #{@instances[gid]} is #{instance.instanceId}"
              end
              @instances[gid] = {
                :instance_id => instance.instanceId,
                :state => state
              }
            end
          end
        end
      end
    end 
    puts @instances.to_yaml
  end

  #
  # get the ec2 connection by username
  #
  def self.ec2(username)
    @ec2[username]
  end

  #
  # return the actual ec2 instance id for an instance identified by
  # its membership to a security group
  #
  def self.instance_id(group)
    if @instances[group]
      @instances[group][:instance_id]
    else
      nil
    end
  end

  #
  # returns the current state for an instance.
  #
  def self.instance_state(group)
    if @instances[group]
      @instances[group][:state]
    else
      nil
    end
  end

  # hash the resources per user
  def self.prefetch(resources) 
#puts resources.to_yaml
    resources.each do |k,v|
      ec2_connection(v[:user], v[:password])
    end
    id_instances()
  end
#
#  def self.get_type(mem, cpu, arch='i386')
#    if arch == 'i386'
#      if mem > 1700000000
#        raise Exception, "Maximum memory is =~1.7GB with i386"
#      else
#        if cpu == 1
#          # memory = 1.7
#          # EC2 compute units = 1
#          'm1.small'
#        elsif cpu <= 5
#          'c1.medium'
#        else
#          raise Exception, "Maximum cpu units for ec2 with i386 is 5, not #{cpu}"
#        end
#      end
#    elsif arch == 'x86_64'
#      if mem <= 7500000000
#        if cpu <= 4
#          'm1.large'
#        else
#          # need something more memory intensive
#        end
#      elsif mem <= 15000000000
#        if cpu <= 8
#          'm1.xlarge'
#        end
#      elsif mem <= 17100000000
#        if cpu <= 6.5
#          'm2.xlarge'
#        elsif cpu <= 20
#          'c1.xlarge'
#        else
#          raise Exception, 'cannot support < 17.1GB RAM with more than 20 cpu units'
#        end
#      elsif mem <= 34200000000
#
#        'm2.2xlarge'
#      elsif mem <= 68400000000
#        if cpu <= 26
#          'm2.4xlarge'
#        else
#          raise Exception, "ec2 does not support more than 26 CPU units"
#        end
#      else
#        raise Exception, "ec2 does not support more than 68.4GB RAM"
#      end
#    end
    #if memory < 2000000000 && cpu == 1 && arch == 'i386'
    #  'm1.small'
    #end
#  end

  def initialize(resource)
    # essentially doing a provider munge to prefix
    # identifying security groups with PUPPET
    # this is required to simply allow other groups.
    resource[:name] = "PUPPET_#{resource[:name]}"
    super(resource)
  end

  #
  # ensures that the EC2 instance exists and is running
  #
  def create 
    ec2 =  self.class.ec2(@resource.value(:user))
    group = @resource.value(:name)
    # create the new security group
    begin
      ec2.describe_security_groups({:group_name => group})
    rescue Exception => e
      unless self.class.instance_state(group)
        ec2.create_security_group(
          { 
            :group_name => group, 
            :group_description => @resource.value(:desc)
          } 
        )
      end
    end
    # if instance in that security group exists, start it
    # otherwise just create a new instance 
    ec2.run_instances(
      {
        :image_id => @resource.value(:image),
        # security groups
        :security_group => group,
        :instance_type => @resource.value(:type),
      } 
    )
  end
  

  # determine if an ec2 instance exists
  def exists?
    # if we have a security group with our name and it has at least one member
    state = self.class.instance_state(@resource.value(:name))
    state == 'running' || state == 'pending'
  end

  # destory an ec2 instance if it exists
  def destroy 
    group = @resource.value(:name)
    ec2 =  self.class.ec2(@resource.value(:user))
    instance = self.class.instance_id(group)
    ec2.terminate_instances({:instance_id => instance})       
    unless group == 'default' 
      ec2.delete_security_group({:group_name => group})
    else
      puts 'cannot remove default'
    end
  end

  # reboot the instance when we receive a signal
  def restart
    group = @resource.value(:name)
    instance = self.class.instance_id(group)
    ec2 = self.class.ec2(@resource.value(:user))
puts 'rebooting'
    puts ec2.reboot_instances({:instance_id => instance}).to_yaml
    puts ec2.describe_instances({:instance_id => instance}).to_yaml
   # state = self.class.instance_state(@resource.value(:name))
   # state == 'running' || state == 'pending'
  end

#  private

#    def connect
#      opts = {
#        :access_key_id => ,
#        :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY']
#      }
#
#      @ec2 =  
#    end
    

end
