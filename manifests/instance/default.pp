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
class simp_ds389::instance::default (
  String[2]                      $base_dn                 = simp_ds389::base_dn,
  String[2]                      $root_dn                 = simp_ds389::root_dn,
  String[2]                      $bind_dn                 = simp_ds389::binddn,
  String[1]                      $bind_pw                 = simp_ds389::bindpw,
  Variant[Boolean, Enum['simp']] $enable_tls              = simp_ds::enable_tls,
  Boolean                        $use_firewalld           = $simp_ds::use_firewalld,
  Hash                           $tls_params              = simp_ds389::tls_params,
  Hash                           $instance_params         = {},

  String[1]                      $instance_name           = 'puppet_default',
  Simplib::IP                    $listen_address          = '0.0.0.0',
  Simplib::Port                  $port                    = 389,
  Simplib::Port                  $secure_port             = 636,
  # Default LDIF configuration parameters
  Integer[1]                     $users_group_id                            = 100,
  Integer[500]                   $administrators_group_id                   = 700,

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
  else {
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

  ds389::instance { $instance_name:
    base_dn        => $base_dn,
    root_dn        => $root_dn,
    listen_address => $listen_address,
    enable_tls     => $enable_tls,
    port           => $port,
    secure_port    => $secure_port,
    tls_params     => $tls_params,
    *              => merge($_default_params, $instance_params)
  }

  if $simp_ds389::firewall {
    if $enable_tls {
      $_ports = [$port, $secure_port]
    } else {
      $_ports = [$port]
    }
    simp_firewalld::rule { "Allow 389DS ${instance_name} instance":
      trusted_nets => $simp_ds389::trusted_nets,
      apply_to     => 'all',
      dports       => $_ports,
      protocol     => 'tcp'
    }
  }

}
