class scipion_web::dyndns {
  case $scipion_web::ensure {
    present: {
      #TODO: take IP address from the fact
      class { 'ddclient':
        host     => $scipion_web::dyndns_hostname,
        login    => $scipion_web::dyndns_login,
        password => $scipion_web::dyndns_password,
        server   => $scipion_web::dyndns_server,
        ssl      => $scipion_web::dyndns_ssl,
        protocol => 'dyndns2',
        use      => 'web',
        daemon   => '300 -pid=/var/run/ddclient/ddclient.pid', #HACK!
      }
    }

    absent: {
      service { 'ddclient':
        ensure => stopped,
        enable => false,
      }

      package { 'ddclient':
        ensure  => purged,
        require => Service['ddclient'],
      }
    }

    default: {
      fail("Invalid ensure state '${scipion_web::ensure}'")
    }
  }
}
