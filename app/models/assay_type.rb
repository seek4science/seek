require 'acts_as_ontology'

class AssayType < ActiveRecord::Base

  belongs_to :contributor,:class_name => "Person"
  has_many :assays
  scope :user_defined_assay_types, :conditions => "contributor_id is not null"

  # default_parent_id: either exp assay type or modelling analysis type
  # link_from: where the new assay type link was initiated, e.g. new assay type link at assay creation page,--> link_from = "assays".
  attr_accessor :default_parent_id, :link_from

  acts_as_ontology

  validates_presence_of :title
  alias_attribute :label, :title
  validate :uniq_term_uri_combined_with_title
  before_validation :default_parents_and_term_uri , :if => "self.parents.empty? && self != AssayType.ontology_root"


  def default_parents_and_term_uri
    self.parents = [AssayType.ontology_root] if AssayType.ontology_root
    self.term_uri = self.parents.first.try(:term_uri) if self.term_uri.nil?
  end

  def self.ontology_root
      self.to_tree.detect{|at| at.term_uri == "http://www.mygrid.org.uk/ontology/JERMOntology#Assay_type" || at.title == "assay types"}
  end


  def uniq_term_uri_combined_with_title
     if self.new_record?
       errors[:base] << "Assay type with label #{self.title} and parent #{self.parents.first.try(:title)} already exists!" if AssayType.all.detect{|at| at.title == self.title && at.term_uri == self.term_uri}
     else
       errors[:base] << "Assay type with label #{self.title} and parent #{self.parents.first.try(:title)} already exists!" if AssayType.all.detect{|at| at.id != self.id && at.title == self.title && at.term_uri == self.term_uri}
     end
  end


  def is_user_defined
     !contributor.nil?
  end

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
    at=AssayType.find_by_term_uri("http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_Assay_Type").id
  end

  #FIXME: really not happy looking up by title, but will be replaced by BioPortal eventually
  def self.modelling_assay_type_id
    at=AssayType.find_by_term_uri("http://www.mygrid.org.uk/ontology/JERMOntology#Model_Analysis_Type").id
  end


  def can_edit?
    contributor && User.logged_in_and_member?
  end

  def can_destroy? user=User.current_user
   (contributor && (user == contributor.user)) || User.asset_manager_logged_in?
  end

end
  

