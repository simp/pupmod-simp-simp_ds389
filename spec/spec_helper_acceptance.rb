require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers

# Helper method to wait for a port to be accessible
def wait_for_tcp_from(src_host, dst_host, port, timeout: 120)
  start = Time.now
  loop do
    cmd = %(timeout 5 bash -lc "echo | openssl s_client -connect #{dst_host}:#{port} -servername #{dst_host} >/dev/null 2>&1")
    result = on(src_host, cmd, acceptable_exit_codes: [0, 1, 124])

    return true if result.exit_code == 0

    raise "Port #{port} not reachable from #{src_host} to #{dst_host} after #{timeout}s" if (Time.now - start) > timeout
    sleep 2
  end
end

# Helper method to update /etc/hosts with all host entries
#
# This is based on hack_etc_hosts in Beaker::HostPrebuiltSteps
# On AlmaLinux 10 (at least), the address of the host changes
# and host['ip'] is incorrect.
def update_etc_hosts(test_hosts)
  etc_hosts = "127.0.0.1\tlocalhost localhost.localdomain\n"
  test_hosts.each do |host|
    # Get IP from networking facts, assuming interfaces start with 'e'
    interfaces = fact_on(host, 'networking.interfaces')
    ip = interfaces.select { |name, data| name.downcase.start_with?('e') && data['ip'] }
                   .values
                   .last
                   &.[]('ip')
    # Fall back to host['vm_ip'] or host['ip'] if no matching interface found
    ip ||= host['vm_ip'] || host['ip'].to_s

    hostname = host[:vmhostname] || host.name
    domain = fact_on(host, 'networking.domain')
    etc_hosts += "#{ip}\t#{hostname}.#{domain} #{hostname}\n"
  end
  test_hosts.each do |host|
    if host['platform'].include?('windows') && !host.is_cygwin?
      on(host, "echo '#{etc_hosts}' > C:\\Windows\\System32\\drivers\\etc\\hosts")
    else
      host.exec(Beaker::Command.new("cat > /etc/hosts <<EOF\n#{etc_hosts}EOF"))
    end
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
