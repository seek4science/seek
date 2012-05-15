module FancyMultiselectHelper
  #the point of this module is to decompose the 'fancy_multiselect' method which was becoming too large and complex.
  #This breaks it into submodules by feature.
  module Base
    def fancy_multiselect object, association, options = {}
      render :partial => 'assets/fancy_multiselect', :locals => options
    end
  end

  module AjaxPreview
    def fancy_multiselect object, association, options = {}
      #skip if preview is disabled
      return super if options.delete :preview_disabled

      #skip if controller class does not define a preview method
      return super unless try_block{"#{association.to_s.classify.pluralize}Controller".constantize.method_defined?(:preview)}

      #adds options to the dropdown used to select items to add to the multiselect.
      options[:possibilities_options] = {} unless options[:possibilities_options]
      onchange = options[:possibilities_options][:onchange] || ''
      onchange += remote_function(
          :url=>{:action=>"preview", :controller=>"#{association}", :element=>"#{association}_preview"},
          :with=>"'id='+this.value",
          :before=>"show_ajax_loader('#{association}_preview')") + ';'

      options[:possibilities_options][:onchange] = onchange
      options = options.reverse_merge :html_options => "style='float:left; width:66%' "

      #after rendering the multiselect, throw in a preview box.
      super(object, association, options) + "\n" + render(:partial => 'assets/preview_box', :locals => {:preview_name => association.to_s.underscore})
    end
  end

  module HideButtonWhenDefaultIsSelected
    def fancy_multiselect object, association, options = {}
      options[:possibilities_options] = {} unless options[:possibilities_options]
      onchange = options[:possibilities_options][:onchange] || ''
      collection_id = options[:name].to_s.gsub(']','').gsub(/[^-a-zA-Z0-9:.]/, "_")
      possibilities_id = "possible_#{collection_id}"
      button_id = "add_to_#{collection_id}_link"
      hide_add_link_when_default_is_selected_js = "($F('#{possibilities_id}') == 0) ? $('#{button_id}').hide() : $('#{button_id}').show();"
      onchange += hide_add_link_when_default_is_selected_js
      options[:possibilities_options][:onchange] = onchange
      super(object, association, options) + "\n<script type='text/javascript'>#{hide_add_link_when_default_is_selected_js}</script>\n"
    end
  end

  module OtherProjectsCheckbox
    def fancy_multiselect object, association, options = {}
      if options[:project_possibilities]
        type = object.class.name.underscore
        check_box_and_alternative_list = <<-HTML
          <br/>
          #{check_box_tag "include_other_project_#{association}", nil, false, {:onchange => "swapSelectListContents('possible_#{type}_#{association.to_s.singularize}_ids','alternative_#{association.to_s.singularize}_ids');", :style => "margin-top:0.5em;"}} Associate #{association.to_s.humanize} from other projects?
          #{select_tag "alternative_#{association.to_s.singularize}_ids", options_for_select([["Select #{association.to_s.singularize.humanize} ...", 0]]|options[:project_possibilities].collect { |o| [truncate(h(o.title), :length => 120), o.id] }), {:style => 'display:none;'}}
        HTML

        options[:association_step_content] = '' unless options[:association_step_content]
        options[:association_step_content] = options[:association_step_content] + check_box_and_alternative_list
        swap_project_possibilities_into_dropdown_js = <<-JS
          <script type="text/javascript">
              swapSelectListContents('possible_#{type}_#{association.to_s.singularize}_ids','alternative_#{association.to_s.singularize}_ids');
          </script>
        JS
        super + swap_project_possibilities_into_dropdown_js
      else
        super
      end
    end
  end

  module SetDefaults
    def fancy_multiselect object, association, options = {}
      options[:object_type_text] = options[:object_class].name.underscore.humanize unless options[:object_type_text]
      with_new_link = options[:with_new_link] || false
      object_type_text = options[:object_type_text]
      object_type_text = CELL_CULTURE_OR_SPECIMEN.capitalize if object_type_text == 'Specimen'

      #set default values for locals being sent to the partial
      #override default values with options passed in to the method
      options.reverse_merge! :intro => "The following #{association.to_s.capitalize} are associated with this #{object_type_text}:",
                             :button_text => "Associate with this #{object_type_text}",
                             :default_choice_text => "Select #{association.to_s.singularize.capitalize} ...",
                             :name => "#{options[:object_class].name.underscore}[#{association.to_s.singularize}_ids]",
                             :possibilities => [],
                             :value_method => :id,
                             :text_method => :title,
                             :with_new_link => with_new_link,
                             :object_type_text=> object_type_text,
                             :association=>association

      options[:selected] = object.send(association).map(&options[:value_method]) unless options[:selected]

      super object, association, options
    end
  end

  module SetDefaultsWithReflection
    def fancy_multiselect object, association, options = {}

      if reflection = options[:object_class].reflect_on_association(association)
        required_access = reflection.options[:required_access] || :can_view?
        association_class = options.delete(:association_class) || reflection.klass
        options[:project_possibilities] = authorised_assets(association_class, current_user.person.projects) if options[:other_projects_checkbox]
        options[:possibilities] = association_class.all.select(&required_access.to_sym) unless options[:possibilities]
      end

      super object, association, options
    end
  end

  module FoldingBox
    def fancy_multiselect object, association, options = {}
      hidden = options.delete(:hidden)
      object_type_text = options[:object_type_text] || options[:object_class].name.underscore.humanize
      object_type_text = CELL_CULTURE_OR_SPECIMEN.capitalize if object_type_text == 'Specimen'
      title = (help_icon("Here you can associate the #{object_type_text} with specific #{association}.") + " #{association.to_s.titleize}") + (options[:required] ? ' <span class="required">*</span>'.html_safe : '')

      folding_box "add_#{association}_form", title , :hidden => hidden, :contents => super(object, association, options)
    end
  end

  module AssociationContentFromBlock
    def fancy_multiselect object, association, options = {}
      if block_given?
        options[:association_step_content] = '' unless options[:association_step_content]
        options[:association_step_content] = options[:association_step_content] + capture {yield}
        concat super(object, association, options)
      else
        super(object, association, options)
      end
    end
  end


  module StringOrObject
    def fancy_multiselect string_or_object, association, options = {}
      string_or_object = string_or_object.constantize if string_or_object.is_a? String
      if string_or_object.is_a? Class
        options[:object_class] = string_or_object
        string_or_object = nil
      else
        options[:object_class] = string_or_object.class
      end
      super(string_or_object, association, options)
    end
  end

  #commenting some of these out should be ok. The only one relied on by others is SetDefaults (and Base, of course).
  #Changing the order may break things. These are executed starting with the last one, and ending with Base.
  include Base
  include AjaxPreview
  include HideButtonWhenDefaultIsSelected
  include OtherProjectsCheckbox
  include SetDefaults
  include SetDefaultsWithReflection
  include FoldingBox
  include AssociationContentFromBlock
  include StringOrObject
end