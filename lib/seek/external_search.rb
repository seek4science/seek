
module Seek
  module ExternalSearch

    #returns an array of instantiated search adaptors that match the appropriate search type, or for any search type if 'all' or nothing is specified.
    def search_adaptors type="all"
      file_names = Dir.glob("config/external_search_adaptors/*.yml")
      files = file_names.collect{|filename| YAML::load_file(filename)}
      unless type=="all"
        files = files.select{|file| file["search_type"]==type}
      end
      files.collect{|file| file["adaptor_class_name"].constantize.new(file)}
    end

    def external_search query,type='all'
      search_adaptors(type).collect do |adaptor|
        adaptor.search query
      end.flatten
    end

  end

  module ExternalSearchResult
    def can_view?
      true
    end

    def is_external_search_result?
      true
    end
  end

end