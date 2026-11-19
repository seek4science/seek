module Seek
  module Templates
    # Excel imposes limits that caxlsx does not enforce. When a generated workbook breaks one of them, Excel reports
    # the file as damaged and silently drops content while "repairing" it (e.g. all data validations of a sheet).
    #
    # This class keeps the single page spreadsheet export within those limits:
    # - it builds the data validation prompts (tooltips) and prompt titles so they fit and are valid XML
    # - it reports, as user facing warnings, everything that had to be shortened or that Excel cannot hold
    class SpreadsheetExportCheck
      include SinglePagesHelper

      PROMPT_MAX_LENGTH = 255
      PROMPT_TITLE_MAX_LENGTH = 32
      CELL_MAX_LENGTH = 32_767
      # Don't bother including a description in the prompt when less than this is left for it
      MIN_DESCRIPTION_LENGTH = 10
      LINE_BREAK = "\n".freeze

      # caxlsx writes data validation attributes into the XML without escaping them,
      # so '&', '<' or '"' in a description would produce an invalid (damaged) file.
      def self.xml_attribute(text)
        CGI.escapeHTML(text.to_s).gsub(LINE_BREAK, '&#10;')
      end

      def initialize(sample_type, samples = [])
        @sample_type = sample_type
        @samples = samples
      end

      def sample_attributes
        @sample_attributes ||= @sample_type.sample_attributes.to_a
      end

      # Plain text of the input prompt shown when a cell of the attribute's column is selected.
      # The guidance is always kept; the description is shortened to fit.
      def prompt(attribute)
        guidance = guidance_text(attribute)
        description = clean_text(attribute.description)
        room = description_room(guidance)
        return guidance.truncate(PROMPT_MAX_LENGTH) if description.blank? || room < MIN_DESCRIPTION_LENGTH

        "#{description.truncate(room)}#{LINE_BREAK}#{guidance}"
      end

      def prompt_title(attribute)
        clean_text(attribute.title).truncate(PROMPT_TITLE_MAX_LENGTH)
      end

      def warnings
        sample_attributes.flat_map { |attribute| attribute_warnings(attribute) } + cell_warnings
      end

      private

      def attribute_warnings(attribute)
        warnings = []
        if clean_text(attribute.title).length > PROMPT_TITLE_MAX_LENGTH
          warnings << "The name of attribute '#{attribute.title}' is longer than #{PROMPT_TITLE_MAX_LENGTH} " \
                      'characters and was shortened in its Excel tooltip.'
        end
        if description_shortened?(attribute)
          warnings << "The description of attribute '#{attribute.title}' is too long for an Excel tooltip " \
                      "(max. #{PROMPT_MAX_LENGTH} characters) and was shortened."
        end
        warnings
      end

      def cell_warnings
        @samples.flat_map do |sample|
          sample_attributes.filter_map do |attribute|
            value = format_attribute_value_for_spreadsheet(sample.get_attribute_value(attribute), attribute)
            next if value.to_s.length <= CELL_MAX_LENGTH

            "The value of attribute '#{attribute.title}' for sample '#{sample.title}' (ID #{sample.id}) is longer " \
              "than the #{CELL_MAX_LENGTH} characters an Excel cell can hold. Excel may cut it off, so check it " \
              'before uploading the spreadsheet again.'
          end
        end
      end

      def description_shortened?(attribute)
        description = clean_text(attribute.description)
        return false if description.blank?

        room = description_room(guidance_text(attribute))
        room < MIN_DESCRIPTION_LENGTH || description.length > room
      end

      def description_room(guidance)
        PROMPT_MAX_LENGTH - guidance.length - LINE_BREAK.length
      end

      def guidance_text(attribute)
        lines = []
        type = attribute.sample_attribute_type
        free_text = attribute.allow_cv_free_text
        if type.seek_cv_list? || type.seek_sample_multi?
          lines << "Any valid combination of the terms on sheet 'Controlled Vocabularies'" \
                   "#{', as well as free text,' if free_text} are accepted."
        end
        if requires_data_validation?(attribute)
          lines << "Choose a valid option from the 'Controlled Vocabularies' sheet#{' or add free text' if free_text}."
        end
        lines << (attribute.required ? 'This field is REQUIRED!' : 'This field is optional.')
        lines.join(LINE_BREAK)
      end

      # Normalizes line breaks and removes control characters that are not allowed in XML
      def clean_text(text)
        text.to_s.gsub(/\r\n?/, LINE_BREAK).delete(Axlsx::CONTROL_CHARS).strip
      end
    end
  end
end
