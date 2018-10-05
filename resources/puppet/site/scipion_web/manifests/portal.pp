class scipion_web::portal {
  if ($scipion_web::ensure == 'present') {
    # Portal code
    $_portal_arch = '/tmp/scipion_web.tar.gz'

    file { $_portal_arch:
      ensure => file,
      source => 'puppet:///modules/scipion_web/private/scipion_web.tar.gz',
    }

    file { $scipion_web::code_dir:
      ensure => directory,
      owner  => $apache::user,
      group  => $apache::group,
      force  => true,
      backup => false,
    }

    archive { $_portal_arch:
      extract      => true,
      extract_path => $scipion_web::code_dir,
      creates      => "${scipion_web::code_dir}/app/frontend",
      user         => $apache::user,
      group        => $apache::group,
      require      => Class['apache'],
    }

    file { $scipion_web::app_symlink:
      ensure  => symlink,
      target  => "${scipion_web::code_dir}/app",
      owner   => $apache::user,
      group   => $apache::group,
      force   => true,
      backup  => false,
      require => Archive[$_portal_arch],
    }

    # Configure secrets
    exec { 'set-secret-scipion-cloudify-web.wsgi':
      command => "sed -i -e 's/your-application-secret-key/${scipion_web::portal_app_secret}/' ${scipion_web::code_dir}/app/scipion-cloudify-web.wsgi",
      onlyif  => "grep -q 'your-application-secret-key' ${scipion_web::code_dir}/app/scipion-cloudify-web.wsgi",
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      require => Archive[$_portal_arch],
    }

    exec { 'set-secret-app_entry.py':
      command => "sed -i -e 's/super_secret_scipion_cloudify_web_jwt_key/${scipion_web::portal_jwt_secret}/' ${scipion_web::code_dir}/app/app_entry.py",
      onlyif  => "grep -q 'super_secret_scipion_cloudify_web_jwt_key' ${scipion_web::code_dir}/app/app_entry.py",
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      require => Archive[$_portal_arch],
    }

    # Python
    class { 'python':
      ensure      => present,
      version     => 'python3',
      dev         => present,
      virtualenv  => present,
    }

    python::virtualenv { '/var/www/scipion-cloudify-web/venv':
      ensure       => present,
      version      => '3',
      requirements => "${scipion_web::app_symlink}/requirements.txt",
      require      => File[$scipion_web::app_symlink],
      notify       => Class['apache::service'],
    }

  } elsif ($scipion_web::ensure == 'absent') {
    file { $scipion_web::code_dir:
      ensure => absent,
      force  => true,
      backup => false,
    }
  }
}
