module Seek
  module Zip
    def self.unzip(file, destination, &block)
      directory = Pathname(destination)
      ::Zip::File.open(file) do |zipfile|
        zipfile.each do |entry|
          next if entry.name_is_directory?
          dest = directory.join(entry.name)
          # Guard against zip-slip attacks.
          begin
            unsafe = dest.expand_path.relative_path_from(directory.expand_path).each_filename.first == '..'
          rescue ArgumentError # Handle unjoinable paths, e.g. on different drives.
            unsafe = true
          end
          raise "Unsafe path in zip entry: #{entry.name}" if unsafe

          unless ::File.exist?(dest)
            FileUtils::mkdir_p(::File.dirname(dest))
            entry.extract(entry.name, destination_directory: directory)
          end

          yield entry if block_given?
        end
      end
    end
  end
end