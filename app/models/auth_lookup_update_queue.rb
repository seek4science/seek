class AuthLookupUpdateQueue < ApplicationRecord
  include ResourceQueue

  def self.queue_enabled?
    Seek::Config.auth_lookup_enabled
  end
end
