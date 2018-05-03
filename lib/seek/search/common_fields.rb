module Seek
  module Search
    module CommonFields
      include Seek::ExperimentalFactors::SearchFields

      def self.included(klass)
        klass.class_eval do
          if Seek::Config.solr_enabled
            searchable(auto_index: false) do
              text :title do
                title if respond_to?(:title)
              end
              text :description do
                description if respond_to?(:description)
              end
              text :searchable_tags do
                searchable_tags if respond_to?(:searchable_tags)
              end
              text :contributor do
                contributor.try(:person).try(:name) if respond_to?(:contributor)
              end
              text :projects do
                projects.collect(&:title) if respond_to?(:projects)
              end

              text :external_asset do
                external_asset_search_terms if respond_to?(:external_asset_search_terms)
              end
            end
          end
        end
      end
    end
  end
end
