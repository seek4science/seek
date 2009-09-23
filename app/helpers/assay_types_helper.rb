module AssayTypesHelper
  
  def assay_type_ontology_edit_display
    roots=AssayType.to_tree.sort{|a,b| a.title.downcase <=> b.title.downcase}
    list = []
    roots.each do |root|
      list = list | child_indented_options(root,0)
    end
    
    list.collect do |item|
      item + "\n"
    end

  end
  
  def child_indented_options parent,depth=0
    result = []
    unless parent.children.empty?
      parent.children.sort{|a,b| a.title.downcase <=> b.title.downcase}.each do |child|
        result << "<li style=\"margin-left:#{12*depth}px;\">"+ (depth>0 ? "└ " : " ") + child.title + " " +
                    (link_to(image("edit"),edit_assay_type_url(child.id),:style=>"vertical-align:middle") if true)+ " " +
                    (link_to(image("destroy"),child, :confirm => 
                      'Are you sure you want to remove this assay type?  This cannot be undone.',
                      :method => :delete, :style=>"vertical-align:middle") if true) +
                    "</li>"
        result = result | child_indented_options(child,depth+1) if child.has_children?
      end
    end
    return result
  end
  
  def ontology_multiple_select_tag form,type,id,selected_ids=nil,name=nil,size=10
    name = id if name.nil?
    roots=type.to_tree.sort{|a,b| a.title.downcase <=> b.title.downcase}
    options=[]
    roots.each do |root|
      options << [root.title,root.id]
      options = options | child_select_options(root,1)
    end
    
    selected_options = []
    selected_ids.each do |o|
      selected_options << o.id
    end    

    #form.select name,options,{:selected=>selected_id},{:multiple => true, :size => size}
    select_tag "#{type.name.underscore}[#{name}][]", options_for_select(options, selected_options), { :multiple => true, :size => size}

    
  end

end