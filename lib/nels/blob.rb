module Nels
  module Blob
    def self.prepended(base)
      base.class_eval do
        scope :for_nels, (->() { where("url LIKE '#{Seek::Config.nels_permalink_base}%'") })
      end
    end

    def nels?
      url && valid_url?(url) && url.start_with?(Seek::Config.nels_permalink_base)
    end

    def retrieve_from_nels(access_token)
      rest_client = Nels::Rest::Client.new(access_token)
      ref = url.scan(/ref=([^&]+)/).try(:first).try(:first)

      self.tmp_io_object = StringIO.new(rest_client.sample_metadata(ref))
      self.original_filename = 'sample_metadata.xlsx'
      self.content_type = mime_types_for_extension('xlsx').sort.first

      save
    end
  end
end
