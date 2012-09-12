ec2 { 'blah2':
  ensure => present,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
}
ec2 { 'blah3':
  ensure => present,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
}
ec2 { 'default':
  ensure => present,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
  require => Noder['blah3']
}
ec2 { 'blah':
  ensure => absent,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
  require => Noder['default'],
}
