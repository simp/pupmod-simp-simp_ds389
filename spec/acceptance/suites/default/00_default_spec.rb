require 'spec_helper_acceptance'

test_name 'simp_ds389 class'

describe 'simp_ds389 class' do
  let(:manifest) {
    <<-EOS
      class { 'simp_ds389': }
    EOS
  }

  context 'default parameters' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      apply_manifest(manifest, :catch_failures => true)
    end

    it 'should be idempotent' do
      apply_manifest(manifest, :catch_changes => true)
    end


    describe package('simp_ds389') do
      it { is_expected.to be_installed }
    end

    describe service('simp_ds389') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
