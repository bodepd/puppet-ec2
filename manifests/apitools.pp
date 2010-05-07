#
# I didnt wind up using apitools
#
class ec2::apitools {
  include ec2
  package { 'java':
    ensure => installed,
  }    
}
