# To change this template, choose Tools | Templates
# and open the template in the editor.

module Stu
  module Acts
    module Ontology
      module ActsAsOntologyViewHelper
        
        def ontology_select_tag form,type,root_id,element_id,selected_id=nil,html_options={}

          roots=type.to_tree(root_id).sort{|a,b| a.title.downcase <=> b.title.downcase}
          options=[]
          roots.each do |root|
            options << [root.title,root.id]
            options = options + child_select_options(root,1)
          end

          selected_id ||= roots.first.id
          
          form.select element_id,options,{:selected=>selected_id},html_options

        end

        private

        def child_select_options parent,depth=0
          result = []
          unless parent.children.empty?
            parent.children.sort{|a,b| a.title.downcase <=> b.title.downcase}.each do |child|
              result << ["---"*depth + child.title,child.id]
              result = result + child_select_options(child,depth+1) if child.has_children?
            end
          end
          return result
        end

      end
    end
  end
end
