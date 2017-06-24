package { 'fail2ban':
  ensure => 'latest'
}->
service {'fail2ban':
  ensure => 'stopped',
  enable => true,
}
