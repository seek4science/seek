# encoding: utf-8

module AssayTypesHelper
  def is_modelling_type?(type_class)
    type_class.try(:term_type) == Seek::Ontologies::ModellingAnalysisTypeReader::TERM_TYPE
  end

  def parent_types_list_links(parents, type)
    if parents.empty?
      content_tag :span, 'No parent terms', class: 'none_text'
    else
      parents.collect do |par|
        link_to_ontology_term par, par.label, type, class: 'parent_term'
      end.join(' | ').html_safe
    end
  end

  # describes the number of visible and hidden assays listed for a given assay or technology type.
  # - this is similar to the count diplayed for index views
  def assay_visibility_count_for_type(shown_assays, type)
    content_tag :span, class: 'resource-count-stats' do
      html = content_tag(:strong, shown_assays.count)
      html << " #{t('assay').pluralize} visible to you, out of a total of "
      html << content_tag(:strong, type.assays.count)
      html
    end
  end
end
