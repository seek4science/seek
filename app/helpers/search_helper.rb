require 'seek/external_search'

module SearchHelper
  include Seek::ExternalSearch
  def search_type_options
    search_type_options = [["All", '']] | Seek::Util.searchable_types.collect{|c| [(c.name.underscore.humanize == "Sop" ? t('sop') : c.name.underscore.humanize.pluralize),c.name.underscore.pluralize] }
    return search_type_options
  end

  def external_search_tooltip_text
    text = "Checking this box allows external resources to be includes in the search. "
    text << "External resources include:  "
    text << search_adaptor_names.collect{|name| "#{name}"}.join(", ")
    text << ". "
    text << "This means the search will take longer, but will include results from other sites"
    text.html_safe
  end

  def get_resource_hash scale, external_resource_hash
    internal_resource_hash = {}
    if external_resource_hash.blank?
      @results_scaled[scale].each do |item|
        tab = item.respond_to?(:tab) ? item.tab : item.class.name
        if item.respond_to?(:is_external_search_result?) && item.is_external_search_result?
          external_resource_hash[tab] = [] unless external_resource_hash[tab]
          external_resource_hash[tab] << item
        else
          internal_resource_hash[tab] = [] unless internal_resource_hash[tab]
          internal_resource_hash[tab] << item
        end
      end
    else
      @results_scaled[scale].each do |item|
        tab = item.respond_to?(:tab) ? item.tab : item.class.name
        unless item.respond_to?(:is_external_search_result?) && item.is_external_search_result?
          internal_resource_hash[tab] = [] unless internal_resource_hash[tab]
          internal_resource_hash[tab] << item
        end
      end
    end
    [internal_resource_hash, external_resource_hash]
  end

  #can only be supported if turned on and crossref api email is configured
  def external_search_supported?
    Seek::Config.external_search_enabled && !Seek::Config.crossref_api_email.blank?
  end

end
