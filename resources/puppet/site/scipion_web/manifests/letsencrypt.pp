class scipion_web::letsencrypt {
  case $scipion_web::ensure {
    present: {
      class { 'letsencrypt':
        email               => $scipion_web::ssl_email,
        unsafe_registration => true,
      }

      letsencrypt::certonly { $scipion_web::servername:
        plugin               => 'standalone',
        manage_cron          => true,
        cron_before_command  => '/bin/systemctl stop apache2.service',
        cron_success_command => '/bin/systemctl restart apache2.service',
        suppress_cron_output => true,
      }
    }

    absent: {
      include letsencrypt::params

      cron { "letsencrypt renew cron ${scipion_web::servername}":
        ensure => absent,
        user   => 'root',
      }

      package { $letsencrypt::params::package_name:
        ensure => purged,
      }

      file { $letsencrypt::params::config_dir:
        ensure => absent,
        force  => true,
        backup => false,
      }
    }

    default: {
      fail("Invalid ensure state '${scipion_web::ensure}'")
    }
  }
}
