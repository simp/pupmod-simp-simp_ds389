require 'spec_helper_acceptance'

test_name 'simp_ds389 class'

describe 'simp_ds389 class' do
  servers = hosts_with_role(hosts, 'directory_server')

  servers.each do |server|
    context "on #{server} " do
      let(:server_manifest) {
        <<-EOS
         include 'simp_ds389::instances::accounts'
        EOS
      }
      let(:server_fqdn) { fact_on(server, 'fqdn') }
      let(:root_pw) { 's00perSekr!tP@ssw0rd'}
      #default base_dn should be domain
      let(:domain) { fact_on(server,'domain') }

      let(:base_dn) { 'dc=' + "#{domain}".split('.').join(',dc=') }

      # These are expected  defaults.  Will use these for tests not to set things.
      let(:bind_dn) { "cn=hostAuth,ou=Hosts,#{base_dn}"}
      let(:root_dn) { 'cn=Directory_Manager'}
      let(:ds_root_name) { 'accounts'}

      let(:hieradata) {{
        'simp_ds389::instances::accounts::root_pw' =>  "#{root_pw}",
      }}

      context 'set up an ldapserver with defaults' do
        # Using puppet_apply as a helper
        it 'should work with no errors' do
          set_hieradata_on(server, hieradata)
          apply_manifest_on(server, server_manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(server, server_manifest, :catch_changes => true)
        end

        it 'should have a dirsrv  accounts instance' do
          result = on(server, '/sbin/dsctl -l').output.strip
          expect(result).to include("slapd-#{ds_root_name}")
        end
        it 'should log into ldapi' do
          on(server, %(ldapsearch -x -w "#{root_pw}" -D "#{root_dn}" -H ldapi://%2fvar%2frun%2fslapd-#{ds_root_name}.socket -b "cn=tasks,cn=config"))
        end

        it 'should login to 389DS without' do
          on(server, %(ldapsearch -x -w "#{root_pw}" -D "#{root_dn}" -H ldap://#{server_fqdn}:389  -b "cn=tasks,cn=config"))
        end

        it 'should not login to 389DS encrypted' do
          expect { on(server, %(ldapsearch -x -w "#{root_pw}" -D "#{root_dn}" -H ldaps://#{server_fqdn}:636  -b "cn=tasks,cn=config")) }.to raise_error(Beaker::Host::CommandFailure)
        end

        it 'should have the bind account and the users and administrators groups' do
          result = on(server, %(ldapsearch x -w "#{root_pw}" -D "#{root_dn}" -H ldap://#{server_fqdn}  -b "#{base_dn}")).output.strip
          expect(result).to include("#{bind_dn}")
          expect(result).to include("cn=administrators,ou=Groups,#{base_dn}")
          expect(result).to include("cn=users,ou=Groups,#{base_dn}")
        end

      end

      context "remove the instance" do
        let(:remove_manifest) {
          <<-EOS
           ds389::instance { "#{ds_root_name}":
             ensure => 'absent'
           }
          EOS
        }
        it 'should work with no errors' do
          apply_manifest_on(server, remove_manifest, :catch_failures => true)
        end

        it 'should be idempotent' do
          apply_manifest_on(server, remove_manifest, :catch_changes => true)
        end

        it 'should not have a dirsrv  accounts instance' do
          result = on(server, '/sbin/dsctl -l').output.strip
          expect(result).not_to include("slapd-#{ds_root_name}")
        end
      end

    end
  end
end
