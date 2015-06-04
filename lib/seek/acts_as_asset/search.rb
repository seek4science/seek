module Seek
  module ActsAsAsset
    module Search
      extend ActiveSupport::Concern

      included do
        include Seek::Search::CommonFields
        searchable(auto_index: false) do
          text :creators do
            if self.respond_to?(:creators)
              creators.compact.map(&:name)
            end
          end
          text :other_creators do
            if self.respond_to?(:other_creators)
              other_creators
            end
          end
          text :content_blob do
            content_blob_search_terms
          end
          text :assay_type_titles, :technology_type_titles
        end if Seek::Config.solr_enabled
      end
    end
  end
end
