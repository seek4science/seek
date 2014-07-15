module Seek
  module Search
    module SearchSunspot
      def self.included klass
        klass.class_eval do
          searchable do
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
                contributor.try(:name)
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

["Assay", "DataFile", "Event", "Institution", "Investigation", "Model", "Person", "Presentation", "Programme", "Project", "Publication", "Sample", "Sop", "Specimen", "Strain", "Study", "Workflow"].each do |klass|
  klass.constantize.class_eval do
    include Seek::Search::SearchSunspot
  end
end
