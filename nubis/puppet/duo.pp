# installs duo package that is built by mozilla
$duo_version    = '1.9.11-1'
$url            = "https://s3-us-west-2.amazonaws.com/nubis-stacks/packages/rpm/duo_unix-${duo_version}.x86_64.rpm"

wget::fetch { "download duo_unix-${duo_version}":
    source      => $url,
    destination => "/usr/local/src/duo_unix-${duo_version}.x86_64.rpm",
    user        => root,
    verbose     => true,
    redownload  => true,
}

package { 'duo_unix':
    ensure   => present,
    provider => 'rpm',
    source   => "/usr/local/src/duo_unix-${duo_version}.x86_64.rpm",
    require  => Wget::Fetch["download duo_unix-${duo_version}"],
}

file { '/etc/confd/conf.d/duo.toml':
    ensure  => 'file',
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => 'puppet:///nubis/files/duo.toml',
    require => Package['duo_unix'],
}

file { '/etc/confd/templates/duo.tmpl':
    ensure  => 'file',
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => 'puppet:///nubis/files/duo.tmpl',
    require => [ Package['duo_unix'], File['/etc/confd/conf.d/duo.toml'] ],
}

file { '/etc/nubis.d/confd-fixup':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///nubis/files/confd-fixup',
    require => [ File['/etc/confd/conf.d/duo.toml'], File['/etc/confd/templates/duo.tmpl'] ],
}
