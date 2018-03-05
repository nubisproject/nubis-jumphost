package { 'fail2ban':
  ensure => 'latest'
}
->service {'fail2ban':
  ensure => 'stopped',
  enable => true,
}

if $osfamily == 'RedHat' {
  exec { 'firewalld default accept':
    command => '/usr/bin/firewall-offline-cmd --zone=public --set-target=ACCEPT',
    require => [
      Package['fail2ban'],
    ],
  }
}
