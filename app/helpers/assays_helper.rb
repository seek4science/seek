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

  
  def assay_type_select_tag form

    roots=AssayType.to_tree
    options=[]
    roots.each do |root|
      options << [root.title,root.id]
      options = options | child_select_options(root,1)
    end
    
    form.select "assay_type_id",options

  end

  private

  def child_select_options parent,depth=0
    result = []
    unless parent.children.empty?
      parent.children.each do |child|
        result << ["---"*depth + child.title,child.id]
        result = result | child_select_options(child,depth+1) if child.has_children?
      end
    end
    return result
  end

end
