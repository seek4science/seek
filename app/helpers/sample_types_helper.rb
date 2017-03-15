module SampleTypesHelper
  def sample_attribute_details(sample_type_attribute)
    type = sample_type_attribute.sample_attribute_type.title
    if sample_type_attribute.seek_sample?
      type += ' - ' + link_to(sample_type_attribute.linked_sample_type.title, sample_type_attribute.linked_sample_type)
    end
    unit = sample_type_attribute.unit ? "( #{sample_type_attribute. unit.symbol} )" : ''
    req = sample_type_attribute.required? ? required_span : ''
    attribute_css = 'sample-attribute'
    attribute_css << ' sample-attribute-title' if sample_type_attribute.is_title?
    content_tag :span, class: attribute_css do
      "#{h sample_type_attribute.title} (#{type}) #{unit} #{req}".html_safe
    end
  end

  def create_sample_controlled_vocab_model_button
    modal_id = 'cv-modal'
    button_link_to('New', 'add', '#', 'data-toggle' => 'modal', 'data-target' => "##{modal_id}")
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
    sample_types = SampleType.all
    projects = current_user.person.projects
    person_sample_types = sample_types.select { |type| (type.projects & projects).any? }
    other_sample_types = sample_types - person_sample_types
    grouped_options = [["Sample types from your #{t('project').pluralize}", person_sample_types.collect { |type| [type.title, type.id] }]]
    grouped_options << ["Sample types form other #{t('project').pluralize}", other_sample_types.collect { |type| [type.title, type.id] }]
  end

  def sample_type_tags_list(sample_type)
    list_item_tags_list(sample_type.annotations_with_attribute('sample_type_tags').collect(&:value), type: 'sample_type_tags')
  end

  def all_sample_type_tags
    tags = Annotation.with_attribute_name('sample_type_tags').collect(&:value)
    tags.uniq.sort_by(&:tag_count).reverse
  end
end
