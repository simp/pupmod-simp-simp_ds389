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
      'simp_options::ldap::uri' => [ "ldaps://#{server_fqdn}" ],
      'simp_ds389::instances::accounts::password_policy' => {
        'passwordWarning' => 99999,
        'passwordMinAge' => 0
      }
    }}
    let(:default_passwordpolicy) {{
              'nsslapd-pwpolicy-local' => 'on',
              'passwordChange'=> 'on',
              'passwordMustChange' => 'on',
              'passwordInHistory' => 6,
              'passwordTrackUpdateTime' => 'on',
              'passwordWarning' => 86400,
              'passwordIsGlobalPolicy' => 'on',
              'passwordExp' => 'on',
              'passwordMaxAge' => 7776000,
              'passwordMinAge' => 1800,
              'passwordGraceLimit' => 0,
              'passwordLockout' => 'on',
              'passwordUnlock' => 'on',
              'passwordLockoutDuration' => 900,
              'passwordMaxFailure' => 3,
              'passwordResetFailureCount' => 600,
              'passwordCheckSyntax' => 'on',
              'passwordMinLength' => 15,
              'passwordMinDigits' => 1,
              'passwordMinAlphas' => 1,
              'passwordMinUppers' => 1,
              'passwordMinLowers' => 1,
              'passwordMinSpecials' => 1,
              'passwordMaxRepeats' => 3,
              'passwordMinCategories' => 3,
              'passwordMinTokenLength' => 3,
              'nsslapd-pwpolicy-inherit-global' => 'on',
              'passwordMaxClassChars' => 3,
              'passwordMaxSequence' => 4,
              'passwordMaxSeqSets' => 2,
              'passwordPalindrome' => 'on',
              'passwordDictCheck' => 'on',
              'passwordHistory' => 'on',
   }}


    context 'check password policy' do

      it "should have default password policy "  do
        result = on(server, %(dsconf -j  -w "#{root_pw}" -D "#{root_dn}"  accounts config get)).output.strip
        config_hash = JSON.parse(result)
        attrs_hash = config_hash['attrs']
        default_passwordpolicy.each do  |key,value|
          expect(attrs_hash).to have_key("#{key.downcase}")
          expect(attrs_hash[key.downcase]).to include("#{value}")
        end
      end
    end

  end
end
