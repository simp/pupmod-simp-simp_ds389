require 'spec_helper'

describe 'simp_ds389::instances::accounts' do

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        context "simp_ds389 class without any parameters" do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_ds389__instance('accounts')
            .with_listen_address('0.0.0.0')
            .with_trusted_nets(['127.0.0.1/32'])
            .with_enable_tls(false)
            .with_port(389)
            .with_secure_port(636)
            .with_tls_params({})
            .with_base_dn(%r{^dc=})
            .with_root_dn('cn=Directory_Manager')
          }
          it { is_expected.to contain_ds389__instance('accounts')
            .with_password_policy({
              'nsslapd-pwpolicy-local' => 'on',
              'passwordChange'=> 'on',
              'passwordMustChange' => 'on',
              'passwordHistory' => 'on',
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
            })
          }
          it { is_expected.not_to contain_simp_firewalld__rule('Allow 389DS accounts instance')}
        end

        context "with params set" do
          let(:params) {{
              :instance_name           => 'myaccounts',
              :base_dn                 => 'dc=test,dc=org',
              :root_dn                 => 'cn=myDirectory_Manager',
              :root_pw                 => 'myrootpassword',
              :bind_dn                 => 'cn=myhostAuth,ou=Hosts',
              :bind_pw                 => 'mypassword',
              :listen_address          => '1.2.3.4',
              :enable_tls              => true,
              :firewall                => true,
              :trusted_nets            => ['ALL'],
              :port                    => 388,
              :secure_port             => 638,
              :tls_params              => { 'source' => '/my/source' },
              :instance_params         => { 'service_user' => 'myuser' },
              :users_group_id          => 666,
              :administrators_group_id => 777
          }}

          it { is_expected.to contain_ds389__instance('myaccounts').with({
            :listen_address => '1.2.3.4',
            :trusted_nets => ['ALL'],
            :enable_tls => true,
            :port => 388,
            :secure_port => 638,
            :tls_params =>  {
               'source' => '/my/source'
            },
            :base_dn => 'dc=test,dc=org',
            :bind_dn => 'cn=myhostAuth,ou=Hosts',
            :root_dn => 'cn=myDirectory_Manager',
            :root_pw => 'myrootpassword',
            :bind_pw => 'mypassword',
            :service_user => 'myuser',
          })}
          it { is_expected.to contain_simp_firewalld__rule('Allow 389DS myaccounts instance')}

        end
      end
    end
  end

end
