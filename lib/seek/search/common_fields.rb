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

    module BiosampleFields
      def self.included klass
        klass.class_eval do
          include Seek::Search::CommonFields

          searchable(auto_index: false) do
            text :genotype_info do
              if self.respond_to?(:genotype_info)
                genotype_info
              end
            end
            text :phenotype_info do
              if self.respond_to?(:phenotype_info)
                phenotype_info
              end
            end
            text :provider_name do
              if self.respond_to?(:provider_name)
                provider_name
              end
            end
            text :provider_id do
              if self.respond_to?(:provider_id)
                provider_id
              end
            end
            text :lab_internal_number do
              if self.respond_to?(:lab_internal_number)
                lab_internal_number
              end
            end
            text :institution do
              if self.respond_to?(:institution)
                institution.try :title
              end
            end
          end if Seek::Config.solr_enabled
        end
      end
    end
  end
end
