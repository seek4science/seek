module ResourceListHelper
  include ApplicationHelper
  include ResourceListItemHelper
  include LicenseHelper
  include OntologyHelper
  include CountriesHelper

  def resource_list_table_row(resource, tableview_columns)
    content_tag :tr, class: :list_item do
      tableview_columns.collect do |column|
        content_tag :td do
          resource_list_column_display_value(resource, column)
        end
      end.join.html_safe
    end
  end

  def resource_list_condensed_row(resource)
    resource.default_table_columns.first(3).collect do |column|
      content_tag :div, class: 'rli-condensed-attribute' do
        "<b>#{resource.class.human_attribute_name(column)}: </b>#{resource_list_column_display_value(resource,
                                                                                                     column)}".html_safe
      end
    end.join.html_safe
  end

  def resource_list_column_display_value(resource, column)
    raise 'Invalid column' unless resource.allowed_table_columns.include?(column)

    column_value = resource.send(column)
    case column
    when 'title'
      list_item_title resource
    when 'creators'
      list_item_person_list_inner resource.assets_creators, (resource.other_creators if resource.respond_to? 'other_creators')
    when 'assay_type_uri'
      link_to_assay_type(resource)
    when 'technology_type_uri'
      link_to_technology_type(resource)
    when 'license'
      describe_license(column_value)
    when 'country'
      country_text_or_not_specified(column_value)
    when 'doi'
      doi_link(resource.latest_citable_resource.doi) if resource.has_doi?
    else
      if column_value.try(:acts_like_time?)
        date_as_string(column_value, true)
      else
        Array(column_value).collect do |value|
          if value.is_a?(SampleControlledVocabTerm)
            controlled_vocab_annotation_items(value)
          elsif value.is_a?(ApplicationRecord)
            link_to value.title, value
          else
            text_or_not_specified(value, length: 300, auto_link: true, none_text: '')
          end
        end.join(', ').html_safe
      end
    end
  end

  def resource_list_advanced_search_link(list_items_details, search_query, parent_item = nil)
    return nil if list_items_details[:is_external]
    return nil unless safe_class_lookup(list_items_details[:type]).available_filters.any?
    return nil unless (search_query || parent_item)
    right_arrow_glyph = "<span class='glyphicon glyphicon-arrow-right' aria-hidden='true'></span>"
    if search_query
      more_results_link_text = "Advanced #{list_items_details[:visible_resource_type]} search with filtering #{right_arrow_glyph}".html_safe
    elsif parent_item
      more_results_link_text = "Advanced #{list_items_details[:visible_resource_type]} list for this #{internationalized_resource_name(parent_item.model_name.to_s, false)} with search and filtering #{right_arrow_glyph}".html_safe
    end

    content_tag(:span, id: 'advanced-search-link') do
      link_to(more_results_link_text, resource_list_more_results_path(list_items_details, search_query, parent_item), class: 'pull-right')
    end
  end

  def resource_list_items_shown_text(list_items_details, search_query, parent_item)
    return nil if list_items_details[:is_external] || list_items_details[:extra_count] <= 0

    content_tag(:span, id: 'resources-shown-count') do
      link = link_to(pluralize(resource_type_total_visible_count(list_items_details),list_items_details[:visible_resource_type]), resource_list_more_results_path(list_items_details, search_query, parent_item))
      "Showing #{list_items_details[:items_count]} out of a possible #{link}".html_safe
    end

  end

  def resource_list_all_results_link(list_items_details, search_query, parent_item)
    return nil if list_items_details[:is_external] || list_items_details[:extra_count] <= 0
    right_arrow_glyph = "<span class='glyphicon glyphicon-arrow-right' aria-hidden='true'></span>"
    content_tag(:div, id:'more-results', class:'text-center') do
      link_text = "View all #{pluralize(resource_type_total_visible_count(list_items_details),list_items_details[:visible_resource_type])} #{right_arrow_glyph}".html_safe
      link_to(link_text, resource_list_more_results_path(list_items_details, search_query, parent_item))
    end
  end

  # the path to the index view with filtering, based on whether there is a search query, or parent from a nested route
  def resource_list_more_results_path(list_items_details, search_query, parent_item)
    if search_query
      polymorphic_path(list_items_details[:type].tableize.to_sym, 'filter[query]': search_query)
    else
      [parent_item, list_items_details[:type].tableize.to_sym]
    end
  end

end
