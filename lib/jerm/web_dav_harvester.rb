
require 'jerm/harvester'
require 'jerm/web_dav'

module Jerm
  class WebDavHarvester < Harvester

    include WebDav
  
    def initialize root_uri,username,password
      super root_uri,username,password

      configpath=File.join(File.dirname(__FILE__),"config/#{project_name.downcase}.yml")
      @config=YAML::load_file(configpath)
      @directories_and_types=@config['directories_and_types']      
    end

    def authenticate
      raise Exception.new("No username") if @username.nil?
      raise Exception.new("No password") if @password.nil?
    end

    def key_directories
      @directories_and_types.keys
    end

    def changed_since time
      #FIXME: need to actually get those changed since time
      items = []
      key_directories.each do |directory|
        uri = URI.join(@base_uri,directory)
        trees = get_contents(uri,@username,@password,true)

        #need to split tree into a list of the final directory leaves
        extensions = asset_extensions(directory)
        split_items = trees.collect{|tree| split_items(split_tree(tree),extensions)}.flatten
        type = asset_type(directory)
        split_items.each{|i| i[:type]=type}
        
        items += split_items
      end
      return items
    end

    private

    def split_tree tree
      items = []
      if !tree[:children].nil? && !tree[:children].empty? && tree[:children][0][:is_directory]
        tree[:children].each {|i| items = items + split_tree(i)}
      else
        items << tree unless tree[:children].nil? || tree[:children].empty?
      end
      return items
    end

    #required for where a directory contains multiple data items, with a single metadata
    def split_items items,extensions
      items.collect{|item| split_item(item,extensions)}
    end

    def split_item item,extensions
      metadata=item[:children].select{|c| c[:full_path].end_with?(meta_data_file)}.first
      if metadata.nil?
        puts "No metadata for: " + item[:full_path]
        return []
      end
      assets=item[:children].select{|c| !extensions.detect{|ext| c[:full_path].end_with?(ext)}.nil?}
      res = assets.collect{|a| {:metadata=>metadata,:asset=>a}}
      return res
    end
  
  end
end
