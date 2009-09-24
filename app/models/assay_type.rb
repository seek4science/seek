require 'acts_as_ontology'

class AssayType < ActiveRecord::Base

  has_many :assays
  
  acts_as_ontology

  def get_child_assays assay_type=self
    #TODO: needs unit test
    result = assay_type.assays
    assay_type.children.each do |child|
      result = result | child.assays
      result = result | get_child_assays(child) if child.has_children?
    end
    return result
  end
  
  def get_all_descendants assay_type=self
    result = []
    assay_type.children.each do |child|
      result << child
      result = result | get_all_descendants(child) if child.has_children?
    end
    return result
  end
 
  private




end
  

