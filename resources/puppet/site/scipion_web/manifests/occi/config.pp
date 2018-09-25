class scipion_web::occi::config {
  $_ensure_dir = $scipion_web::ensure ? {
    present => directory,
    default => $scipion_web::ensure
  }

  file { '/etc/vomses':
    ensure => $_ensure_dir,
    force  => true,
  }

  $scipion_web::occi_vomses.each |String $filename, String $content| {
    file { "/etc/vomses/${filename}":
      ensure  => $scipion_web::ensure,
      content => $content,
    }
  }

  $_user_home = "${scipion_web::user::user_home}" ? {
    ''      => "/home/${scipion_web::user::user_name}",
    default => $scipion_web::user::user_home,
  }

  File {
    owner => $scipion_web::user::user_name,
    group => $scipion_web::user::group_name,
  }

  file { "${_user_home}/.globus":
    ensure => $_ensure_dir,
    force  => true,
    mode   => '0700',
  }

  file { "${_user_home}/.globus/robotcert.crt":
    ensure  => $scipion_web::ensure,
    content => base64('decode', $scipion_web::occi_robot_cert_b64),
    mode    => '0600',
  }

  file { "${_user_home}/.globus/robotkey.pem":
    ensure  => $scipion_web::ensure,
    content => base64('decode', $scipion_web::occi_robot_key_b64),
    mode    => '0600',
  }
}
