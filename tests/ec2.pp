noder { 'blah2':
  ensure => present,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
}
noder { 'blah3':
  ensure => present,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
}
noder { 'default':
  ensure => present,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
  require => Noder['blah3']
}
noder { 'blah':
  ensure => absent,
  user => 'Dannyboy',
  password => 'password',
  image => 'ami-84db39ed',
  desc => 'happy instance',
  require => Noder['default'],
}
