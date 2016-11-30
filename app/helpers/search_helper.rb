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

  def search_extractable_items items, search_query

    sheet_array = []
    items = items.select { |item| item.is_asset? && item.can_download? && item.respond_to?(:content_blob) && item.content_blob.is_extractable_spreadsheet? }
    results = items.select do |object|
      workbook = Rails.cache.fetch(object.content_blob.cache_key) do
        object.spreadsheet
      end
      xml = object.spreadsheet_xml
      doc = LibXML::XML::Parser.string(xml).parse
      doc.root.namespaces.default_prefix="ss"

      #@origin_query = "Final Concentration,  LmPTR1 <=  30"
      # @origin_query  ="Final Concentration, LmPTR1 [µM]"
      search_query = search_query ? search_query.gsub(/\s+/, " ").strip : ""
      operators = ["<", "<=", ">", ">=", "="]
      search_operator = operators.select { |o| search_query.index(o) }.max_by(&:length)
      if search_operator
        search_arr = search_query.split(search_operator)
        search_field_name = search_arr.first
        search_value = search_arr.last
        search_operator = "=" if search_field_name == search_value

        head_cells = doc.find("//ss:sheet[@hidden='false' and @very_hidden='false']/ss:rows/ss:row/ss:cell").find_all { |cell| cell.content.gsub(/\s+/, " ").strip.match(/#{search_field_name}/i) }
        unless head_cells.blank?
          head_cell = head_cells[0]
          #head_sheet = head_cell.parent.parent.parent
          head_col = head_cell.attributes["column"]
          cells = doc.find("//ss:sheet[@hidden='false' and @very_hidden='false']/ss:rows/ss:row/ss:cell[@column=#{head_col}][text() #{search_operator} #{search_value}]").find_all

        end
      else
        standardized_underscore_search_query = search_query.underscore #Seek::Data::DataMatch.standardize_compound_name(search_query).underscore
        #cells = doc.find("//ss:sheet[@hidden='false' and @very_hidden='false']/ss:rows/ss:row/ss:cell").find_all { |cell| Seek::Data::DataMatch.standardize_compound_name(cell.content).underscore == standardized_underscore_search_query }
        cells = doc.find("//ss:sheet[@hidden='false' and @very_hidden='false']/ss:rows/ss:row/ss:cell").find_all { |cell| cell.content.underscore == standardized_underscore_search_query }
      end
      unless cells.blank?
        cell_groups = cells.group_by { |c| c.parent.try(:parent).try(:parent).try(:attributes).to_h["name"] }
        sheet_array |= cell_groups.map do |sheet_name, match_cells|
          sheet = workbook.sheets.detect { |sh| sheet_name.downcase == sh.name.downcase }
          rows_nums = match_cells.map { |c| c.attributes["row"].to_i }
          col_nums = match_cells.map { |c| c.attributes["column"].to_i }
          [sheet, rows_nums, col_nums, object.id]
        end
      end
      !sheet_array.empty?
    end
    return results, sheet_array
  end
end
