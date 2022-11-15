module Seek
  module WorkflowExtractors
    class Nextflow < Base
      def self.file_extensions
        ['nf']
      end

      def metadata
        metadata = super

        mani = manifest
        metadata[:title] = mani['name'] if mani.has_key?('name')
        metadata[:description] = mani['description'] if mani.has_key?('description')
        if mani['author'].present?
          mani['author'].split(',').each_with_index do |author_name, i|
            author = extract_author(author_name)
            unless author.blank?
              metadata[:assets_creators_attributes] ||= {}
              metadata[:assets_creators_attributes][i.to_s] = author.merge(pos: i)
            end
          end
        end

        #metadata[:url] = manifest['homePage'] if manifest.has_key?('homePage')

        metadata
      end

      def manifest
        config_string = @io.read

        manifest = manifest_block(config_string)
        manifest.merge(manifest_values(config_string))
      end

      def manifest_block(config)
        hash = {}
        lines = config.split("\n")
        open_line = lines.index { |a| a.match?(/\s*manifest\s*\{/) }
        return {} unless open_line
        line_index = open_line
        line = lines[line_index]
        until line.match?(/\s*\}\s*/) do
          matches = line.match(/\s*(.+)\s*=\s*(.+)\s*/)
          if matches
            hash[matches[1].strip] = matches[2].strip.gsub(/\A['"]+|['"]+\Z/, '')
          end
          line = lines[line_index += 1]
        end

        hash
      end

      def manifest_values(config)
        hash = {}
        config.split("\n").each do |line|
          matches = line.match(/\s*manifest\.(.+)\s*=\s*(.+)\s*/)
          next unless matches
          hash[matches[1].strip] = matches[2].strip.gsub(/\A['"]+|['"]+\Z/, '')
        end

        hash
      end
    end
  end
end
