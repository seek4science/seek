module FancyMultiselectHelper
  def fancy_multiselect(object, association, options = {})
    # override default values with options passed in to the method
    options.reverse_merge! default_fancy_multi_select_options(association, object, options)

    options[:selected] ||= object.send(association)

    # - SetDefaultsWithReflection
    set_defaults_with_reflection(association, object, options)

    unless options[:preview_disabled]
      options[:possibilities_options]['data-preview-url'] =
          url_for({ action: 'preview', controller: association, element: "#{association}_preview" })
    end

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
      if options[:sort_by]
        attr = options[:sort_by]
        options[:possibilities] = options[:possibilities].sort_by(&attr)
        options[:unscoped_possibilities] = options[:unscoped_possibilities].sort_by(&attr)
      end
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
        name: "#{object.class.name.underscore}[#{association.to_s.singularize}_ids]",
        possibilities: nil,
        unscoped_possibilities: [],
        group_options_by: nil,
        value_method: :id,
        text_method: :title,
        object_type_text: object_type_text,
        association_text: association_text,
        association: association,
        other_projects_checkbox: false,
        object_type: object.class.name,
        possibilities_options: {},
        hidden: hidden,
        required: false,
        title: nil,
        preview_disabled: association_controller.nil? || !association_controller.method_defined?(:preview),
        sort_by: :title
    }
  end
end
