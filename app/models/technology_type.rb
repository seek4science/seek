require 'acts_as_ontology'

class TechnologyType < ActiveRecord::Base

  has_many :assays
  scope :user_defined_technology_types, :conditions => "source_path is null || source_path = ''"

   # link_from: where the new technology type link was initiated, e.g. new technology type link at assay creation page,--> link_from = "assays"
  attr_accessor :link_from



  acts_as_ontology

  validates_presence_of :title
  alias_attribute :label, :title

  def self.ontology_root
      self.to_tree.detect{|at| at.term_uri == "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type" || at.title == "technology"  }
  end

  validate :uniq_term_uri_combined_with_title
  before_validation :default_parents_and_term_uri , :if => "self.parents.empty? && self != TechnologyType.ontology_root"


  def default_parents_and_term_uri
    self.parents = [TechnologyType.ontology_root] if TechnologyType.ontology_root
    self.term_uri = self.parents.first.try(:term_uri) if self.term_uri.nil?
  end
  def uniq_term_uri_combined_with_title
    if self.new_record?
      errors[:base] << "Technology type with label #{self.title} and parent #{self.parents.first.try(:title)} already exists!" if TechnologyType.all.detect { |at| at.title == self.title && at.term_uri == self.term_uri }
    else
      errors[:base] << "Technology type with label #{self.title} and parent #{self.parents.first.try(:title)} already exists!" if TechnologyType.all.detect { |at| at.id != self.id && at.title == self.title && at.term_uri == self.term_uri }
    end
  end


  def is_user_defined
    self.source_path.blank?
  end


  def get_child_assays technology_type=self
    #TODO: needs unit test
    #TODO: make Assay independant, and move some of this to acts_as_ontology
    result = technology_type.assays
    technology_type.children.each do |child|
      result = result | child.assays
      result = result | get_child_assays(child) if child.has_children?
    end
    return result
  end
 
  def get_all_descendants technology_type=self
    result = []
    technology_type.children.each do |child|
      result << child
      result = result | get_all_descendants(child) if child.has_children?
    end
    return result
  end

end
