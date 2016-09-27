module Seek
  module ActsAsAsset
    module Searching
      extend ActiveSupport::Concern

      included do
        include Seek::Search::CommonFields
        searchable(auto_index: false) do
          text :creators do
            creators.compact.map(&:name)
          end if self.respond_to?(:creators)

          text :other_creators do
            other_creators
          end if self.respond_to?(:other_creators)

          text :content_blob do
            content_blob_search_terms
          end if self.respond_to?(:content_blob_search_terms)

          text :assay_type_titles do
            assay_type_titles
          end if self.respond_to?(:assay_type_titles)

          text :technology_type_titles do
            technology_type_titles
          end if self.respond_to?(:technology_type_titles)
        end if Seek::Config.solr_enabled
      end
    end
  end
end
