module Seek
  module WorkflowExtractors
    class KNIME < Base
      def metadata
        metadata = super
        knime_string = @io.read
        knime = LibXML::XML::Parser.string(knime_string).parse
        knime.root.namespaces.default_prefix = 'k'

        title = knime.find('/k:config/k:entry[not(@isnull="true")][@key="name"]/@value').first&.value
        if title.present?
          metadata[:title] = title.to_s
        else
          metadata[:warnings] << 'Unable to determine title of workflow'
        end

        description = knime.find('/k:config/k:entry[not(@isnull="true")][@key="customDescription"]/@value').first&.value
        metadata[:description] = description if description.present?

        metadata
      end
    end
  end
end
