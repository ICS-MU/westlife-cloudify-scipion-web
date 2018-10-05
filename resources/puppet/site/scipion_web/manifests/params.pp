class scipion_web::params {
  $ensure = present

  $code_dir = '/opt/scipion_web'
  $app_symlink = '/var/www/scipion-cloudify-web'

  $node_cfy_source = 'https://github.com/ICS-MU/westlife-cloudify-scipion'
  $node_cfy_provider = 'git'
  $node_cfy_revision = 'master'

  $cfy_voms_proxy_file = '/tmp/x509up_u1000'
  $cfy_wrapper_dir = '/opt/cfy-wrapper'
  $cfy_template_dir = '<%= $scipion_web::cfy_wrapper_dir %>/template'
  $cfy_deployments_dir = '<%= $scipion_web::cfy_wrapper_dir %>/deployments'
  $cfy_log_dir = '<%= $scipion_web::cfy_wrapper_dir %>/log'
  $cfy_scripts_dir = '<%= $scipion_web::cfy_wrapper_dir %>/backend'

  $cfy_scripts = [
    'deploy_scipion.py',
    'b_constants.py',
    'get_resources.py',
    'undeploy_scipion.py',
    'init_templates.py',
    'init_example_data.py',
    'occi_list_ext.py'
  ]

  $cfy_jinja_scripts = {
    'renew_proxy.j2'      => 'renew_proxy.sh',
    'deploy_scipion.j2'   => 'deploy_scipion.sh',
    'undeploy_scipion.j2' => 'undeploy_scipion.sh',
  }

  $user_name = 'be-user'
  $user_id = undef
  $user_groups = []
  $user_shell = '/bin/bash'
  $user_home = undef
  $user_system = true

  $group_name = 'be-user'
  $group_id = undef
  $group_system = true

  $servername = $::fqdn
  $ssl_enabled = true
  $ssl_email = 'root@localhost'
  $server_url = undef  #depends on $ssl_enabled

  $occi_robot_key_b64 = undef
  $occi_robot_cert_b64 = undef

  $occi_vomses = {
    'enmr.eu.voms2.cnaf.infn.it' => '"enmr.eu" "voms2.cnaf.infn.it" "15014" "/C=IT/O=INFN/OU=Host/L=CNAF/CN=voms2.cnaf.infn.it" "enmr.eu"',
    'gputest.metacentrum.cz.voms1.grid.cesnet.cz' => '"gputest.metacentrum.cz" "voms1.grid.cesnet.cz" "15035" "/DC=org/DC=terena/DC=tcs/C=CZ/ST=Hlavni mesto Praha/L=Praha 6/O=CESNET/CN=voms2.grid.cesnet.cz" "gputest.metacentrum.cz" "24"',
    'gputest.metacentrum.cz.voms2.grid.cesnet.cz' => '"gputest.metacentrum.cz" "voms2.grid.cesnet.cz" "15035" "/DC=org/DC=terena/DC=tcs/C=CZ/ST=Hlavni mesto Praha/L=Praha 6/O=CESNET/CN=voms2.grid.cesnet.cz" "gputest.metacentrum.cz" "24"',
  }

  case $facts['os']['name'] {
    'Ubuntu': {
      $occi_packages = ['voms-clients', 'fetch-crl', 'ca-policy-egi-core', 'occi-cli']
    }

    default: {
      fail("Unsupported OS: ${facts['os']['name']}")
    }
  }

  $auth_enabled = true
  $auth_service_key_b64 = undef
  $auth_service_cert_b64 = undef
  $auth_service_meta_b64 = undef

  $dyndns_enabled = false
  $dyndns_hostname = undef
  $dyndns_server = undef
  $dyndns_login = undef
  $dyndns_password = undef
  $dyndns_ssl = 'yes'

  $portal_app_secret = extlib::random_password(64)
  $portal_jwt_secret = extlib::random_password(64)
}
