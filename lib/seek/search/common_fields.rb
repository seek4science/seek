module Seek
  module Search
    module CommonFields
      include Seek::ExperimentalFactors::SearchFields

      def self.included(klass)
        klass.class_eval do
          searchable(auto_index: false) do
            text :title do
              title if self.respond_to?(:title)
            end
            text :description do
              description if self.respond_to?(:description)
            end
            text :searchable_tags do
              searchable_tags if self.respond_to?(:searchable_tags)
            end
            text :contributor do
              if self.respond_to?(:contributor)
                contributor.try(:person).try(:name)
              end
            end
            text :projects do
              projects.collect(&:title) if self.respond_to?(:projects)
            end
          end if Seek::Config.solr_enabled
        end
      end
    end
  end
end
