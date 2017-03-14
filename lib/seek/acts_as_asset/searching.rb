module Seek
  module ActsAsAsset
    module Searching
      extend ActiveSupport::Concern

      included do
        include Seek::Search::CommonFields
        searchable(auto_index: false) do
          text :creators do
            creators.compact.map(&:name) if self.respond_to?(:creators)
          end

          text :other_creators do
            other_creators if self.respond_to?(:other_creators)
          end

          text :content_blob do
            content_blob_search_terms if self.respond_to?(:content_blob_search_terms)
          end

          text :assay_type_titles do
            assay_type_titles if self.respond_to?(:assay_type_titles)
          end

          text :technology_type_titles do
            technology_type_titles if self.respond_to?(:technology_type_titles)
          end
        end if Seek::Config.solr_enabled
      end
    end
  end
end
