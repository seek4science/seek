# frozen_string_literal: true

# This monkey patch is to solve a change in PrivateAddressCheck following a change in behaviour.
#  the patch applies a suggested fix presented as a pull request but not yet applied: https://github.com/jtdowney/private_address_check/pull/6
#
#  # The problem was caused by attempting to connect before checking if the address is private, resulting in a different exception, that could also potentially be used to determine what services are running on the server
#  FIXME: review this in the future to see if a new version of PrivateAddressCheck has been updated (I've set myself a reminder)
require 'private_address_check'
require 'private_address_check/tcpsocket_ext'
require 'resolv'

TCPSocket.class_eval do
  def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
    STDOUT.puts "Patched TCPSocket init - #{remote_host} #{remote_port} #{local_host} #{local_port}"
    STDOUT.puts "enabled: #{Thread.current[:private_address_check]}, is private: #{PrivateAddressCheck.resolves_to_private_address?(remote_host)}"
    STDOUT.puts "----ips:"
    ips = Socket.getaddrinfo(remote_host, nil).map { |info| IPAddr.new(info[3]) }
    pp ips
    STDOUT.puts '----'
    STDOUT.puts "----private address list:"
    pp PrivateAddressCheck::CIDR_LIST
    STDOUT.puts '----'

    begin
      STDOUT.puts  "begin 1"
      STDOUT.puts  "mapped host: #{IPSocket.getaddress(remote_host).to_s}"
      STDOUT.puts  "mapped host private?: #{PrivateAddressCheck.resolves_to_private_address?(IPSocket.getaddress(remote_host))}"

      initialize_without_private_address_check(remote_host, remote_port, local_host, local_port)
      STDOUT.puts  "begin 2"
    rescue Errno::ECONNREFUSED, SocketError, Net::OpenTimeout => e
      STDOUT.puts "Exception: #{e.class.name}"
      private_address_check! remote_host
      raise
    end

    STDOUT.puts  "priv add check"
    private_address_check! remote_address.ip_address
  end

  private

  def private_address_check!(address)
    STDOUT.puts "checking #{address} - #{Thread.current[:private_address_check]} #{PrivateAddressCheck.resolves_to_private_address?(address)}"
    return unless Thread.current[:private_address_check]
    return unless PrivateAddressCheck.resolves_to_private_address?(address)

    raise PrivateAddressCheck::PrivateConnectionAttemptedError
  end
end
