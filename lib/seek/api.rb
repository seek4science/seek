# BioCatalogue: lib/bio_catalogue/api.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the REST XML/JSON/etc API

# Taken from our friends Biocatalogue http://www.biocatalogue.org

module Seek
  module Api        
    
    def self.uri_for_path(path, *args)
      options = args.extract_options!
      # defaults:
      options.reverse_merge!(:params => nil)        
      
      uri = ""
      
      unless path.blank?
        uri = URI.join(Seek::Config.site_base_host, path).to_s
        uri = append_params(uri, options[:params]) unless options[:params].blank?
      end
      
      return uri
    end
    
    def self.api_partial_path_for_item object      
      item_name=object.class.name.underscore
      "#{item_name.pluralize}/api/#{item_name}"      
    end
    
    def self.uri_for_collection(resource_name, *args)
      options = args.extract_options!
      # defaults:
      options.reverse_merge!(:params => nil)        
      
      uri = ""
      
      unless resource_name.blank?
        uri = URI.join(Seek::Config.site_base_host, resource_name).to_s
        uri = append_params(uri, options[:params]) unless options[:params].blank?
      end
      
      return uri
    end
    
    
    def self.uri_for_object(resource_obj, *args)
      options = args.extract_options!
      # defaults:
      options.reverse_merge!(:params => nil,
                             :sub_path => nil)
                             
      uri = ""
      
      unless resource_obj.nil?
        resource_part = "#{resource_obj.class.name.pluralize.underscore}/#{resource_obj.id}"
        unless options[:sub_path].blank?
          sub_path = options[:sub_path]
          sub_path = "/#{sub_path}" unless sub_path.starts_with?('/')
          resource_part += sub_path
        end
        uri = URI.join(Seek::Config.site_base_host, resource_part).to_s
        uri = append_params(uri, options[:params]) unless options[:params].blank?
      end
      
      return uri
    end
    
    # Attempts to figure out what internal object the URI is referring to.
    # Returns nil if the URI is an invalid resource URI, or if the object doesn't exist anymore.
    def self.object_for_uri(uri)
      return nil if uri.blank?
      return nil unless uri.downcase.include?(Seek::Config.site_base_host.downcase)
      
      obj = nil
      
      begin
        pieces = uri.downcase.gsub(Seek::Config.site_base_host.downcase, '').split('/').delete_if { |s| s.blank? }
        obj = pieces[0].singularize.camelize.constantize.find(pieces[1])
      rescue Exception => ex
        BioCatalogue::Util.log_exception(ex, :warning, "BioCatalogue::Api.object_for_uri failed to find an object for the uri '#{uri}'")
      end
      
      return obj
    end
    
    protected
      
    def self.append_params(uri, params)
      # Remove the special params
      new_params = Seek::Util.remove_rails_special_params_from(params)
      return (new_params.blank? ? uri : "#{uri}?#{new_params.to_query}")
    end
      
  end
end