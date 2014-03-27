#encoding: utf-8

# To change this template, choose Tools | Templates
# and open the template in the editor.

module Stu
  module Acts
    module Ontology
      module ActsAsOntologyViewHelper


        def ontology_select_tag_old form, type, root_id, element_id, selected_id=nil, html_options={}
          roots=type.to_tree(root_id).sort { |a, b| a.title.downcase <=> b.title.downcase }
          options=[]
          roots.each do |root|
            options << [root.title, root.id]
            options = options + child_select_options(root, 1)
          end

          selected_id ||= roots.first.id

          if form
            form.select element_id, options, {:selected => selected_id}, html_options
          elsif html_options[:name]
            select_tag html_options[:name], options_for_select(options, :selected => selected_id), html_options
          end
        end


        #Displays the ontology with links to edit and remove each node, if requested.
        #Items with an ID matching selected_id are highlighted blue.
        def ontology_editor_display type, root_id=nil, selected_id=nil

          # login users can edit new defined assay/technology types
          # only admin can edit/delete new defined assay/technology types
          show_edit = false
          show_delete = false

          roots=type.to_tree(root_id).sort { |a, b| a.title.downcase <=> b.title.downcase }
          list = []
          roots.each do |root|
            if root_id
              path = send("#{type.model_name.underscore}s_path", :uri=>root.term_uri, :label=> root.title)
              assay_stat = root.assays.size == 0 ?  "" : "<span style='color: #666666;'>(#{root.assays.count} assays)</span>".html_safe
              root_link = "<li style=\"margin-left:0px;\">" + link_to(root.title, path) + assay_stat + "</li>"
              list << root_link
              depth = 1
            else
              depth = 0
            end
            list = list + indented_child_options(type, root, depth, selected_id)
          end
          list = list.join("\n").html_safe
          list = list + "<br/> <em>* Note that it is created by seek user.</em>".html_safe
        end


        private


        #Displays the ontology node with appropriate indentation, as well as optional
        #edit and remove icons, and the number of assays associated with the node.
        def indented_child_options type, parent, depth=0, selected_id

          result = []
          unless parent.children.empty?
            parent.children.sort { |a, b| a.title.downcase <=> b.title.downcase }.each do |child|
              child_path = send("#{type.model_name.underscore}s_path", :uri=>child.term_uri, :label=> child.title)
              assay_stat = child.assays.size == 0 ?  "" : "<span style='color: #666666;'>(#{child.assays.count} assays)</span>".html_safe
              ontology_term_li = link_to(child.title, child_path).html_safe
              user_defined_term_li = link_to(child.title, child_path, {:style => "color:green;font-style:italic"}) + "*" + " " +
                  (child.can_edit? ? link_to(image("edit"), edit_polymorphic_path(child), {:style => "vertical-align:middle"}) : "") + " " +
                  (child.can_destroy? ? (child.assays.count == 0 && child.children.empty? ? link_to(image("destroy"), child, :confirm =>
                      "Are you sure you want to remove this #{child.class.name}?  This cannot be undone.",
                                                                        :method => :delete, :style => "vertical-align:middle") : "") : "").html_safe
              child_link = (child.respond_to?(:is_user_defined) && child.is_user_defined) ? user_defined_term_li : ontology_term_li

              result << ("<li style=\"margin-left:#{12*depth}px;#{child.id == selected_id ? "background-color: lightblue;" : ""}\">"+ (depth>0 ? "└ " : " ") + child_link +  assay_stat +
                  "</li>")
              result = result + indented_child_options(type, child, depth+1,selected_id) if child.has_children?
            end
          end
          return result
        end


        def child_select_options parent, depth=0
          result = []
          unless parent.children.empty?
            parent.children.sort { |a, b| a.title.downcase <=> b.title.downcase }.each do |child|
              result << ["---"*depth + child.title, child.id]
              result = result + child_select_options(child, depth+1) if child.has_children?
            end
          end
          return result
        end

      end
    end
  end
end
