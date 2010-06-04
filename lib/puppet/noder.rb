#
# blah!
#
# this has mainly been written to facilitate ec2 instance provisioning with puppet.
#
# I am sure that more attributes will have to be added.
#
Puppet::Type.newtype(:noder) do
  @doc = "Manages the provisioing of new machines."

  #
  #  I need additional ensurable states: 
  #    * stopped (stop but dont delete)
  #    * running (alias for present),
  #    * absent - terminate (is there anything more brutal than terminate?)
  # 
  ensurable

  # you cannot only manage security groups on create instance. 
  newparam(:name) do
    desc "unique id for a machine"
    isnamevar
    validate do
    end
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
#    munge do
#      'bob'
#    end
  end

  # this is a feature only required for cloud usage
  newparam(:password) do
    desc "password used to connect to cloud providers"
    # this is only required for cloud providers
  end

  newparam(:image) do 
    desc "base image used during installation"
    # this is only required when we create
  end

  newparam(:desc) do
    desc "description of instance"
  end

  newparam(:type) do
    desc "this is how ec2 qualifies machine strength, I would rather use memory or ncpus or something else..."
  end


  #
  # this should be a property but its just not supported
  # with the ec2 ruby bindings... yet.
  #
  newparam(:memory) do
    validate do |mem|
      unless mem =~ /\d+(GB|KB|MB)?/
        raise Puppet::Error, "Unexpected memory value #{mem}"
      end
    end
    munge do |mem|
      mem.capitalize!
      if mem =~ /(\d+)(GB|MB|KB)?/
        mult = 1
        if $2 == 'KB'
          mult = 1000
        elsif $2 == 'MB'
          mult = 1000000
        elsif $2 == 'GB'
          mult = 1000000000
        end 
        mem.to_i*mult
      end
    end
  end

  #
  # this should be a property eventually.
  #
  newparam(:cpu) do
    validate do |cpu|
      unless cpu =~ /\d+/
        raise Puppet::Error, "Expected int for cpu, got #{cpu}" 
      end
    end
    munge do |cpu|
      cpu.to_i
    end
    defaultto '1'
  end

  #
  #  this should probably be a property eventually.
  #
  newparam(:arch) do
    validate do |arch|
      unless arch =~ /(i386|x86_64)/
        raise Puppet::Error, "Unsupported arch #{arch}"
      end
    end
    defaultto 'i386'
  end 

  newparam(:sync) do
    desc 'rather or not to wait until images exist, defaults to true'
    defaultto true
  end
 
#  newparam(:group) do
#    desc "node group that will be used for parameterization"
#  end

#  newparam(:role) do
#    desc "list of classes that define machine role"
#  end

end
