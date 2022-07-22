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
    div_class = "col-sm-#{resource.default_table_columns.length < 3 ? '4' : '3'}"
    resource.default_table_columns.first(3).collect do |column|
      content_tag :div, class: div_class do
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
      table_item_person_list column_value
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

  def table_item_person_list(contributors, other_contributors = nil, key = t('creator').capitalize)
    contributor_count = contributors.count
    contributor_count += 1 unless other_contributors.blank?
    html = ''
    other_html = ''
    html << if key == 'Author'
              contributors.map do |author|
                if author.person
                  link_to author.full_name, show_resource_path(author.person)
                else
                  author.full_name
                end
              end.join(', ')
            else
              contributors.map do |c|
                link_to truncate(c.title, length: 75), show_resource_path(c), title: get_object_title(c)
              end.join(', ')
            end
    unless other_contributors.blank?
      other_html << ', ' unless contributors.empty?
      other_html << other_contributors
    end
    other_html << 'None' if contributor_count.zero?
    html.html_safe + other_html
  end
end
