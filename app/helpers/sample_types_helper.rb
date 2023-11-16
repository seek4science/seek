module SampleTypesHelper
  def list_item_sample_attribute_details(sample_type_attribute)
    type = attribute_type_link(sample_type_attribute)

    unit = sample_type_attribute.unit ? "( #{sample_type_attribute.unit.symbol} )" : ''
    req = sample_type_attribute.required? ? required_span : ''
    attribute_css = 'sample-attribute'
    attribute_css << ' sample-attribute-title' if sample_type_attribute.is_title?

    content_tag :span, class: attribute_css do
      "#{h sample_type_attribute.title} (#{type}) #{unit} #{req}".html_safe
    end
  end

  def sample_attribute_details_table(attributes)
    head = content_tag :thead do
      content_tag :tr do
        "<th>Name</th><th>Type</th><th>Description</th><th>PID #{sample_attribute_pid_help_icon}</th><th>Unit</th>".html_safe
      end
    end

    body = content_tag :tbody do
      attributes.collect do |attr|
        req = attr.required? ? required_span.html_safe : ''
        unit = attr.unit ? attr.unit.symbol : "<span class='none_text'>-</span>".html_safe
        description = attr.description.present? ? attr.description : "<span class='none_text'>Not specified</span>".html_safe
        pid = attr.pid.present? ? attr.pid : "<span class='none_text'>-</span>".html_safe

        type = attribute_type_link(attr)

        content_tag :tr do
          concat content_tag :td, (h(attr.title) + req).html_safe
          concat content_tag :td, type.html_safe
          concat content_tag :td, description
          concat content_tag :td, pid
          concat content_tag :td, unit
        end
      end.join.html_safe
    end

    content_tag :table, head.concat(body), class: 'table table-responsive table-hover'
  end

  def create_sample_controlled_vocab_modal_button
    modal_id = 'cv-modal'
    button_link_to('New', 'add', '#', 'data-toggle':'modal', 'data-target': "##{modal_id}")
  end  

  def sample_controlled_vocab_model_dialog(modal_id)
    modal_options = { id: modal_id, size: 'xl', 'data-role' => 'create-sample-controlled-vocab-form' }

    modal_title = 'Create Sample Controlled Vocab'

    modal(modal_options) do
      modal_header(modal_title) +
        modal_body do
          @sample_controlled_vocab = SampleControlledVocab.new
          render partial: 'sample_controlled_vocabs/form', locals: { remote: true }
        end
    end
  end

  def sample_type_grouped_options
    sample_types = Seek::Config.isa_json_compliance_enabled && !displaying_single_page? ? SampleType.without_template : SampleType.all
    projects = current_user.person.projects
    person_sample_types = sample_types.select { |type| (type.projects & projects).any? }
    other_sample_types = sample_types - person_sample_types
    grouped_options = [["Sample types from your #{t('project').pluralize}", person_sample_types.collect { |type| [type.title, type.id] }]]
    grouped_options << ["Sample types from other #{t('project').pluralize}", other_sample_types.collect { |type| [type.title, type.id] }]
  end

  def sample_type_tags_list(sample_type)
    list_item_tags_list(sample_type.sample_type_tag_annotations.collect(&:value), type: 'sample_type_tag')
  end

  def all_sample_type_tags
    tags = Annotation.with_attribute_name('sample_type_tag').collect(&:value)
    tags.uniq.sort_by(&:tag_count).reverse
  end

  def ebi_ontology_choices
    opts = Ebi::OlsClient.ontologies.map { |ontology| [ontology.dig('config', 'title'), ontology.dig('config', 'namespace')] }

    opts.sort_by { |o| o[0] || '' }
  end

  def sample_attribute_pid_help_icon
    help_icon(t('samples.pid_info_text'))
  end

  def allow_free_text_help_icon
    help_icon(t('samples.allow_free_text_info_text'))
  end

  private

  def displayed_sample_attribute_types
    SampleAttributeType.all.reject{ |x|x.linked_extended_metadata? || x.linked_extended_metadata_multi? }
  end

  def attribute_type_link(sample_type_attribute)
    type = sample_type_attribute.sample_attribute_type.title
    if sample_type_attribute.seek_sample?
      type += ' - ' + link_to(sample_type_attribute.linked_sample_type.title, sample_type_attribute.linked_sample_type)
    end

    if sample_type_attribute.controlled_vocab? || sample_type_attribute.seek_cv_list?
      type += ' - ' + link_to(sample_type_attribute.sample_controlled_vocab.title, sample_type_attribute.sample_controlled_vocab)
      type += " (#{t('samples.allow_free_text_label_hint')})" if sample_type_attribute.allow_cv_free_text?
    end
    type
  end
end
