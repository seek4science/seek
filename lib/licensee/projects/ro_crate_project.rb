module Licensee
  module Projects
    # Project class for finding license files in an RO-Crate
    class RoCrateProject < ::Licensee::Projects::Project
      def initialize(ro_crate, **args)
        @ro_crate = ro_crate
        super(**args)
      end

      def files
        @files ||= @ro_crate.entries.each.map do |path, entry|
          next if entry.remote?
          next if entry.directory?
          split = path.split('/')
          name = split.last
          if split.length > 1
            dir = split[0..-2].join('/')
          else
            dir = ''
          end
          { name: name, dir: dir }
        end.compact
      end

      def load_file(file)
        path = file[:dir].blank? ? file[:name] : "#{file[:dir]}/#{file[:name]}"
        entry = @ro_crate.entries[path]
        entry.read
      end
    end
  end
end
