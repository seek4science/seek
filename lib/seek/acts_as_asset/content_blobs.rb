module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to content
    module ContentBlobs
      module InstanceMethods
        def contains_downloadable_items?
          all_content_blobs.compact.any? { |blob| blob.is_downloadable? }
        end

        def all_content_blobs
          if self.respond_to?(:content_blobs)
            self.content_blobs
          elsif self.respond_to?(:content_blob)
            [self.content_blob]
          else
            []
          end
        end

        def single_content_blob
          all_content_blobs.size == 1 ? all_content_blobs.first : nil
        end

        # the search terms coming from the content-blob(s)
        def content_blob_search_terms
          all_content_blobs.map do |blob|
            blob.search_terms
          end.flatten.compact.uniq
        end

        def cache_remote_content_blob
          all_content_blobs.each do |blob|
            if blob.url && projects.first
              begin
                p = projects.first
                p.decrypt_credentials
                downloader = Jerm::DownloaderFactory.create p.title
                resource_type         = self.class.name.split('::')[0] # need to handle versions, e.g. Sop::Version
                data_hash             = downloader.get_remote_data blob.url, p.site_username, p.site_password, resource_type
                blob.tmp_io_object = File.open data_hash[:data_tmp_path], 'r'
                blob.content_type     = data_hash[:content_type]
                blob.original_filename = data_hash[:filename]
                blob.save!
              rescue => e
                puts "Error caching remote data for url=#{content_blob.url} #{e.message[0..50]} ..."
              end
            end
            self.save!
          end
        end
      end
    end
  end
end
