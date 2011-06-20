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
      return super unless "#{association.to_s.classify.pluralize}Controller".constantize.method_defined?(:preview)

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

  module SetDefaults
    def fancy_multiselect object, association, options = {}
      options[:object_type_text] = object.class.name.underscore.humanize unless options[:object_type_text]
      object_type_text = options[:object_type_text]

      #set default values for locals being sent to the partial
      #override default values with options passed in to the method
      options.reverse_merge! :intro => "The following #{association} are involved in this #{object_type_text}:",
                             :button_text => "Include in the #{object_type_text}",
                             :default_choice_text => "Select #{association} ...",
                             :name => "#{object.class.name.underscore}[#{association.to_s.singularize}_ids]",
                             :possibilities => [],
                             :value_method => :id,
                             :text_method => :title

      options[:selected] = object.send(association).map(&options[:value_method]) unless options[:selected]

      super object, association, options
    end
  end

  module SetDefaultsWithReflection
    def fancy_multiselect object, association, options = {}

      if reflection = object.class.reflect_on_association(association)
        required_access = reflection.options[:required_access] || :can_view?
        association_class = options.delete(:association_class) || reflection.klass
        options[:possibilities] = association_class.all.select(&required_access.to_sym) unless options[:possibilities]
      end

      super object, association, options
    end
  end

  module FoldingBox
    def fancy_multiselect object, association, options = {}
      hidden = options.delete(:hidden)
      object_type_text = options[:object_type_text] || object.class.name.underscore.humanize
      title = (help_icon("Here you can associate the #{object_type_text} with specific #{association}.") + "#{association.to_s.titleize}")

      folding_box "add_#{association}_form", title , :hidden => hidden, :contents => super(object, association, options)
    end
  end

  #commenting some of these out should be ok. The only one relied on by others is SetDefaults (and Base, of course).
  #Changing the order may break things. These are executed starting with the last one, and ending with Base.
  include Base
  include AjaxPreview
  include HideButtonWhenDefaultIsSelected
  include SetDefaults
  include SetDefaultsWithReflection
  include FoldingBox
end