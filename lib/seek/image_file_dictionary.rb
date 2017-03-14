module Seek
  # a means to lookup the configured icon image filename for a given key
  class ImageFileDictionary
    include Singleton

    def initialize
      @dictionary = dictionary_definition
    end

    def image_filename_for_key(key)
      @dictionary[key.to_s]
    end

    def image_files
      @dictionary.values
    end

    private

    def dictionary_definition
      dictionary_filepath = File.join(Rails.root, 'config/image_files', 'image_file_dictionary.yml')
      YAML.load(File.read(dictionary_filepath))
    end
  end
end
