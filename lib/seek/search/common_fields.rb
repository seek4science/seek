module Seek
  module Search
    module CommonFields
      include Seek::ExperimentalFactors::SearchFields

      def self.included klass
        klass.class_eval do
          searchable(auto_index: false) do
            text :title do
              if self.respond_to?(:title)
                title
              end
            end
            text :description do
              if self.respond_to?(:description)
                description
              end
            end
            text :searchable_tags do
              if self.respond_to?(:searchable_tags)
                searchable_tags
              end
            end
            text :contributor do
              if self.respond_to?(:contributor)
                contributor.try(:person).try(:name)
              end
            end
            text :projects do
              if self.respond_to?(:projects)
                projects.collect(&:title)
              end
            end
          end if Seek::Config.solr_enabled
        end
      end
    end
  end
end
