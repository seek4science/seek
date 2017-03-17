
module Seek
  module ExternalSearch
    # returns an array of instantiated search adaptors that match the appropriate search type, or for any search type if 'all' or nothing is specified.
    def search_adaptors(type = 'all')
      files = search_adaptor_files type

      adaptors = files.collect do |file|
        file['adaptor_class_name'].constantize.new(file)
      end
    end

    def search_adaptor_files(type = 'all')
      file_names = Dir.glob('config/external_search_adaptors/*.yml')
      files = file_names.collect { |filename| YAML.load_file(filename) }

      files = files.select { |f| f['search_type'] == type } unless type == 'all'
      files.select { |f| f['enabled'] == true }
    end

    def search_adaptor_names(type = 'all')
      search_adaptor_files(type).collect { |f| f['name'] }
    end

    def external_item(item_id, type = 'all')
      search_adaptors(type).collect do |adaptor|
        begin
          adaptor.get_item item_id
        rescue Exception => e
          Rails.logger.error("Error getting external item #{item_id} with #{adaptor} - #{e.class.name}:#{e.message}")
          []
          raise e if Rails.env.development?
        end
      end.flatten.uniq
    end

    def external_search(query, type = 'all')
      search_adaptors(type).collect do |adaptor|
        begin
          adaptor.search query
        rescue Exception => e
          Rails.logger.error("Error performing external search with #{adaptor} - #{e.class.name}:#{e.message}")
          []
          raise e if Rails.env.development?
        end
      end.flatten.uniq
    end

    # TODO: code to do each search adaptor in parallel - but currently removed due a random set of errors (that I can't now reproduce') - will revisit after holidy
    # def external_search query,type='all'
    #  threads = search_adaptors(type).collect do |adaptor|
    #    Thread.new do
    #      Thread.current[:result]=adaptor.search query
    #    end
    #  end
    #  threads.each{|thr| thr.join}
    #  threads.collect do |thread|
    #    thread[:result]
    #  end.flatten.uniq
    # end
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
