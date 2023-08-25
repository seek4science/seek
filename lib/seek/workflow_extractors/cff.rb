require 'cff'

module Seek
  module WorkflowExtractors
    class CFF
      FILENAME = 'CITATION.cff'

      def initialize(io)
        if io.respond_to?(:path)
          @path = io.path
        else
          f = Tempfile.new('cff')
          f.binmode
          f.write(io.read)
          f.rewind
          @path = f.path
        end
      end

      def metadata
        metadata = {}
        cff = ::CFF::File.read(@path)

        other_creators = []
        cff.authors.each_with_index do |author, i|
          if author.is_a?(::CFF::Person)
            metadata[:assets_creators_attributes] ||= {}
            metadata[:assets_creators_attributes][i.to_s] = {
              family_name: author.family_names,
              given_name: author.given_names,
              affiliation: author.affiliation,
              orcid: author.orcid,
              pos: i
            }
          elsif author.is_a?(::CFF::Entity)
            other_creators << author.name
          end
        end
        metadata[:other_creators] = other_creators.join(', ')

        metadata[:title] = cff.title if cff.title.present?
        metadata[:license] = cff.license if cff.license.present?
        metadata[:tags] = cff.keywords.map(&:strip) if cff.keywords.present?
        metadata[:doi] = cff.doi if cff.doi.present?
        metadata[:source_link_url] = cff.url if cff.url.present?

        metadata
      end
    end
  end
end
