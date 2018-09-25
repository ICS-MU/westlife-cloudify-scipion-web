---

tosca_definitions_version: cloudify_dsl_1_3

description: >
  Scipion frontend setup via FedCloud OCCI and Puppet.

dnl *** From gromacs-inputs.yaml.m4 take only macros, drop regular texts.
divert(`-1')dnl
include(scipion-web-inputs.yaml.m4)dnl
divert(`0')dnl

define(_NODE_SERVER_,         ifdef(`_CFM_',`gromacs.nodes.MonitoredServer',`gromacs.nodes.Server'))dnl
define(_NODE_HOSTPOOLSERVER_, ifdef(`_CFM_',`gromacs.nodes.MonitoredHostPoolServer',`gromacs.nodes.HostPoolServer'))dnl
define(_NODE_TORQUESERVER_,   ifdef(`_CFM_',`gromacs.nodes.MonitoredTorqueServer',`gromacs.nodes.TorqueServer'))dnl
define(_NODE_WEBSERVER_,      ifdef(`_CFM_',`gromacs.nodes.MonitoredWebServer', `gromacs.nodes.WebServer'))dnl
define(_NODE_SWCOMPONENT_,    ifdef(`_CFM_',`gromacs.nodes.MonitoredSoftwareComponent', `gromacs.nodes.SoftwareComponent'))dnl
define(_NAME_OLINNODE_,       ifelse(_PROVISIONER_,`hostpool',`olinNodeHostPool',`olinNode'))dnl
define(_NAME_WORKERNODE_,     ifelse(_PROVISIONER_,`hostpool',`workerNodeHostPool',`workerNode'))dnl
define(_NAME_TORQUESERVER_,   ifelse(_PROVISIONER_,`hostpool',`torqueServerHostPool',`torqueServer'))dnl

# Note: plugin/version installation for CFM handled
# in Makefile by target "cfm-plugins"
imports:
  - http://www.getcloudify.org/spec/cloudify/4.3/types.yaml
  - http://www.getcloudify.org/spec/diamond-plugin/1.3.1/plugin.yaml
  - https://raw.githubusercontent.com/cloudify-cosmo/cloudify-host-pool-plugin/1.5/plugin.yaml
  - https://raw.githubusercontent.com/ICS-MU/westlife-cloudify-occi-plugin/0.0.15/plugin.yaml
  - https://raw.githubusercontent.com/ICS-MU/westlife-cloudify-fabric-plugin/1.5.1.1/plugin.yaml
  - https://raw.githubusercontent.com/ICS-MU/westlife-cloudify-westlife-workflows/master/plugin.yaml
  - types/puppet.yaml
  - types/server.yaml
  - types/softwarecomponent.yaml
#  - types/torqueserver.yaml
  - types/webserver.yaml

inputs:
  # OCCI
  occi_endpoint:
    default: ''
    type: string
  occi_auth:
    default: ''
    type: string
  occi_username:
    default: ''
    type: string
  occi_password:
    default: ''
    type: string
  occi_user_cred:
    default: ''
    type: string
  occi_ca_path:
    default: ''
    type: string
  occi_voms:
    default: False
    type: boolean

  # Host pool
  hostpool_service_url:
    default: ''
    type: string
  hostpool_username:
    default: 'root'
    type: string
  hostpool_private_key:
    default: ''
    type: string

  # contextualization
  cc_username:
    default: cfy
    type: string
  cc_public_key:
    type: string
  cc_private_key:
    type: string
  cc_data:
    default: {}

  # VM parameters
  olin_occi_os_tpl:
    type: string
  olin_occi_resource_tpl:
    type: string
  olin_occi_availability_zone:
    type: string
  olin_occi_network:
    type: string
  olin_occi_network_pool:
    type: string
  olin_occi_scratch_size:
    type: integer
  olin_hostpool_tags:
    default: []

  # Application parameters
  scipion_web_servername:
    type: string
  scipion_web_ssl_enabled:
    type: boolean
  scipion_web_ssl_email:
    type: string
  scipion_web_dyndns_enabled:
    type: boolean
  scipion_web_dyndns_hostname:
    type: string
  scipion_web_dyndns_server:
    type: string
  scipion_web_dyndns_login:
    type: string
  scipion_web_dyndns_password:
    type: string
  scipion_web_dyndns_ssl:
    type: string
  scipion_web_auth_enabled:
    type: boolean
  scipion_web_auth_service_key_b64:
    type: string
  scipion_web_auth_service_cert_b64:
    type: string
  scipion_web_auth_service_meta_b64:
    type: string
  scipion_web_occi_robot_key_b64:
    type: string
  scipion_web_occi_robot_cert_b64:
    type: string
  scipion_web_node_cfy_source:
    type: string
  scipion_web_node_cfy_revision:
    type: string

dsl_definitions:
  occi_configuration: &occi_configuration
    endpoint: { get_input: occi_endpoint }
    auth: { get_input: occi_auth }
    username: { get_input: occi_username }
    password: { get_input: occi_password }
    user_cred: { get_input: occi_user_cred }
    ca_path: { get_input: occi_ca_path }
    voms: { get_input: occi_voms }

  cloud_configuration: &cloud_configuration
    username: { get_input: cc_username }
    public_key: { get_input: cc_public_key }
    data: { get_input: cc_data }

  fabric_env: &fabric_env
    user: { get_input: cc_username }
    key: { get_input: cc_private_key }

  fabric_env_hostpool: &fabric_env_hostpool
    user: { get_input: hostpool_username }
    key: { get_input: hostpool_private_key }

  agent_configuration: &agent_configuration
    install_method: remote
    user: { get_input: cc_username }
    key: { get_input: cc_private_key }

  agent_configuration_hostpool: &agent_configuration_hostpool
    install_method: remote
    user: { get_input: hostpool_username }
    key: { get_input: hostpool_private_key }

  puppet_config: &puppet_config
    repo: 'https://apt.puppetlabs.com/puppet5-release-trusty.deb'
    package: 'puppet-agent'
    download: resources/puppet.tar.gz

  #TODO
  plugin_resources: &plugin_resources
    description: >
      Holds any archives that should be uploaded to the manager.
    default:
      - 'https://github.com/ICS-MU/westlife-cloudify-occi-plugin/releases/download/0.0.14/cloudify_occi_plugin-0.0.14-py27-none-linux_x86_64.wgn'

node_templates:

ifelse(_PROVISIONER_,`hostpool',`
  ### Predeployed nodes #######################################################

  # predeployed olin (frontend)
  olinNodeHostPool:
    type: _NODE_HOSTPOOLSERVER_
    properties:
      agent_config: *agent_configuration_hostpool
      fabric_env: *fabric_env_hostpool
      hostpool_service_url: { get_input: hostpool_service_url }
      filters:
        tags: { get_input: olin_hostpool_tags }

  scipionFeHostPool:
    type: _NODE_WEBSERVER_
    instances:
      deploy: 1
    properties:
      fabric_env: *fabric_env_hostpool
      puppet_config:
        <<: *puppet_config
        manifests:
          start: manifests/olin.pp
          delete: manifests/olin.pp
          #delete: manifests/noop.pp
        hiera:
          scipion_web::servername: { get_input: scipion_web_servername }
          westlife::volume::device: /dev/vdc
          westlife::volume::fstype: ext4
          westlife::volume::mountpoint: /data
          westlife::volume::mode: "1777"
          scipion_web::ssl_enabled: { get_input: scipion_web_ssl_enabled }
          scipion_web::ssl_email: { get_input: scipion_web_ssl_email }
          scipion_web::auth_enabled: { get_input: scipion_web_auth_enabled }
          scipion_web::auth_service_key_b64: { get_input: scipion_web_auth_service_key_b64 }
          scipion_web::auth_service_cert_b64: { get_input: scipion_web_auth_service_cert_b64 }
          scipion_web::auth_service_meta_b64: { get_input: scipion_web_auth_service_meta_b64 }
          scipion_web::dyndns_enabled: { get_input: scipion_web_dyndns_enabled }
          scipion_web::dyndns_hostname: { get_input: scipion_web_dyndns_hostname }
          scipion_web::dyndns_server: { get_input: scipion_web_dyndns_server }
          scipion_web::dyndns_login: { get_input: scipion_web_dyndns_login }
          scipion_web::dyndns_password: { get_input: scipion_web_dyndns_password }
          scipion_web::dyndns_ssl: { get_input: scipion_web_dyndns_ssl }
          scipion_web::occi_robot_key_b64: { get_input: scipion_web_occi_robot_key_b64 }
          scipion_web::occi_robot_cert_b64: { get_input: scipion_web_occi_robot_cert_b64 }
          scipion_web::node_cfy_source: { get_input: scipion_web_node_cfy_source }
          scipion_web::node_cfy_revision: { get_input: scipion_web_node_cfy_revision }
    relationships:
      - type: cloudify.relationships.contained_in
        target: olinNodeHostPool

',_PROVISIONER_,`occi',`
  ### OCCI nodes #############################################################

  # olin (frontend)
  olinNode:
    type: _NODE_SERVER_
    properties:
      name: "Scipion all-in-one server node"
      resource_config:
        os_tpl: { get_input: olin_occi_os_tpl }
        resource_tpl: { get_input: olin_occi_resource_tpl }
        availability_zone: { get_input: olin_occi_availability_zone }
        network: { get_input: olin_occi_network }
        network_pool: { get_input: olin_occi_network_pool }
      agent_config: *agent_configuration
      cloud_config: *cloud_configuration
      occi_config: *occi_configuration
      fabric_env: *fabric_env

  scipionFe:
    type: _NODE_WEBSERVER_
    instances:
      deploy: 1
    properties:
      fabric_env: *fabric_env
      puppet_config:
        <<: *puppet_config
        manifests:
          start: manifests/olin.pp
        hiera:
          scipion_web::servername: { get_input: scipion_web_servername }
          westlife::volume::device: /dev/vdc
          westlife::volume::fstype: ext4
          westlife::volume::mountpoint: /data
          westlife::volume::mode: "1777"
          scipion_web::ssl_enabled: { get_input: scipion_web_ssl_enabled }
          scipion_web::ssl_email: { get_input: scipion_web_ssl_email }
          scipion_web::auth_enabled: { get_input: scipion_web_auth_enabled }
          scipion_web::auth_service_key_b64: { get_input: scipion_web_auth_service_key_b64 }
          scipion_web::auth_service_cert_b64: { get_input: scipion_web_auth_service_cert_b64 }
          scipion_web::auth_service_meta_b64: { get_input: scipion_web_auth_service_meta_b64 }
          scipion_web::dyndns_enabled: { get_input: scipion_web_dyndns_enabled }
          scipion_web::dyndns_hostname: { get_input: scipion_web_dyndns_hostname }
          scipion_web::dyndns_server: { get_input: scipion_web_dyndns_server }
          scipion_web::dyndns_login: { get_input: scipion_web_dyndns_login }
          scipion_web::dyndns_password: { get_input: scipion_web_dyndns_password }
          scipion_web::dyndns_ssl: { get_input: scipion_web_dyndns_ssl }
          scipion_web::occi_robot_key_b64: { get_input: scipion_web_occi_robot_key_b64 }
          scipion_web::occi_robot_cert_b64: { get_input: scipion_web_occi_robot_cert_b64 }
          scipion_web::node_cfy_source: { get_input: scipion_web_node_cfy_source }
          scipion_web::node_cfy_revision: { get_input: scipion_web_node_cfy_revision }
    relationships:
      - type: cloudify.relationships.contained_in
        target: olinNode

',`errprint(Missing definition of _PROVISIONER_ in the inputs
)m4exit(1)')

outputs:
  web_endpoint:
    description: Scipion Web endpoint
    value: { concat: ['http://', { get_attribute: [_NAME_OLINNODE_, ip] }] }

# vim: set syntax=yaml
