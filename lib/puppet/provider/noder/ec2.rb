#
# copyright and what-not. apache commons (and what-not)
#
# even though, if you use this code, you'll actually have to make it do something useful.
#
require 'AWS'

Puppet::Type.type(:noder).provide(:ec2) do

  @doc = "
This is the provider for noder that builds nodes on ec2

  there will likely be a virtual shit-ton of documentation added later
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
  def self.organize(ec2)
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
        if instance.groupSet.item.size > 1 || instance.instancesSet.item.size > 1
          raise Puppet::Exception, 'Puppet only allows 1 instance per group'
        end
        instance.groupSet.item.each do |group|
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

  def self.instance_id(group)
    if @instances[group]
      @instances[group][:instance_id]
    else
      nil
    end
  end

  def self.instance_state(group)
    if @instances[group]
      @instances[group][:state]
    else
      nil
    end
  end

  # hash the resources per user
  def self.prefetch(resources) 
    resources.each do |k,v|
       ec2_connection(v[:user], v[:password])
    end
    organize(@ec2)
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
        :security_group => group,
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
