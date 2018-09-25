class scipion_web (
  $ensure                = $scipion_web::params::ensure,
  $code_dir              = $scipion_web::params::code_dir,
  $app_symlink           = $scipion_web::params::app_symlink,
  $servername            = $scipion_web::params::servername,
  $ssl_enabled           = $scipion_web::params::ssl_enabled,
  $ssl_email             = $scipion_web::params::ssl_email,
  $server_url            = $scipion_web::params::server_url,
  $auth_enabled          = $scipion_web::params::auth_enabled,
  $auth_service_key_b64  = $scipion_web::params::auth_service_key_b64,
  $auth_service_cert_b64 = $scipion_web::params::auth_service_cert_b64,
  $auth_service_meta_b64 = $scipion_web::params::auth_service_meta_b64,
  $dyndns_enabled        = $scipion_web::params::dyndns_enabled,
  $dyndns_hostname       = $scipion_web::params::dyndns_hostname,
  $dyndns_server         = $scipion_web::params::dyndns_server,
  $dyndns_login          = $scipion_web::params::dyndns_login,
  $dyndns_password       = $scipion_web::params::dyndns_password,
  $dyndns_ssl            = $scipion_web::params::dyndns_ssl,
  $occi_packages         = $scipion_web::params::occi_packages,
  $occi_vomses           = $scipion_web::params::occi_vomses,
  $occi_robot_key_b64    = $scipion_web::params::occi_robot_key_b64,
  $occi_robot_cert_b64   = $scipion_web::params::occi_robot_cert_b64,
  $cfy_wrapper_dir       = $scipion_web::params::cfy_wrapper_dir,
  $cfy_template_dir      = $scipion_web::params::cfy_template_dir,
  $cfy_deployments_dir   = $scipion_web::params::cfy_deployments_dir,
  $cfy_log_dir           = $scipion_web::params::cfy_log_dir,
  $cfy_scripts_dir       = $scipion_web::params::cfy_scripts_dir,
  $cfy_scripts           = $scipion_web::params::cfy_scripts,
  $cfy_jinja_scripts     = $scipion_web::params::cfy_jinja_scripts,
  $node_cfy_source       = $scipion_web::params::node_cfy_source,
  $node_cfy_provider     = $scipion_web::params::node_cfy_provider,
  $node_cfy_revision     = $scipion_web::params::node_cfy_revision
) inherits scipion_web::params {

  $_proto = $ssl_enabled ? {
    true    => 'https',
    default => 'http'
  }

  if ($server_url) {
    $_server_url = $server_url
  } else {
    $_server_url = "${_proto}://${servername}"
  }

  contain scipion_web::dyndns
  contain scipion_web::user
  contain scipion_web::apache
  contain scipion_web::portal
  contain scipion_web::occi
  contain scipion_web::cfy

  Class['scipion_web::dyndns']
    -> Class['scipion_web::apache']
    -> Class['scipion_web::portal']
    -> Class['scipion_web::occi']
    -> Class['scipion_web::cfy']

  Class['scipion_web::user']
    -> Class['scipion_web::portal']
}
