require 'spec_helper_acceptance'

test_name 'simp_ds389 class'

describe 'simp_ds389 class' do
  #
  #  This test sets up a 389ds server using TLS.  It sets  data using simp_options
  #  settings in hiera to mimic what would happen if simp_cli were run.
  #  It  tests connecting from other hosts using openldap client to make
  #  sure the firewall is open and the the bind_dn can access the base_dn.
  #
  servers = hosts_with_role(hosts, 'directory_server')
  clients = hosts_with_role(hosts, 'client')

  servers.each do |server|
    let(:server_manifest) {
      <<-EOS
       include 'simp_ds389::instances::accounts'

       #let vagrant ssh in
       simp_firewalld::rule { "Allow ssh":
          trusted_nets => ['ALL'],
          apply_to     => 'all',
          dports       => [22],
          protocol     => 'tcp'
       }
      EOS
    }
    let(:server_fqdn) { fact_on(server, 'fqdn') }
    let(:root_pw) { 's00perSekr!tP@ssw0rd'}
    let(:root_dn) { 'cn=Directory_Manager'}
    let(:ds_root_name) { 'accounts'}
    let(:base_dn) { 'dc=test,dc=org'}
    let(:bind_dn) { "cn=myhostAuth,ou=Hosts,#{base_dn}"}
    let(:bind_pw) { 'P@ssw0rdP@ssw0rd' }

    let(:hieradata) {{
      'simp_options::pki' => true,
      'simp_options::pki::source' => '/etc/pki/simp-testing/pki',
      'simp_options::ldap::bind_dn' => "#{bind_dn}",
      'simp_options::ldap::base_dn' => "#{base_dn}",
      'simp_options::ldap::bind_hash' => '{SHA256}UPh9BmVFn/Pg2Fx/L+Qgf7pjmr7mjR7f0WOVhAlalRc=',
      'simp_options::ldap::bind_pw' => "#{bind_pw}",
      'simp_options::firewall' => true,
      'simp_ds389::instances::accounts::root_pw' =>  "#{root_pw}",
      'simp_options::trusted_nets' => [ 'ALL' ],
      'simp_options::ldap::uri' => [ "ldaps://#{server_fqdn}" ]
    }}

    context 'set up an ldapserver with tls enabled' do
      # Using puppet_apply as a helper
      it 'should work with no errors' do
        set_hieradata_on(server, hieradata)
        apply_manifest_on(server, server_manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(server, server_manifest, :catch_changes => true)
      end

      it 'sets the environment variables for ldapsearch' do
        server.add_env_var('LDAPTLS_CACERT', "/etc/pki/simp_apps/ds389_#{ds_root_name}/x509/cacerts/cacerts.pem")
        server.add_env_var('LDAPTLS_KEY', "/etc/pki/simp_apps/ds389_#{ds_root_name}/x509/private/#{server_fqdn}.pem")
        server.add_env_var('LDAPTLS_CERT', "/etc/pki/simp_apps/ds389_#{ds_root_name}/x509/public/#{server_fqdn}.pub")
      end

      it 'should log into ldapi' do
        on(server, %(ldapsearch -x -w "#{root_pw}" -D "#{root_dn}" -H ldapi://%2fvar%2frun%2fslapd-#{ds_root_name}.socket -b "cn=tasks,cn=config"))
      end

      it 'should login to 389DS Start TLS' do
        on(server, %(ldapsearch -ZZ -x -w "#{root_pw}" -D "#{root_dn}" -H ldap://#{server_fqdn}:389  -b "cn=tasks,cn=config"))
      end

      it 'should login to 389DS encrypted' do
        on(server, %(ldapsearch -x -w "#{root_pw}" -D "#{root_dn}" -H ldaps://#{server_fqdn}:636  -b "cn=tasks,cn=config"))
      end

      it 'should have the bind account and the users and administrators groups' do
        result = on(server, %(ldapsearch -ZZ -x -w "#{root_pw}" -D "#{root_dn}" -H ldap://#{server_fqdn}  -b "#{base_dn}")).output.strip
        expect(result).to include("#{bind_dn}")
        expect(result).to include("cn=administrators,ou=Groups,#{base_dn}")
        expect(result).to include("cn=users,ou=Groups,#{base_dn}")
      end

      it 'should get results with the bind account' do
        result = on(server, %(ldapsearch -ZZ -x -w "#{bind_pw}" -D "#{bind_dn}" -H ldap://#{server_fqdn}  -b "#{base_dn}")).output.strip
        expect(result).to include("cn=users,ou=Groups,#{base_dn}")
      end
    end

    clients.each do |client|

      context "#{client} connecting to #{server}" do

        let(:client_manifest) {
        <<-EOS
         include 'simp_openldap::client'

         #let vagrant ssh in
         simp_firewalld::rule { "Allow ssh":
            trusted_nets => ['ALL'],
            apply_to     => 'all',
            dports       => [22],
            protocol     => 'tcp'
         }
        EOS
       }

        it 'should work with no errors' do
          set_hieradata_on(client, hieradata)
          apply_manifest_on(client, client_manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(client, client_manifest, :catch_changes => true)
        end
        it 'should be able to connect using the bind DN and password' do
          # LDAP server parameters are set in /etc/openldap/ldap.conf by simp_openldap
          result = on(client, "ldapsearch -D #{bind_dn} -w #{bind_pw}")
          expect(result.output).to match(/dn: cn=users,ou=Groups,/)
        end

      end
    end

  end
end
