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
end
