class ec2 {
  package{'amazon-ec2':
    ensure => latest,
    provider => 'gem',
  }
}
