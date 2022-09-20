module Seek
  module WorkflowExtractors
    class Base
      NULL_CLASS_METADATA = {
          "@id" => "#workflow_type",
          "@type" => "ComputerLanguage",
          "name" => "Unrecognized Workflow Type"
      }

      def initialize(io)
        @io = io.is_a?(String) ? StringIO.new(io) : io
      end

      def metadata
        { }
      end

      def has_tests?
        false
      end

      def can_render_diagram?
        false
      end

      def generate_diagram
        nil
      end

      def diagram_extension
        'svg'
      end

      def self.workflow_class
        WorkflowClass.find_by_key(name.demodulize.underscore)
      end

      def self.file_extensions
        []
      end

      private

      # Extract author from a string or a Hash complying to schema.org's `Person`
      def extract_author(obj)
        author = {}
        if obj.is_a?(String)
          if obj.present?
            given_name, family_name = obj.split(' ', 2)
            author[:given_name] = given_name if given_name.present?
            author[:family_name] = family_name if family_name.present?
          end
        elsif obj.is_a?(Hash)
          name = obj['name'] || obj['@id'] || ''
          given_name, family_name = name.split(' ', 2)
          family_name = obj['familyName'] if obj['familyName'].present?
          given_name = obj['givenName'] if obj['givenName'].present?
          affiliation = obj['affiliation']
          if affiliation.present?
            if affiliation.is_a?(String)
              obj[:affiliation] = affiliation
            else
              obj[:affiliation] = affiliation['name'] if affiliation['name'].present?
            end
          end
          orcid = obj['identifier'] || obj['@id']
          author[:orcid] = orcid if orcid.present? && orcid.include?('orcid.org')
          author[:given_name] = given_name if given_name.present?
          author[:family_name] = family_name if family_name.present?
        end

        author
      end
    end
  end
end
