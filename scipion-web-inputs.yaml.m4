---

define(SQ,')

############################################
# Provisioner
#
# Note: Uncomment one of the following provisioners
# to choose between OCCI or Host-pool

define(_PROVISIONER_, occi)dnl
# define(_PROVISIONER_, hostpool)dnl


############################################
# OCCI authentication options

# OCCI server URL, defaults to the CESNET's FedCloud site
occi_endpoint: 'https://carach5.ics.muni.cz:11443'

# OCCI authentication method, valid options: x509, token, basic, digest, none
occi_auth: 'x509'

# OCCI username for basic or digest authentication, defaults to "anonymous"
occi_username: ''

# OCCI password for basic, digest and x509 authentication
occi_password: ''

# OCCI path to user's x509 credentials
occi_user_cred: '/tmp/x509up_u1000'

# OCCI path to CA certificates directory
occi_ca_path: ''

# OCCI using VOMS credentials; modifies behavior of the X509 authN module
occi_voms: True


############################################
# Host-pool plugin options

# Host-pool service endpoint
hostpool_service_url: 'http://127.0.0.1:8080'

# Host-pool nodes remote user
hostpool_username: 'root'

# Host-pool nodes remote user
hostpool_private_key: | ifelse(_PROVISIONER_,`hostpool',`
esyscmd(`/bin/bash -c 'SQ`set -o pipefail; cat resources/ssh_hostpool/id_rsa | sed -e "s/^/  /"'SQ)
ifelse(sysval, `0', `', `m4exit(`1')')dnl
',`')

############################################
# Contextualization

# remote user for accessing the portal instances
cc_username: 'cfy'

# SSH public key for remote user
cc_public_key: |
esyscmd(`/bin/bash -c 'SQ`set -o pipefail; cat resources/ssh_cfy/id_rsa.pub | sed -e "s/^/  /"'SQ)
ifelse(sysval, `0', `', `m4exit(`1')')dnl

# SSH private key (filename or inline) for remote user
cc_private_key: |
esyscmd(`/bin/bash -c 'SQ`set -o pipefail; cat resources/ssh_cfy/id_rsa | sed -e "s/^/  /"'SQ)
ifelse(sysval, `0', `', `m4exit(`1')')dnl

############################################
# Main node (portal, batch server) deployment parameters

# OS template
olin_occi_os_tpl: 'uuid_enmr_egi_ubuntu_server_16_04_lts_cerit_sc_271'

# sizing
olin_occi_resource_tpl: 'medium'

# availability zone
olin_occi_availability_zone: 'uuid_fedcloud_cerit_sc_103'

# network
olin_occi_network: ''

# network pool
olin_occi_network_pool: ''

# scratch size (in GB)
olin_occi_scratch_size: 2

# list of filter tags for the Host-pool
olin_hostpool_tags: ['scipion']


############################################
# Application

# portal servername for redirects, SSL certificates, defaults to portal FQDN
scipion_web_servername: NULL

# enable https:// only access on the web portal secured by Let's Encrypt
scipion_web_ssl_enabled: True  # if True, setup valid admin e-mail below

# your valid contact e-mail address
scipion_web_ssl_email: 'root@localhost'

# node deployment blueprints git URL and revision
scipion_web_node_cfy_source: NULL
scipion_web_node_cfy_revision: NULL

# DynDNS: connection parameters for frontend registration via dyndns API
scipion_web_dyndns_enabled: False
scipion_web_dyndns_hostname: ''
scipion_web_dyndns_server: ''
scipion_web_dyndns_login: ''
scipion_web_dyndns_password: ''
scipion_web_dyndns_ssl: "yes"            # "yes" or "no"

# user SAML authentication via mod_auth_mellon
scipion_web_auth_enabled: True   # if True, SSL needs to be enabled
scipion_web_auth_service_key_b64:  'esyscmd(base64 -w0 service.key)'
scipion_web_auth_service_cert_b64: 'esyscmd(base64 -w0 service.cert)'
scipion_web_auth_service_meta_b64: 'esyscmd(base64 -w0 service.xml)'

# put base64 encoded content of OCCI robot certificate/key
scipion_web_occi_robot_key_b64: 'esyscmd(base64 -w0 robotkey.pem)'
  ifelse(sysval, `0', `', `m4exit(`1')')dnl

scipion_web_occi_robot_cert_b64: 'esyscmd(base64 -w0 robotcert.crt)'
  ifelse(sysval, `0', `', `m4exit(`1')')dnl

# vim: set syntax=yaml
