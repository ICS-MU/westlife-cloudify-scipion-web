class scipion_web::occi::install {
  $_ensure_link = $scipion_web::ensure ? {
    present => link,
    default => $scipion_web::ensure,
  }

  ###

  package { $scipion_web::occi_packages:
    ensure => $scipion_web::ensure,
  }

  file { '/usr/local/bin/occi':
    ensure  => $_ensure_link,
    target  => '/usr/bin/occi',
    require => Package[$scipion_web::occi_packages],
  }
}
