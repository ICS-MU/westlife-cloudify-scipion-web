class scipion_web::user (
  $ensure          = $scipion_web::params::ensure,
  $user_name       = $scipion_web::params::user_name,
  $user_id         = $scipion_web::params::user_id,
  $user_groups     = $scipion_web::params::user_groups,
  $user_shell      = $scipion_web::params::user_shell,
  $user_home       = $scipion_web::params::user_home,
  $user_system     = $scipion_web::params::user_system,
  $group_name      = $scipion_web::params::group_name,
  $group_id        = $scipion_web::params::group_id,
  $group_system    = $scipion_web::params::group_system,
#  $public_key      = $scipion_web::params::public_key,
#  $private_key_b64 = $scipion_web::params::private_key_b64
) inherits scipion_web::params {

  group { $group_name:
    ensure => $ensure,
    gid    => $group_id,
    system => $group_system,
  }

  user { $user_name:
    ensure     => $ensure,
    uid        => $user_id,
    gid        => $group_id,
    groups     => $user_groups,
    shell      => $user_shell,
    home       => $user_home,
    managehome => true,
    system     => true,
  }

  file { "/etc/sudoers.d/scipion-backend":
    ensure  => $ensure,
    mode    => '0600',
    content => "# Managed by Puppet
${user_name} ALL=(ALL) NOPASSWD:ALL
",
  }

  if ($ensure == 'present') {
    Group[$group_name]
      -> User[$user_name]

#    exec { "usermod -a -G ${group_name} www-data": #TODO $apache::user_name
#      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
#      unless  => "id -Gn www-data | grep -qF ${group_name}",
#      require => Class['apache'],
#    }

    # SSH keys and configuration
    $_user_home = "${user_home}" ? {
      ''      => "/home/${user_name}",
      default => $user_home
    }

#    file { "${_user_home}":
#      ensure => directory,
#      owner  => $user_name,
#      group  => $group_name,
#      mode   => '0700',
#    }
#
#    file { "${_user_home}/.ssh/config":
#      ensure  => file,
#      owner   => $user_name,
#      group   => $group_name,
#      mode    => '0600',
#      content => '# This file is managed by Puppet
#Host *
#    StrictHostKeyChecking no
#    UserKnownHostsFile /dev/null
#',
#    }
#
#    if $private_key_b64 {
#      $_private_key = base64('decode', $private_key_b64)
#
#      file { "${_user_home}/.ssh/id_rsa":
#        ensure  => file,
#        content => $_private_key,
#        owner   => $user_name,
#        group   => $group_name,
#        mode    => '0400',
#      }
#    }
#
#    if $public_key {
#      $_public_key_files= [
#        "${_user_home}/.ssh/id_rsa.pub",
#        "${_user_home}/.ssh/authorized_keys"
#      ]
#
#      file { $_public_key_files:
#        ensure  => file,
#        content => $public_key,
#        owner   => $user_name,
#        group   => $group_name,
#        mode    => '0600',
#      }
#    }

  } else {
    User[$user_name]
      -> Group[$group_name]
  }
}
