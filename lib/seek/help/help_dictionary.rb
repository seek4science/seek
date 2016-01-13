module Seek
  module Help
    class HelpDictionary
      include Singleton

      def initialize
        @dictionary = dictionary_definition
      end

      def help_link(key)
        @dictionary[key.to_s]
      end

      def all_links
        @dictionary.values
      end

      private

      def dictionary_definition
        dictionary_filepath = File.join(File.dirname(File.expand_path(__FILE__)), 'help_links.yml')
        YAML.load(File.read(dictionary_filepath))
      end
    end
  end
end
