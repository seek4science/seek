require 'rest-client'
require 'uri'

module Nels
  module Rest
    def self.client_class
      if Seek::Config.nels_use_dummy_client
        Nels::Rest::DummyClient
      else
        Nels::Rest::Client
      end
    end
  end
end