require 'spec_helper'

describe 'simp_ds389' do
  shared_examples_for "a structured module" do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('simp_ds389') }
    it { is_expected.to contain_class('simp_ds389') }
    it { is_expected.to contain_class('simp_ds389::install').that_comes_before('Class[simp_ds389::config]') }
    it { is_expected.to contain_class('simp_ds389::config') }
    it { is_expected.to contain_class('simp_ds389::service').that_subscribes_to('Class[simp_ds389::config]') }

    it { is_expected.to contain_service('simp_ds389') }
    it { is_expected.to contain_package('simp_ds389').with_ensure('installed') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        context "simp_ds389 class without any parameters" do
          let(:params) {{ }}
          it_behaves_like "a structured module"
          it { is_expected.to contain_class('simp_ds389').with_trusted_nets(['127.0.0.1/32']) }
        end

        context "simp_ds389 class with firewall enabled" do
          let(:params) {{
            :firewall => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('simp_ds389::config::firewall') }

          it { is_expected.to contain_class('simp_ds389::config::firewall').that_comes_before('Class[simp_ds389::service]') }
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_simp_ds389_tcp_connections').with_dports(9999)
          }
        end

        context "simp_ds389 class with selinux enabled" do
          let(:params) {{
            :selinux => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('simp_ds389::config::selinux') }
          it { is_expected.to contain_class('simp_ds389::config::selinux').that_comes_before('Class[simp_ds389::service]') }
          it { is_expected.to create_notify('FIXME: selinux') }
        end

        context "simp_ds389 class with auditing enabled" do
          let(:params) {{
            :auditing => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('simp_ds389::config::auditing') }
          it { is_expected.to contain_class('simp_ds389::config::auditing').that_comes_before('Class[simp_ds389::service]') }
          it { is_expected.to create_notify('FIXME: auditing') }
        end

        context "simp_ds389 class with logging enabled" do
          let(:params) {{
            :logging => true
          }}

          ###it_behaves_like "a structured module"
          it { is_expected.to contain_class('simp_ds389::config::logging') }
          it { is_expected.to contain_class('simp_ds389::config::logging').that_comes_before('Class[simp_ds389::service]') }
          it { is_expected.to create_notify('FIXME: logging') }
        end
      end
    end
  end

  context 'unsupported operating system' do
    describe 'simp_ds389 class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
        :os => {
          :family => 'Solaris',
          :name   => 'Nexenta',
        }
      }}

      it { expect { is_expected.to contain_package('dummy') }.to raise_error(Puppet::Error, /'Nexenta' is not supported/) }
    end
  end
end
