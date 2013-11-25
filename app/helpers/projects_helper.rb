#encoding: utf-8

module ProjectsHelper
  def project_select_choices
    res=[]
    Project.all.collect { |p| res << [p.name, p.id] }
    return res
  end

  def projects_link_list projects, sorted=true
    projects=projects.select { |p| !p.nil? } #remove nil items
    return "<span class='none_text'>Not defined</span>".html_safe if projects.empty?

    result=""
    projects=projects.sort { |a, b| a.title<=>b.title } if sorted
    projects.each do |proj|
      result += link_to h(proj.title), proj
      result += " | " unless projects.last==proj
    end
    return result.html_safe
  end

  def pals_link_list project
    if project.pals.empty?
      html = "<span class='none_text'>No PALs for this #{t('project')}</span>";
    else
      html = project.pals.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def asset_managers_link_list project
    if project.asset_managers.empty?
      html = "<span class='none_text'>No Asset Managers for this #{t('project')}</span>";
    else
      html = project.asset_managers.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def project_managers_link_list project
    if project.project_managers.empty?
      html = "<span class='none_text'>No #{t('project')} Managers for this #{t('project')}</span>";
    else
      html = project.project_managers.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def gatekeepers_link_list project
    if project.gatekeepers.empty?
      html = "<span class='none_text'>No Gatekeepers for this #{t('project')}</span>";
    else
      html = project.gatekeepers.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end

  def project_coordinators_link_list project
    if project.project_coordinators.empty?
      html=  "<span class='none_text'>No project coordinators for this project</span>";
    else
      html = project.project_coordinators.select(&:can_view?).collect { |p| link_to(h(p.name), p) }.join(", ")
    end
    html.html_safe
  end
  def project_mailing_list project
    if project.people.empty?
      html = "<span class='none_text'>No people in this #{t('project')}</span>";
    else
      html = "<span>" + project.people.sort_by(&:last_name).select(&:can_view?).map{|p|link_to(h(p.name), p) + " (" + p.email + ")"}.join(";<br/>") + "</span>";
    end
    html.html_safe
  end

  def tree_editor_display type, show_edit=true, show_delete=true, selected_id=nil, related_resource_type="Person",selective_display=false, foldable=false

    selected_display_items = nil

    if selected_id && selective_display
      selected = type.find selected_id
      selected_display_items = [selected] + selected.ancestors
    end


    roots = type.roots.sort { |a, b| a.title.downcase <=> b.title.downcase }
    list = []
    roots.each do |root|
      related_resource = eval "root.#{related_resource_type.downcase.pluralize}"
      depth = 1
      display_style = (foldable == true) ? "display:none" : "display:block"
      display_style = "display:block" if (foldable == true) && (!selected_display_items.nil?) && selected_display_items.include?(root)

      #two images for toggle
      expand_link = link_to_function expand_plus_image, :style => "float:left;" + "display:" + (display_style=='display:none' ? 'block;' : 'none;'), :id =>"projects_hierarchies_expand_#{root.id}" do |page|
        page.visual_effect :toggle_blind, "#{root.id}", :duration => 0.5
        page["projects_hierarchies_expand_#{root.id}"].toggle
        page["projects_hierarchies_collapse_#{root.id}"].toggle

      end
      collapse_link = link_to_function collapse_minus_image,:style => "float:left;"+ "display:" + (display_style=='display:none' ? 'none;' : 'block;'), :id =>"projects_hierarchies_collapse_#{root.id}" do |page|
        page.visual_effect :toggle_blind, "#{root.id}", :duration => 0.5
        page["projects_hierarchies_expand_#{root.id}"].toggle
        page["projects_hierarchies_collapse_#{root.id}"].toggle
      end

      folder_tag =  expand_link + collapse_link
      if foldable
        folder = root.has_children? ? folder_tag : " "
        margin_left = root.has_children? ? "" : "margin-left:18px"
        
      else
        folder = " "
        margin_left  = ""
      end
      list << "<li style=\"#{margin_left} ; #{root.id == selected_id ? "background-color: lightblue;" : "#{(selected_display_items && selected_display_items.include?(root))? "font-weight: bold;" : ""}"}\">"+ folder + (link_to root.title, root) + " " +
          (show_edit ? link_to(image("edit"), edit_polymorphic_path(root), {:style=>"vertical-align:middle"}) : "") + " " +
          (show_delete ? link_to(image("destroy"), root, :confirm =>
              "Are you sure you want to remove this #{root.class.name}?  This cannot be undone.",
                                                               :method => :delete, :style=>"vertical-align:middle") : "")  + "<span style=\"color: #666666;\">(#{related_resource.size} #{related_resource_type.downcase.pluralize})</span>" +
          "</li>"

      list << "<div id= '#{root.id}' style='#{display_style}'>"
      list = list + indented_tree_child_options(root, depth, show_edit, show_delete, selected_id, related_resource_type, selected_display_items,foldable)
      list << "</div>"

    end
    list.join("\n").html_safe
  end

  #Displays the tree node with appropriate indentation, as well as optional
  #edit and remove icons, and the number of people associated with the node.
  def indented_tree_child_options parent, depth=0, show_edit=true, show_delete=true, selected_id=nil, related_resource_type="Person",selected_display_items=nil, foldable=true
    result = []
    unless parent.children.empty?
      parent.children.sort { |a, b| a.title.downcase <=> b.title.downcase }.each do |child|
        display_style = (foldable==true) ? "display:none" : "display:block"
        display_style = "display:block" if (foldable == true) && (!selected_display_items.nil?) && selected_display_items.include?(child)
        expand_link = link_to_function expand_plus_image, :style => "float:left;" + "display:" + (display_style=='display:none' ? 'block;' : 'none;'), :id =>"projects_hierarchies_expand_#{parent.id}_#{child.id}" do |page|
          page.visual_effect :toggle_blind, "#{parent.id}_#{child.id}", :duration => 0.5
          page["projects_hierarchies_expand_#{parent.id}_#{child.id}"].toggle
          page["projects_hierarchies_collapse_#{parent.id}_#{child.id}"].toggle
        end
        collapse_link = link_to_function collapse_minus_image,:style => "float:left;" + "display:" + (display_style=='display:none' ? 'none;' : 'block;'), :id =>"projects_hierarchies_collapse_#{parent.id}_#{child.id}" do |page|
          page.visual_effect :toggle_blind, "#{parent.id}_#{child.id}", :duration => 0.5
          page["projects_hierarchies_expand_#{parent.id}_#{child.id}"].toggle
          page["projects_hierarchies_collapse_#{parent.id}_#{child.id}"].toggle
        end

        folder_tag =  expand_link + collapse_link
        if foldable
          folder = child.has_children? ? folder_tag : " └ "
        else
          folder = depth>0 ? " └ " : " "
        end

        related_resource = eval "child.#{related_resource_type.downcase.pluralize}"
        result << "<li style=\"margin-left:#{12*depth}px;#{child.id == selected_id ? "background-color: lightblue;" : "#{(selected_display_items && selected_display_items.include?(child))? "font-weight: bold;" : ""}"};\">"+ folder + (link_to child.title, child) + " " +
            (show_edit ? link_to(image("edit"), edit_polymorphic_path(child), {:style=>"vertical-align:middle"}) : "") + " " +
            (show_delete ? link_to(image("destroy"), child, :confirm =>
                "Are you sure you want to remove this #{child.class.name}?  This cannot be undone.",
                                   :method => :delete, :style=>"vertical-align:middle") : "")+ "<span style=\"color: #666666;\">(#{related_resource.size} #{related_resource_type.downcase.pluralize})</span>" +

            "</li>"

        if child.has_children?
          result << "<div id= '#{parent.id}_#{child.id}' style='#{display_style}'>"
          result = result + indented_tree_child_options(child, depth+1, show_edit, show_delete, selected_id, related_resource_type, selected_display_items, foldable)
          result<< "</div>"
        end
      end
    end
    return result
  end

  def tree_single_select_tag type, id, selected_item=nil, disabled_items=[], name=nil, html_options={:multiple => false, :size => 10, :style => "width:600px;"}
    name = id if name.nil?
    roots = type.roots.sort { |a, b| a.title.downcase <=> b.title.downcase }
    options=[]
    roots.each do |root|
      options << [root.title, root.id]
      options = options + child_single_select_options(root, 1)
    end
    disabled_options = []
    disabled_items.each do |o|
      disabled_options << o.id
    end

    select_tag "#{type.name.underscore}[#{name}]", options_for_select(options, :selected => selected_item, :disabled => disabled_options), html_options
  end

  private
  def child_single_select_options parent, depth=0
    result = []

    unless parent.children.empty?
      parent.children.sort { |a, b| a.title.downcase <=> b.title.downcase }.each do |child|
        result << ["---"*depth + child.title, child.id]
        result = result + child_single_select_options(child, depth+1) unless child.children.blank?
      end
    end
    return result
  end

end

