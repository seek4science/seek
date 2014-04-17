#encoding: utf-8
module SuggestedAssayTypesHelper
  def create_suggested_assay_type_popup_link is_for_modelling=nil, link_from="suggested_assay_types"
    link_title = is_for_modelling ? "new modelling analysis type" : "new assay type"
    return link_to_remote_redbox(image("new") + ' ' + link_title,
                                 {:url => new_suggested_assay_type_path,
                                  :failure => "alert('Sorry, an error has occurred.'); RedBox.close();",
                                  :with => "'is_for_modelling=#{is_for_modelling}' +'&link_from=#{link_from}'",
                                  :method=> :get
                                 }
    )
  end

  #select tag without form
  def ontology_selection_list type, element_name, selected_uri, html_options={}
    case type
      when "assay", "modelling_analysis", "technology"
        reader = reader_for_type(type)
        classes = reader.class_hierarchy
        options = render_ontology_class_options classes
      when "all_assay_type"
        assay_type_reader = reader_for_type("assay")
        modelling_analysis_reader = reader_for_type("modelling_analysis")
        assay_type_classes = assay_type_reader.class_hierarchy
        modelling_analysis_classes = modelling_analysis_reader.class_hierarchy

        options = render_ontology_class_options(assay_type_classes)
        options += render_ontology_class_options(modelling_analysis_classes)
      else
        options = []
    end

    select_tag element_name, options_for_select(options, :selected => selected_uri), html_options
  end

  # type: assay type,technology type

  def ontology_editor_display type, selected_uri=nil, html_options={}

    list = []
    case type
      when "assay"
        cache_key = [:ontology_editor_display, SuggestedAssayType.exp_types.order('updated_at').last.cache_key]
        list += cached_list("assay", cache_key, selected_uri)
      #roots =   classes.hash_by_uri[reader.default_parent_class_uri.try(:to_s)]
      when "modelling_analysis"
        cache_key = [:ontology_editor_display, SuggestedAssayType.modelling_types.order('updated_at').last.cache_key]
        list += cached_list("modelling_analysis", cache_key, selected_uri)
      when "all_assay_type"
        exp_cache_key = [:ontology_editor_display, SuggestedAssayType.exp_types.order('updated_at').last.cache_key]
        modelling_cache_key = [:ontology_editor_display, SuggestedAssayType.modelling_types.order('updated_at').last.cache_key]
        list += cached_list("assay", exp_cache_key, selected_uri)
        list += cached_list("modelling_analysis", modelling_cache_key, selected_uri)

      when "technology"
        cache_key = [:ontology_editor_display, SuggestedTechnologyType.order('updated_at').last.cache_key]
        list += cached_list("technology", cache_key, selected_uri)

      else
        return nil
    end
    list = list.join("\n").html_safe
    list = list + "<br/> <em>* Note that it is created by seek user.</em>".html_safe
    list
  end

  def cached_list type, cache_key,selected_uri=nil

    list = Rails.cache.fetch(cache_key) do
      reader = reader_for_type(type)
      classes = reader.class_hierarchy
      model_class_pre = type=="modelling_analysis" ? "assay" : type
      render_ontology_class_tree(classes, model_class_pre, selected_uri)
    end
    list.nil? ? [] : list
  end

  def render_ontology_class_tree clz, type, selected_uri,depth=0
    list = []
    uri = clz.uri.try(:to_s)
    path = send("#{type}_types_path", :uri => uri, :label => clz.label)
    assays = clz.assays
    assay_stat = assays.size == 0 ? "" : "<span style='color: #666666;'>(#{assays.size} assays)</span>".html_safe
    clz_link = is_suggested?(clz) ? link_to(clz.label, path, {:style => "color:green;font-style:italic"}) + "*" + " " +
        (clz.can_edit? ? link_to(image("edit"), edit_polymorphic_path(clz), {:style => "vertical-align:middle"}) : "") + " " +
        (clz.can_destroy? && action_name =="manage" ? link_to(image("destroy"), clz, :confirm =>
            "Are you sure you want to remove this #{type} type?  This cannot be undone.", :method => :delete, :style => "vertical-align:middle") : "").html_safe : link_to(clz.label, path)
    clz_li = "<li style=\"margin-left:#{12*depth}px;#{uri == selected_uri ? "background-color: lightblue;" : ""}\">" + (depth>0 ? "└ " : " ")+ clz_link + assay_stat + "</li>"
    list << clz_li

    clz.children.each do |c|
      list +=render_ontology_class_tree(c, type, selected_uri, depth+1)
    end

    list
  end

  def is_suggested? term
    term.is_a?(SuggestedAssayType) || term.is_a?(SuggestedTechnologyType)
  end


end