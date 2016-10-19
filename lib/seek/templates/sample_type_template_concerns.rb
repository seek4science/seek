module Seek
  module Templates
    # All Sample type methods and behaviour concerned with template handling - reading, extraction and generation

    module SampleTypeTemplateConcerns
      extend ActiveSupport::Concern
      included do
        after_save :queue_template_generation, :queue_sample_type_update_job
        validate :validate_template_file
        has_one :content_blob, as: :asset, dependent: :destroy
        alias_method :template, :content_blob
        extend ClassMethods
      end

      ### Methods related to template Generation

      def queue_template_generation
        unless uploaded_template?
          if content_blob
            content_blob.destroy
            update_attribute(:content_blob, nil)
          end
          SampleTemplateGeneratorJob.new(self).queue_job
        end
      end

      def queue_sample_type_update_job
        SampleTypeUpdateJob.new(self).queue_job
      end

      def generate_template
        Seek::Templates::SamplesWriter.new(self).generate
      end

      ### Methods related to template reading and extraction

      def build_attributes_from_template
        unless compatible_template_file?
          errors.add(:base, "Invalid spreadsheet - Couldn't find a 'samples' sheet")
          return
        end
        template_reader.build_sample_type_attributes(self)
      end

      def matches_content_blob?(blob)
        return false unless content_blob

        Rails.cache.fetch("st-match-#{blob.id}-#{content_blob.id}") do
          template_reader.matches?(blob)
        end
      end

      def build_samples_from_template(content_blob)
        template_reader.build_samples_from_datafile(self, content_blob)
      end

      def attribute_for_column(column)
        @columns_and_attributes ||= Hash[sample_attributes.collect { |attr| [attr.template_column_index, attr] }]
        @columns_and_attributes[column]
      end

      def compatible_template_file?
        template_reader.compatible?
      end

      # private

      def template_reader
        @template_handler ||= Seek::Templates::SamplesReader.new(content_blob)
      end

      def validate_template_file
        if template && !compatible_template_file?
          errors.add(:template, 'Not a valid template file')
        end
      end

      # required by Seek::ActsAsAsset::Searching - don't really need to full search terms, including content provided by Seek::ActsAsAsset::ContentBlobs
      # just the filename
      def content_blob_search_terms
        if content_blob
          [content_blob.original_filename]
        else
          []
        end
      end

      private :template_reader, :validate_template_file, :content_blob_search_terms

      module ClassMethods
        def sample_types_matching_content_blob(content_blob)
          SampleType.all.select do |type|
            type.matches_content_blob?(content_blob)
          end
        end
      end
    end
  end
end
