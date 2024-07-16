module Seek
  module ActsAsAsset
    # Acts as Asset behaviour that relates to content
    module ContentBlobs
      module ClassMethods
        extend ActiveSupport::Concern
        included do
          after_destroy :mark_deleted_content_blobs
        end
      end

      module InstanceMethods
        def all_content_blobs
          if self.respond_to?(:content_blobs)
            content_blobs
          elsif self.respond_to?(:content_blob)
            content_blob ? [content_blob] : []
          else
            []
          end
        end

        def single_content_blob
          all_content_blobs.size == 1 ? all_content_blobs.first : nil
        end

        # the search terms coming from the content-blob(s)
        def content_blob_search_terms
          max_terms = 920000 # an upper limit of terms, found with a large problematic file - greater than this seemed to crash solr
          all_content_blobs.map(&:search_terms).flatten.compact.uniq[0..max_terms]
        end

        def cache_remote_content_blob
          all_content_blobs.each do |blob|
            if blob.url && projects.first
              begin
                p = projects.first
                downloader = Jerm::DownloaderFactory.create p.title
                resource_type         = self.class.name.split('::')[0] # need to handle versions, e.g. Sop::Version
                data_hash             = downloader.get_remote_data blob.url, p.site_username, p.site_password, resource_type
                blob.tmp_io_object = File.open data_hash[:data_tmp_path], 'r'
                blob.content_type = data_hash[:content_type]
                blob.original_filename = data_hash[:filename]
                blob.save!
              rescue => e
                puts "Error caching remote data for url=#{content_blob.url} #{e.message[0..50]} ..."
              end
            end
            self.save!
          end
        end

        # flags that content blob has been deleted, after the associated asset has been destroyed
        def mark_deleted_content_blobs
          all_content_blobs.each do |cb|
            cb.update_column(:deleted, true)
          end
        end
      end
    end
  end
end
