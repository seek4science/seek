module Seek
  module WorkflowExtractors
    class KNIME < Base
      def self.ro_crate_metadata
        {
            "@id" => "#knime",
            "@type" => "ComputerLanguage",
            "name" => "KNIME",
            "identifier" => { "@id" => "https://www.knime.com/" },
            "url" => { "@id" => "https://www.knime.com/" }
        }
      end

      def metadata
        metadata = super
        knime_string = @io.read
        knime = LibXML::XML::Parser.string(knime_string).parse
        knime.root.namespaces.default_prefix = 'k'

        title = knime.find('/k:config/k:entry[not(@isnull="true")][@key="name"]/@value').first.value
        if !title.nil?
          metadata[:title] = title.to_s
        else
          metadata[:title] = "missing_title"
          metadata[:warnings] = 'Unable to determine title of workflow'
        end
        description = knime.find('/k:config/k:entry[not(@isnull="true")][@key="customDescription"]/@value').first.value
        if !description.nil?
          metadata[:description] = description
        end

        metadata
      end
    end
  end
end
