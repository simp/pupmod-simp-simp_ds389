require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers

# Helper method to wait for a port to be accessible
def wait_for_port(host, port, timeout: 120)
  on(host, 'dnf install -y netcat', acceptable_exit_codes: [0, 1]) # netcat may already be installed, so allow exit code 1
  start_time = Time.now
  loop do
    begin
      # Try to connect to the port
      result = on(host, "nc -z localhost #{port}", acceptable_exit_codes: [0, 1])
      return true if result.exit_code == 0
    rescue StandardError
      # Connection failed, continue retrying
    end

    raise "Port #{port} not open on #{host} after #{timeout} seconds" if Time.now - start_time > timeout
    sleep 2
  end
end

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end

RSpec.configure do |c|
  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Detect cases in which no examples are executed (e.g., nodeset does not
  # have hosts with required roles)
  c.fail_if_no_examples = true

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install modules and dependencies from spec/fixtures/modules
    copy_fixture_modules_to(hosts)
    begin
      server = only_host_with_role(hosts, 'server')
    rescue ArgumentError => e
      server = only_host_with_role(hosts, 'default')
    end

    # Generate and install PKI certificates on each SUT
    Dir.mktmpdir do |cert_dir|
      run_fake_pki_ca_on(server, hosts, cert_dir)
      hosts.each { |sut| copy_pki_to(sut, cert_dir, '/etc/pki/simp-testing') }
    end

    # add PKI keys
    copy_keydist_to(server)
  rescue StandardError, ScriptError => e
    raise e unless ENV['PRY']
    require 'pry'
    binding.pry # rubocop:disable Lint/Debugger
  end
end
