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

end
