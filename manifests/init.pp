# @summary  This module id a profile module.  It is designed to work with the
#   ds389 module to set up a directory server to work with a SIMP system.
#   By default it will setup and configure a user database.
#
# @example Basic usage
#   include  'simp_ds389'
#
# @param create_default
#   If enabled this will configure an db instance for users with TLS-enabled communication
#   using both TLS and start TLS.
#   It provides default access controls.
#   It configures a default password policy.
#
# @param trusted_nets
#   A whitelist of subnets (in CIDR notation) permitted access
#
# @param auditing
#   If true, manage auditing for simp_ds389
#
# @param firewall
#   If true, manage firewall rules to acommodate simp_ds389
#
# @param pki
#   If true, manage PKI/PKE configuration for simp_ds389
#
# @param selinux
#   If true, manage selinux to permit simp_ds389
#
# @author simp
#
class simp_ds389 (
# @summary Create a default instance with a common organizational LDIF
#
# @param instance_name
#   The unique name of this instance
#
# @param listen_address
#   The IP address upon which to listen
#
# @param bootstrap_with_defaults
#   Whether to use the inbuilt user/group directory structure
#
#   * If this is `true`, the traditional layout that the SIMP LDAP system has provided
#     will be used
#   * If this is `false`, the internal 389DS layout will be used
#     * NOTE: other SIMP module defaults may not work without alteration
#
# @param instance_params
#   Any other arguments that you wish to pass through directly to the
#   `ds389::instance` Defined Type.
#
# @author https://github.com/simp/pupmod-simp-ds389/graphs/contributors
#
  String[1]                      $instance_name           = 'puppet_default',
  String[2]                      $base_dn                 = simplib::lookup('simp_options::ldap::base_dn', { 'default_value' => sprintf(simplib::ldap::domain_to_dn($facts['domain'], true)) }),
  String[2]                      $root_dn                 = 'cn=Directory_Manager',
  String[2]                      $bind_dn                 = simplib::lookup('simp_options::ldap::bind_dn', { 'default_value' => "cn=hostAuth,ou=Hosts,${base_dn}" }),
  String[1]                      $bind_pw                 = simplib::lookup('simp_options::ldap::bind_hash', { 'default_value' => simplib::passgen("ds389_${instance_name}_bindpw", {'length' => 64})}),
  Boolean                        $bootstrap_with_defaults = true,
  Simplib::IP                    $listen_address          = '0.0.0.0',
  Variant[Boolean, Enum['simp']] $enable_tls              = simplib::lookup('simp_options::pki', { 'default_value'                                         => false }),
  Boolean                        $firewall                = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  
  Hash                           $tls_params              = {},
  Hash                           $instance_params         = {},

  # Default LDIF configuration parameters
  Integer[1]   $users_group_id                            = 100,
  Integer[500] $administrators_group_id                   = 700
) {
  assert_private()

  if $instance_params['ds_setup_ini_content'] {
    $_default_params = {
      'ds_setup_ini_content' => $instance_params['ds_setup_ini_content']
    }
  }
  elsif $instance_params['bootstrap_ldif_content'] {
    $_default_params = {
      'bootstrap_ldif_content' => $instance_params['bootstrap_ldif_content']
    }
  }
  elsif $bootstrap_with_defaults {
    $_default_params = {
      'bootstrap_ldif_content' => epp("${module_name}/instance/bootstrap.ldif.epp",
        {
          base_dn                 => $base_dn,
          root_dn                 => $root_dn,
          bind_dn                 => $bind_dn,
          bind_pw                 => $bind_pw,
          users_group_id          => $users_group_id,
          administrators_group_id => $administrators_group_id
        }
      )
    }
  }
  else {
    $_default_params = {}
  }

  ds389::instance { $instance_name:
    base_dn        => $base_dn,
    root_dn        => $root_dn,
    listen_address => $listen_address,
    enable_tls     => $enable_tls,
    tls_params     => $tls_params,
    *              => merge($_default_params, $instance_params)
  }
}
  Boolean                        $create_default        = true,
  String                         $default_instance_name = 'puppet_default',
  String[2]                      $base_dn                 = simplib::lookup('simp_options::ldap::base_dn', { 'default_value' => sprintf(simplib::ldap::domain_to_dn($facts['domain'], true)) }),
  String[2]                      $root_dn                 = 'cn=Directory_Manager',
  String[2]                      $bind_dn                 = simplib::lookup('simp_options::ldap::bind_dn', { 'default_value' => "cn=hostAuth,ou=Hosts,${base_dn}" }),
  String[1]                      $bind_pw                 = simplib::lookup('simp_options::ldap::bind_hash', { 'default_value' => simplib::passgen("ds389_${instance_name}_bindpw", {'length' => 64})}),

  Simplib::Port                      $tcp_listen_port    = 9999,
  Simplib::Netlist                   $trusted_nets       = simplib::lookup('simp_options::trusted_nets', {'default_value' => ['127.0.0.1/32'] }),
  Variant[Boolean,Enum['simp']]      $pki         = simplib::lookup('simp_options::pki', { 'default_value'         => false }),
  Boolean                            $auditing    = simplib::lookup('simp_options::auditd', { 'default_value'      => false }),
  Variant[Boolean,Enum['firewalld']] $firewall    = simplib::lookup('simp_options::firewall', { 'default_value'    => false }),
  Boolean                            $logging     = simplib::lookup('simp_options::syslog', { 'default_value'      => false }),
  Boolean                            $selinux     = simplib::lookup('simp_options::selinux', { 'default_value'     => false }),
  Boolean                            $tcpwrappers = simplib::lookup('simp_options::tcpwrappers', { 'default_value' => false })
) {

  simplib::assert_metadata($module_name)

  include 'simp_ds389::install'
  include 'simp_ds389::config'
  include 'simp_ds389::service'

  Class[ 'simp_ds389::install' ]
  -> Class[ 'simp_ds389::config' ]
  ~> Class[ 'simp_ds389::service' ]

  if $pki {
    include 'simp_ds389::config::pki'
    Class[ 'simp_ds389::config::pki' ]
    -> Class[ 'simp_ds389::service' ]
  }

  if $auditing {
    include 'simp_ds389::config::auditing'
    Class[ 'simp_ds389::config::auditing' ]
    -> Class[ 'simp_ds389::service' ]
  }

  if $firewall {
    include 'simp_ds389::config::firewall'
    Class[ 'simp_ds389::config::firewall' ]
    -> Class[ 'simp_ds389::service' ]
  }

  if $logging {
    include 'simp_ds389::config::logging'
    Class[ 'simp_ds389::config::logging' ]
    -> Class[ 'simp_ds389::service' ]
  }

  if $selinux {
    include 'simp_ds389::config::selinux'
    Class[ 'simp_ds389::config::selinux' ]
    -> Class[ 'simp_ds389::service' ]
  }

  if $tcpwrappers {
    include 'simp_ds389::config::tcpwrappers'
    Class[ 'simp_ds389::config::tcpwrappers' ]
    -> Class[ 'simp_ds389::service' ]
  }
}
