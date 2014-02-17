require 'acts_as_ontology'

class AssayType < ActiveRecord::Base

  has_many :assays
  attr_accessor :parent_name
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

  #FIXME: really not happy looking up by title, but will be replaced by BioPortal eventually
  def self.experimental_assay_type_id
    at=AssayType.find_by_term_uri("http://www.mygrid.org.uk/ontology/JERMOntology#ExperimentalAssayType").id
  end

  #FIXME: really not happy looking up by title, but will be replaced by BioPortal eventually
  def self.modelling_assay_type_id
    at=AssayType.find_by_term_uri("http://www.mygrid.org.uk/ontology/JERMOntology#ModelAnalysisType").id
  end




end
  

