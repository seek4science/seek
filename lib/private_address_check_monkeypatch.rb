# frozen_string_literal: true

# This monkey patch is to solve a change in PrivateAddressCheck following a change in behaviour.
#  the patch applies a suggested fix presented as a pull request but not yet applied: https://github.com/jtdowney/private_address_check/pull/6
#
#  # The problem was caused by attempting to connect before checking if the address is private, resulting in a different exception, that could also potentially be used to determine what services are running on the server
#  FIXME: review this in the future to see if a new version of PrivateAddressCheck has been updated (I've set myself a reminder)

TCPSocket.class_eval do
  alias_method :initialize_without_private_address_check2, :initialize

  def initialize(remote_host, remote_port, local_host = nil, local_port = nil)
    begin
      initialize_without_private_address_check2(remote_host, remote_port, local_host, local_port)
    rescue SystemCallError, SocketError
      private_address_check! remote_host
      raise
    end

    private_address_check! remote_address.ip_address
  end

  private

  def private_address_check!(address)
    return unless Thread.current[:private_address_check]
    return unless PrivateAddressCheck.resolves_to_private_address?(address)

    raise PrivateAddressCheck::PrivateConnectionAttemptedError
  end
end
