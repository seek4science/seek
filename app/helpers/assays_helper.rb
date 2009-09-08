require 'acts_as_ontology_view_helper'

module AssaysHelper
  
  include Stu::Acts::Ontology::ActsAsOntologyViewHelper
  include ISAHelper

  #assays that haven't already been associated with a study
  def assays_available_for_study_association
    Assay.find(:all,:conditions=>['study_id IS NULL'])
  end

  #only data files authorised for show, and belonging to projects matching current_user
  def data_files_for_assay_association
    data_files=DataFile.find(:all,:include=>:asset)
    data_files=data_files.select{|df| current_user.person.projects.include?(df.asset.project)}
    Authorization.authorize_collection("show",data_files,current_user)
  end

end
