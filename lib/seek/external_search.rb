module Seek
  class ExternalSearch
    include Singleton

    def initialize
      clear_cached # Cache for instantiated adaptors by type
    end

    def clear_cached
      @adaptors = {}
    end

    def supported?(type = 'all')
      search_adaptors(type).any?
    end

    # returns an array of instantiated search adaptors that match the appropriate search type, or for any search type if 'all' or nothing is specified.
    def search_adaptors(type = 'all', include_disabled: false)
      @adaptors[type] ||= search_adaptor_files(type).collect do |file|
        file['adaptor_class_name'].constantize.new(file)
      end
      if include_disabled
        @adaptors[type]
      else
        @adaptors[type].select(&:enabled?)
      end
    end

    def search_adaptor_names(type = 'all', include_disabled: false)
      search_adaptors(type, include_disabled: include_disabled).collect(&:name)
    end

    def external_item(item_id, type = 'all')
      search_adaptors(type).collect do |adaptor|
        adaptor.get_item item_id
      rescue Exception => e
        Rails.logger.error("Error getting external item #{item_id} with #{adaptor} - #{e.class.name}:#{e.message}")
        raise e if Rails.env.development?
      end.flatten.uniq
    end

    def external_search(query, type = 'all')
      search_adaptors(type).collect do |adaptor|
        adaptor.search query
      rescue Exception => e
        Rails.logger.error("Error performing external search with #{adaptor} - #{e.class.name}:#{e.message}")
        raise e unless Rails.env.production?
      end.flatten.uniq
    end

    private

    def search_adaptor_files(type)
      file_names = Dir.glob('config/external_search_adaptors/*.yml')
      files = file_names.collect { |filename| YAML.load_file(filename) }

      files.select! { |f| f['search_type'] == type } unless type == 'all'
      files
    end

  end

  module ExternalSearchResult
    attr_accessor :tab, :partial_path, :id

    def can_view?
      true
    end

    def is_external_search_result?
      true
    end
  end
end
