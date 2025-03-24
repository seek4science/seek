module Seek
  module BioSchema
    class DataDump
      include Seek::BioSchema::Support

      attr_reader :name

      def initialize(model, name: nil, records: nil)
        @name = name || model.model_name.plural
        @records = records || model.authorized_for('view', nil)
      end

      def file
        File.open(file_path, 'r')
      end

      def write
        FileUtils.mkdir_p(file_path_base)
        File.atomic_write(file_path) do |f|
          f.write("[\n")
          first = true
          # Write each record at a time to avoid loading entire set into memory
          bioschemas do |record|
            f.write(",\n") unless first
            JSON.pretty_generate(record).each_line do |line|
              f.write('  ', line) # Indent 2 spaces
            end
            first = false
          end
          f.write("\n]")
        end
      end

      def bioschemas
        if block_given?
          @records.each do |record|
            yield Seek::BioSchema::Serializer.new(record).json_representation
          end
        else
          @records.each.map { |record| Seek::BioSchema::Serializer.new(record).json_representation }
        end
      end

      def file_name
        "#{@name}-bioschemas-dump.jsonld"
      end

      def exists?
        File.exist?(file_path)
      end

      def size
        File.size(file_path) if exists?
      end

      def date_modified
        File.mtime(file_path) if exists?
      end

      def self.generate_dumps
        Seek::Util.searchable_types.select(&:schema_org_supported?).map do |model|
          generate_dump(model)
        end
      end

      def self.generate_dump(model)
        dump = new(model)
        dump.write
        dump
      end

      private

      def file_path
        File.join(file_path_base, file_name)
      end

      def file_path_base
        "#{Seek::Config.temporary_filestore_path}/"
      end
    end
  end
end
