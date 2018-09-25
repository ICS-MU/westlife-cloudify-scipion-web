class scipion_web::apache {
  # Apache
  $_apache_package_ensure = $scipion_web::ensure ? {
    present => installed,
    default => purged,
  }

  $_apache_service_ensure = $scipion_web::ensure ? {
    present => running,
    default => stopped,
  }

  $_apache_service_enable = $scipion_web::ensure ? {
    present => true,
    default => false
  }

  class { 'apache':
    mpm_module     => 'prefork',
    default_vhost  => false,
    package_ensure => $_apache_package_ensure,
    service_ensure => $_apache_service_ensure,
    service_enable => $_apache_service_enable,
  }

  $_mellon_dir = "${apache::httpd_dir}/mellon"

  if ($scipion_web::ensure == 'present') {
    contain apache::mod::ssl
    contain apache::mod::auth_mellon
    contain apache::mod::rewrite

    class { 'apache::mod::wsgi':
      package_name => 'libapache2-mod-wsgi-py3',
      mod_path     => '/usr/lib/apache2/modules/mod_wsgi.so',
    }

    $_custom_fragment = inline_template('
  WSGIScriptAlias / <%= scope["scipion_web::app_symlink"] %>/scipion-cloudify-web.wsgi
  WSGIDaemonProcess <%= scope["scipion_web::servername"] %> processes=2 threads=15 user=<%= scope["scipion_web::user::user_name"] %> display-name=%{GROUP} python-home=<%= scope["scipion_web::app_symlink"] %>/venv/lib/python3.5
  WSGIProcessGroup <%= scope["scipion_web::servername"] %>

  <Directory "<%= scope["scipion_web::app_symlink"] %>">
    Options Indexes FollowSymLinks
    AllowOverride All
    Order allow,deny
    Allow from all
  </Directory>
                
  <Directory "<%= scope["scipion_web::app_symlink"] %>/frontend">
    Order allow,deny
    Allow from all
  </Directory>

  AliasMatch ^(.*\.)(js|css|png|jpg|gif|ico|json)$ <%= scope["scipion_web::app_symlink"] %>/frontend/$1$2

<% if scope["scipion_web::auth_enabled"] == true -%>
  <Location "/">
    MellonSPPrivateKeyFile <%= @_mellon_dir %>/service.key
    MellonSPCertFile       <%= @_mellon_dir %>/service.cert
    MellonSPMetadataFile   <%= @_mellon_dir %>/service.xml

    # https://auth.west-life.eu/proxy/saml2/idp/metadata.php
    MellonIdPMetadataFile  <%= @_mellon_dir %>/idp-metadata.xml

    # Mapping of attribute names to something readable
    MellonSetEnv "name" "urn:oid:2.16.840.1.113730.3.1.241"
    MellonSetEnv "mail" "urn:oid:0.9.2342.19200300.100.1.3"
    MellonSetEnv "eppn" "urn:oid:1.3.6.1.4.1.5923.1.1.1.6"
    MellonSetEnv "entitlement" "urn:oid:1.3.6.1.4.1.5923.1.1.1.7"
    MellonSetEnv "eduPersonUniqueId" "urn:oid:1.3.6.1.4.1.5923.1.1.1.13"
  </Location>

  <Location "/api/authenticate">
    AuthType Mellon
    MellonEnable "auth"
    Require valid-user
  </Location>
<% end -%>
')

    if $scipion_web::auth_enabled {
      file { $_mellon_dir:
        ensure  => directory,
        mode    => '0750',
        owner   => $apache::user,
        group   => $apache::group,
        require => Package['httpd'],
      }

      file { "${_mellon_dir}/idp-metadata.xml":
        ensure => file,
        mode   => '0640',
        owner  => $apache::user,
        group  => $apache::group,
        source => 'puppet:///modules/scipion_web/idp-metadata.xml',
        notify => Class['apache::service'],
      }

      # user provided service keys/certs
      if length($scipion_web::auth_service_key_b64) > 0 {
        file { "${_mellon_dir}/service.key":
          ensure  => file,
          mode    => '0640',
          owner   => $apache::user,
          group   => $apache::group,
          content => base64('decode', $scipion_web::auth_service_key_b64),
          notify  => Class['apache::service'],
        }
      } else {
        fail('Missing $scipion_web::auth_service_key_b64')
      }

      if length($scipion_web::auth_service_cert_b64) > 0 {
        file { "${_mellon_dir}/service.cert":
          ensure  => file,
          mode    => '0640',
          owner   => $apache::user,
          group   => $apache::group,
          content => base64('decode', $scipion_web::auth_service_cert_b64),
          notify  => Class['apache::service'],
        }
      } else {
        fail('Missing $scipion_web::auth_service_cert_b64')
      }

      if length($scipion_web::auth_service_meta_b64) > 0 {
        file { "${_mellon_dir}/service.xml":
          ensure  => file,
          mode    => '0640',
          owner   => $apache::user,
          group   => $apache::group,
          content => base64('decode', $scipion_web::auth_service_meta_b64),
          notify  => Class['apache::service'],
        }
      } else {
        fail('Missing $scipion_web::auth_service_meta_b64')
      }
    }

    apache::vhost { 'http':
      ensure          => present,
      servername      => $scipion_web::servername,
      port            => 80,
      docroot         => $scipion_web::app_symlink,
      manage_docroot  => true,
      docroot_owner   => $apache::user,
      docroot_group   => $apache::group,
      #custom_fragment => $_custom_fragment, #only if not ssl_enabled, configured below
    }

    if $scipion_web::ssl_enabled {
      class { 'scipion_web::letsencrypt':
        before => [ Apache::Vhost['https'], Class['apache'] ],
      }

      apache::vhost { 'https':
        ensure          => present,
        servername      => $scipion_web::servername,
        port            => 443,
        docroot         => $scipion_web::app_symlink,
        manage_docroot  => false,
        docroot_owner   => $apache::user,
        docroot_group   => $apache::group,
        ssl             => true,
        ssl_cert        => "/etc/letsencrypt/live/${scipion_web::servername}/cert.pem",
        ssl_chain       => "/etc/letsencrypt/live/${scipion_web::servername}/chain.pem",
        ssl_key         => "/etc/letsencrypt/live/${scipion_web::servername}/privkey.pem",
        custom_fragment => $_custom_fragment,
      }

      # redirect http->https
      Apache::Vhost['http'] {
        redirect_dest => "${scipion_web::_server_url}/"
      }
    } else {
      Apache::Vhost['http'] {
        custom_fragment => $_custom_fragment,
      }
    }
  } elsif ($ensure = 'absent') {
    if $scipion_web::ssl_enabled {
      include scipion_web::letsencrypt
    }

    if $scipion_web::auth_enabled {
      file { $_mellon_dir:
        ensure => absent,
        force  => true,
        backup => false,
      }
    }
  }
}
