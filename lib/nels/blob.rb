module Nels
  module Blob
    NELS_BASE = 'https://test-fe.cbu.uib.no'

    def self.prepended(base)
      base.class_eval do
        scope :for_nels, (->() { where("url LIKE '#{NELS_BASE}%'") })
      end
    end

    def nels?
      url && valid_url?(url) && url.start_with?(NELS_BASE)
    end
  end
end