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
              'passwordchange'=> 'on',
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

        context "with params set in hiera" do
          let(:hieradata) { 'turn_on_all' }
          it { is_expected.to contain_simp_firewalld__rule('Allow 389DS accounts instance')}
          it { is_expected.to contain_ds389__instance('accounts')
            .with_listen_address('0.0.0.0')
            .with_enable_tls('simp')
            .with_port(333)
            .with_secure_port(666)
            .with_tls_params({
               'source' => '/my/source'
            })
            .with_service_user('myuser')
            .with_base_dn('dc=test,dc=org')
            .with_root_dn('cn=Directory_Manager')
          }
          it { is_expected.to contain_ds389__instance('accounts')
            .with_password_policy({
              'nsslapd-pwpolicy-local' => 'on',
              'passwordchange'=> 'on',
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
              'passwordLockoutDuration' => 999,
              'passwordMaxFailure' => 3,
              'passwordResetFailureCount' => 600,
              'passwordCheckSyntax' => 'on',
              'passwordMinLength' => 15,
              'passwordMinDigits' => 1,
              'passwordMinAlphas' => 1,
              'passwordMinUppers' => 1,
              'passwordMinLowers' => 3,
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
      end
    end
  end

end
