module AssaysHelper
  
  #determines if the current assay can be edited by the 'current_user'
  def user_can_edit_assay? assay
    #FIXME: who can edit the Assay?
    true
  end

  #determines if an assay can be deleted. This is only possible if the assay has no associated studies, and the user is authorised to
  def user_can_delete_assay? assay
    return assay.studies.empty?
  end

  
  def assay_type_select_tag form,selected_id=nil

    roots=AssayType.to_tree.sort{|a,b| a.title.downcase <=> b.title.downcase}
    options=[]
    roots.each do |root|
      options << [root.title,root.id]
      options = options | child_select_options(root,1)
    end

    selected_id ||= roots.first.id
    form.select "assay_type_id",options,:selected=>selected_id

  end

  private

  def child_select_options parent,depth=0
    result = []
    unless parent.children.empty?
      parent.children.sort{|a,b| a.title.downcase <=> b.title.downcase}.each do |child|
        result << ["---"*depth + child.title,child.id]
        result = result | child_select_options(child,depth+1) if child.has_children?
      end
    end
    return result
  end

end
