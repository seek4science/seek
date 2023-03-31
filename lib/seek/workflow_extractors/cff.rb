require 'cff'

module Seek
  module WorkflowExtractors
    class CFF
      FILENAME = 'CITATION.cff'

      def initialize(io)
        @io = io.is_a?(String) ? StringIO.new(io) : io
      end

      def metadata
        metadata = {}
        f = Tempfile.new('cff')
        f.binmode
        f.write(@io.read)
        f.rewind
        cff = ::CFF::File.read(f.path)

        cff.authors.each_with_index do |author, i|
          metadata[:assets_creators_attributes] ||= {}
          metadata[:assets_creators_attributes][i.to_s] = {
              family_name: author.family_names,
              given_name: author.given_names,
              affiliation: author.affiliation,
              orcid: author.orcid,
              pos: i
          }
        end

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
