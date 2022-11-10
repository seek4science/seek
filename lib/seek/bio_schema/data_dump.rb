module Seek
  module BioSchema
    class DataDump
      include Seek::BioSchema::Support

      CONTENT_LICENSE = 'CC-BY-4.0'

      attr_reader :name

      def initialize(name, records)
        raise "Name too short!" if name.length < 3
        @name = name
        @records = records
      end

      def file
        unless File.exist?(file_path)
          clear_old_dumps
          f = File.open(file_path, 'w')
          f.write("[\n")
          first = true
          # Write each record at a time to avoid loading entire set into memory
          dump do |record|
            f.write(",\n") unless first
            JSON.pretty_generate(record).each_line do |line|
              f.write('  ', line) # Indent 2 spaces
            end
            first = false
          end
          f.write("\n]")
          f.close
        end

        File.open(file_path, 'r')
      end

      def dump
        if block_given?
          @records.find_each do |record|
            yield Seek::BioSchema::Serializer.new(record).json_representation
          end
        else
          @records.find_each.map { |record| Seek::BioSchema::Serializer.new(record).json_representation }
        end
      end

      def file_name(date = date_stamp)
        "#{@name}-bioschemas-dump-#{date}.json"
      end

      # Bioschemas compatibility
      def license
        Seek::License.find(CONTENT_LICENSE)&.url
      end

      def schema_org_supported?
        true
      end

      def is_a_version?
        false
      end

      private

      def date_stamp
        Time.now.iso8601.first(10)
      end

      def clear_old_dumps
        Dir.glob(file_path("*")).each do |file|
          next if file == file_path
          puts 'delete'
          File.delete(file)
        end
      end

      def file_path(date = date_stamp)
        "#{file_path_base}#{file_name(date)}"
      end

      def file_path_base
        "#{Seek::Config.temporary_filestore_path}/"
      end
    end
  end
end
