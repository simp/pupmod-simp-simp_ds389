# @summary Create a 389ds instance with a common organizational LDIF for user accounts
#
# @param instance_name
#   The unique name of the instance.
#
# @param base_dn
#   The base Distinguished Name of the directory server.
#
# @param root_dn
#   The default administrator Distinguished Name for the directory server.
#
#   * NOTE: To work around certain application bugs, items with spaces may not
#     be used in this field.
#
# @param root_pw
#   The password for the the ``$root_dn``.
#
#   * NOTE: To work around certain application bugs, items with spaces may not
#     be used in this field.
#
# @param bind_dn
#   The bind Distinguished Name of the directory server.
#
# @param bind_pw
#   The bind password.
#
# @param listen_address
#   The IP address upon which to listen.
#
# @param enable_tls
#   Whether to configure the server to use TLS and also how to copy the
#   pki certificates.
#
#   * simp => Will enable TLS and copy the certificates out from the
#             puppetserver.
#   * true => Will enable TLS and copy the certificates from a local
#             directory on the server.
#   * false => Will not enable TLS
#
# @param firewall
#   Whether to configure access through the firewall.
#
# @param trusted_nets
#   Which networks to all access through the firewall.
#
# @param port
#   The port upon which to accept normal/STARTTLS connections
#
# @param secure_port
#   The port upon which to accept LDAPS connections.
#
# @param tls_params
#    Parameters to pass to the TLS module.
#
# @param instance_params
#   Any other arguments that you wish to pass through directly to the
#   `ds389::instance` Defined Type.
#
# @param password_policy
#  Settings for the password policy.  The defaults in the module data
#  are set to meet most compliance standards.
#
# @param users_group_id
#   The group ID of the "users" group created in the install.
#
# @param administrators_group_id
#   The group ID of the "administrators" group created in the install.
#   The pupmod-simp-simp module configures permissions on systems using
#   simp with the admin.pp manifest.
#
# @author https://github.com/simp/pupmod-simp-ds389/graphs/contributors
#
class simp_ds389::instances::accounts (
  String[1]                      $instance_name           = 'accounts',
  String[2]                      $base_dn                 = simplib::lookup('simp_options::ldap::base_dn', { 'default_value' => sprintf(simplib::ldap::domain_to_dn($facts['domain'], true)) }),
  String[2]                      $root_dn                 = 'cn=Directory_Manager',
  String[2]                      $root_pw                 = simplib::passgen('simp_ds389-rootdn_accounts', { 'length' => 64, 'complexity' => 0 }),
  String[2]                      $bind_dn                 = simplib::lookup('simp_options::ldap::bind_dn', { 'default_value'   => "cn=hostAuth,ou=Hosts,${base_dn}" }),
  String[1]                      $bind_pw                 = simplib::lookup('simp_options::ldap::bind_pw', { 'default_value' => simplib::passgen("ds389_${instance_name}_bindpw", {'length' => 64})}),
  Simplib::IP                    $listen_address          = '0.0.0.0',
  Variant[Boolean, Enum['simp']] $enable_tls              = simplib::lookup('simp_options::pki', { 'default_value' => false }),
  Boolean                        $firewall                = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Simplib::Netlist               $trusted_nets            = simplib::lookup('simp_options::trusted_nets', {'default_value' => ['127.0.0.1/32'] }),
  Simplib::Port                  $port                    = 389,
  Simplib::Port                  $secure_port             = 636,
  Hash                           $tls_params              = {},
  Hash                           $instance_params         = {},
  Ds389::ConfigItem              $password_policy, #data in module

  # Default LDIF configuration parameters
  Integer[1]                     $users_group_id          = 100,
  Integer[500]                   $administrators_group_id = 700,

) {

  $_bootstrap_ldif_content = epp("${module_name}/instance/bootstrap.ldif.epp",
      {
        base_dn                 => $base_dn,
        root_dn                 => $root_dn,
        bind_dn                 => $bind_dn,
        bind_pw                 => $bind_pw,
        users_group_id          => $users_group_id,
        administrators_group_id => $administrators_group_id
      }
    )

  ds389::instance { $instance_name:
    base_dn                => $base_dn,
    root_dn                => $root_dn,
    root_dn_password       => $root_pw,
    listen_address         => $listen_address,
    enable_tls             => $enable_tls,
    port                   => $port,
    secure_port            => $secure_port,
    tls_params             => $tls_params,
    bootstrap_ldif_content => $_bootstrap_ldif_content,
    password_policy        => $password_policy,
    *                      => $instance_params
  }

  if $firewall {
    if $enable_tls {
      $_ports = [$port, $secure_port]
    } else {
      $_ports = [$port]
    }
    simp_firewalld::rule { "Allow 389DS ${instance_name} instance":
      trusted_nets => $trusted_nets,
      apply_to     => 'all',
      dports       => $_ports,
      protocol     => 'tcp'
    }
  }

}
