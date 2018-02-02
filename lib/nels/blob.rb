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

    def retrieve_from_nels(access_token)
      client_class = Nels::Rest::Client
      rest_client = client_class.new(access_token)
      ref = url.scan(/ref=([^&]+)/).try(:first).try(:first)

      self.tmp_io_object = StringIO.new(rest_client.sample_metadata(ref))
      self.original_filename = 'sample_metadata.xlsx'
      self.content_type = mime_types_for_extension('xlsx').sort.first

      save
    end
  end
end
