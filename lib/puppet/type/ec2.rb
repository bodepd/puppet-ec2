#
# blah!
# this has mainly been written to facilitate ec2 instance provisioning with puppet.
#
# I am sure that more attributes will have to be added.
#
Puppet::Type.newtype(:ec2) do
  @doc = "Manages the provisioing of new machines."

  #
  #  I need additional ensurable states: 
  #    * stopped (stop but dont delete)
  #    * running (alias for present),
  #    * absent - terminate (is there anything more brutal than terminate?)
  # 

  ensurable
#  ensurable do
#
#  newvalue(:present, :event => :created) do
#    provider.create
#  end
#  aliasvalue(:running, :present)
#
#  newvalue(:absent, :event => :terminated) do
#    provider.destroy
# end
#  aliasvalue(:terminated, :absent)
#
#  newvalue(:stopped, :event => :stopped) do
#    provider.stop
#  end
#
#  def retrieve
#    if provider
#      provider.get('ensure')
#    else
#      puts 'provider does not exist, I think this is like absent'
#      'absent'
#    end
#  end
#
#  def insync?(is)
#    @should.each do |value|
#      case value 
#      when :present, :running
#        return [:pending, :running].include?(is)
#      when :absent, :terminated
#        return [:'shutting-down', :terminated, :absent].include?(is)
#      when :stopped
#        return ![:pending, :running].include?(is)
#      when is
#        puts 'is there another case'
#      else
#        puts 'else'
#      end
#    end
#  end
#
#  end

  def refresh
    provider.restart
  end

  # you cannot only manage security groups on create instance. 
  newparam(:name, :namevar => true) do
    desc "unique id for a machine"
  end

  #
  #  there will initially be a limitation that only one partition (/)
  #  is supported
  #
#  newparam(:disksize) do
#    desc "the size of the root partition created at boot time"
#    # default is GB
#    defaultto 20
#  end

  # I need to consider if owner and password should be params
  #   ie: do we want to move machines between owners??
  newparam(:user) do
    desc "owner of node, this will refer to the account responsible for
    provisioning for cloud services, this may also be required
    "
    isrequired
  end

  # this is a feature only required for cloud usage
  newparam(:password) do
    desc "password used to connect to cloud providers"
    isrequired
  end

  newparam(:image) do 
    desc "base image used during installation"
    # this is only required when we create
    isrequired
  end

  newparam(:desc) do
    desc "description of instance"
  end


  def self.types
    @types
  end

  newparam(:type) do
	  VALID_TYPES = [ 't1.micro', 'm1.small', 'm1.large', 'm1.xlarge',
        'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge', 'c1.medium', 'c1.xlarge']
        # check valid values from array
	  newvalues(*VALID_TYPES)
    desc "this is how ec2 qualifies machine strength, I would rather use memory or ncpus or something else..."
    munge do |value|
      value.downcase
    end
    defaultto 't1.micro'
  end


  #
  # this should be a property but its just not supported
  # with the ec2 ruby bindings... yet.
  #
#  newparam(:memory) do
#    validate do |mem|
#      unless mem =~ /\d+(GB|KB|MB)?/
#        raise Puppet::Error, "Unexpected memory value #{mem}"
#      end
#    end
#    munge do |mem|
#      mem.capitalize!
#      if mem =~ /(\d+)(GB|MB|KB)?/
#        mult = 1
#        if $2 == 'KB'
#          mult = 1000
#        elsif $2 == 'MB'
#          mult = 1000000
#        elsif $2 == 'GB'
#          mult = 1000000000
#        end 
#        mem.to_i*mult
#      end
#    end
#  end

  #
  # this should be a property eventually.
  #
#  newparam(:cpu) do
#    validate do |cpu|
#      unless cpu =~ /\d+/
#        raise Puppet::Error, "Expected int for cpu, got #{cpu}" 
#      end
#    end
#    munge do |cpu|
#      cpu.to_i
#    end
#    defaultto '1'
#  end

  #
  #  this should probably be a property eventually.
  #
#  newparam(:arch) do
#    validate do |arch|
#      unless arch =~ /(i386|x86_64)/
#        raise Puppet::Error, "Unsupported arch #{arch}"
#      end
#    en
#    defaultto 'i386'
#  end 

#  newparam(:sync) do
#    desc 'how obsessed should we be with synchronizing in general, this is not impleneted as of yet.'
#    defaultto true
#  end
 
#  newparam(:group) do
#    desc "node group that will be used for parameterization"
#  end

#  newparam(:role) do
#    desc "list of classes that define machine role"
#  end

end
