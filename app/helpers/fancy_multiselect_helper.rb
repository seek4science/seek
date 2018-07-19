module FancyMultiselectHelper
  def fancy_multiselect(object, association, options = {})
    # override default values with options passed in to the method
    options.reverse_merge! default_fancy_multi_select_options(association, object, options)

    options[:selected] ||= object.send(association).map(&options[:value_method])

    # - SetDefaultsWithReflection
    set_defaults_with_reflection(association, object, options)

    # Set onchange options for select
    options[:possibilities_options][:onchange] = select_onchange_options(association, options)

    render(partial: 'assets/fancy_multiselect', locals: options) # - Base
  end

  private

  def set_defaults_with_reflection(association, object, options)
    if reflection = object.class.reflect_on_association(association)
      required_access = reflection.options[:required_access] || :can_view?
      # get 'view' from :can_view?
      access = required_access.to_s.split('_').last.delete('?')
      association_class = options.delete(:association_class) || reflection.klass
      options[:unscoped_possibilities] = authorised_assets(association_class, nil, access) if options[:other_projects_checkbox]
      options[:possibilities] = authorised_assets(association_class, current_user.person.projects, access) unless options[:possibilities]
    end
  end

  def default_fancy_multi_select_options(association, object, options)
    # - SetDefaults
    # set default values for locals being sent to the partial

    hidden = object.send(association).blank?
    object_type_text = options[:object_type_text] || t(object.class.name.underscore)
    association_text = t(association.to_s.singularize)
    association_controller = "#{association.to_s.classify.pluralize}Controller".constantize rescue nil

    {
      intro: "The following #{association_text.pluralize} are associated with this #{object_type_text.downcase}:",
      default_choice_text: "Select #{association_text} ...",
      name: "#{object.class.name.underscore}[#{association.to_s.singularize}_ids]",
      possibilities: nil,
      unscoped_possibilities: [],
      group_options_by: nil,
      value_method: :id,
      text_method: :title,
      with_new_link: false,
      object_type_text: object_type_text,
      association_text: association_text,
      association: association,
      other_projects_checkbox: false,
      object_type: object.class.name,
      possibilities_options: {},
      hidden: hidden,
      required: false,
      title: nil,
      preview_disabled: association_controller.nil? || !association_controller.method_defined?(:preview)
    }
  end

  def select_onchange_options(association, options)
    # - HideButtonWhenDefaultIsSelected
    onchange = options[:possibilities_options][:onchange] || ''

    collection_id = options[:name].to_s.delete(']').gsub(/[^-a-zA-Z0-9:.]/, '_')
    onchange += "addSelectedToFancy('#{collection_id}', $F('possible_#{collection_id}'), this"
    onchange += (',' + options[:add_callback]) if options[:add_callback]
    onchange += ');'

    # - AjaxPreview
    unless options[:preview_disabled]
      # adds options to the dropdown used to select items to add to the multiselect.
      onchange += remote_function(
        method: :get,
        url: { action: 'preview', controller: "#{association}", element: "#{association}_preview" },
        with: "'id='+this.value",
        before: "show_ajax_loader('#{association}_preview')") + ';'
    end

    onchange.html_safe
  end
end
