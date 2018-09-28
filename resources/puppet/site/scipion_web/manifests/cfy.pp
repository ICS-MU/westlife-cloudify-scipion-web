class scipion_web::cfy {
  $_ensure_file = $scipion_web::ensure ? {
    present => file,
    default => $scipion_web::ensure,
  }

  $_ensure_dir = $scipion_web::ensure ? {
    present => directory,
    default => $scipion_web::ensure,
  }

  $_ensure_sym = $scipion_web::ensure ? {
    present => symlink,
    default => $scipion_web::ensure,
  }

  $_cfy_template_dir = inline_epp($scipion_web::cfy_template_dir)
  $_cfy_deployments_dir = inline_epp($scipion_web::cfy_deployments_dir)
  $_cfy_log_dir = inline_epp($scipion_web::cfy_log_dir)
  $_cfy_scripts_dir = inline_epp($scipion_web::cfy_scripts_dir)

  $_dirs = [
    $scipion_web::cfy_wrapper_dir,
#    $_cfy_template_dir,
    $_cfy_deployments_dir,
    $_cfy_log_dir,
    $_cfy_scripts_dir
  ]

  file { $_dirs:
    ensure => $_ensure_dir,
    force  => true,
    backup => false,
    owner  => $scipion_web::user::user_name,
    group  => $scipion_web::user::group_name,
  }

  if ($scipion_web::ensure == 'present') {
    $scipion_web::cfy_scripts.each |String $filename| {
      #TODO: copy / executable permission?
      file { "${_cfy_scripts_dir}/${filename}":
        ensure => $_ensure_sym,
        target => "${scipion_web::code_dir}/cfy-wrapper/${filename}",
      }
    }

    $scipion_web::cfy_jinja_scripts.each |String $src, String $dst| {
      $_cfy_scripts_dst = "${_cfy_scripts_dir}/${dst}"

      $_cmd = @("EOT")
        set -e

        sed \
            -e 's,{{\s*template_dir\s*}},${_cfy_template_dir},gi' \
            -e 's,{{\s*deployments_dir\s*}},${_cfy_deployments_dir},gi' \
            -e 's,{{\s*log_dir\s*}},${_cfy_log_dir },gi' \
            -e 's,{{\s*scripts_dir\s*}},${_cfy_scripts_dir },gi' \
            -e 's,{{\s*be_user\s*}},${scipion_web::user::user_name},gi' \
            -e 's,{{\s*be_group\s*}},${scipion_web::user::group_name},gi' \
            ${scipion_web::code_dir}/cfy-wrapper/${src} >${_cfy_scripts_dst}.tmp

        chmod +x ${_cfy_scripts_dst}.tmp
        mv -f ${_cfy_scripts_dst}.tmp ${_cfy_scripts_dst}
      | EOT

      exec { "jinja-process-${src}":
        command  => $_cmd,
        path     => '/bin:/usr/bin:/sbin:/usr/sbin',
        creates  => $_cfy_scripts_dst,
        user     => $scipion_web::user::user_name,
        group    => $scipion_web::user::group_name,
        provider => shell,
      }
    }

    # initial database "bootstrap"
    file { "${scipion_web::cfy_wrapper_dir}/scipion-cloudify.db":
      ensure  => $_ensure_file,
      source  => "${scipion_web::code_dir}/scipion-cloudify.db",
      replace => false,
      owner   => $scipion_web::user::user_name,
      group   => $scipion_web::user::group_name,
      mode    => '0664',
    }

    # deploy blueprints from VCS for Scipion node
    vcsrepo { $_cfy_template_dir:
      ensure   => present,
      provider => $scipion_web::node_cfy_provider,
      source   => $scipion_web::node_cfy_source,
      revision => $scipion_web::node_cfy_revision,
      user     => $scipion_web::user::user_name,
      group    => $scipion_web::user::group_name,
    }

    # bootstrap Cloudify tools
    exec { 'make-bootstrap':
      command     => 'make bootstrap',
      environment => "VIRTUAL_ENV=/home/${scipion_web::user::user_name}/cfy",
      creates     => "/home/${scipion_web::user::user_name}/cfy/bin/cfy",
      cwd         => $_cfy_template_dir,
      user        => $scipion_web::user::user_name,
      group       => $scipion_web::user::group_name,
      path        => '/bin:/sbin:/usr/bin:/usr/sbin',
      require     => Vcsrepo[$_cfy_template_dir],
    }
  }

  # cronjobs
  Cron {
    ensure => $scipion_web::ensure,
    user   => $scipion_web::user::user_name,
  }

  if ($scipion_web::ensure == 'present') {
    $_cmd_renew = "${_cfy_scripts_dir}/renew_proxy.sh >>${_cfy_log_dir}/renew.log 2>&1"

    # generate/refresh VOMS proxy if valid for <=5 hours
    exec { "cfy-renew_proxy.sh":
      command => $_cmd_renew,
      unless  => "voms-proxy-info -file ${scipion_web::cfy_voms_proxy_file} -exists -valid 5:00",
      user    => $scipion_web::user::user_name,
      group   => $scipion_web::user::group_name,
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      before  => File[$scipion_web::cfy_voms_proxy_file],
    }

    Cron {
      require => File["${scipion_web::cfy_wrapper_dir}/scipion-cloudify.db"],
    }
  } else {
    Cron {
      before => File[$_dirs],
    }
  }

  file { $scipion_web::cfy_voms_proxy_file:
    ensure => $_ensure_file,
  }

  cron { 'Scipion web deploy job':
    command => "${_cfy_scripts_dir}/deploy_scipion.py >>${_cfy_log_dir}/deploy.log 2>&1",
    minute  => '*/5',
  }

  cron { 'Scipion web undeploy job':
    command => "${_cfy_scripts_dir}/undeploy_scipion.py >>${_cfy_log_dir}/un_deploy.log 2>&1",
    minute  => '*/5',
  }

  cron { 'Scipion web renew proxy job':
    command => $_cmd_renew,
    hour    => [1, 5, 9, 13, 17, 21],
    minute  => 1,
  }
}
