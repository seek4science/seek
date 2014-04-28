
class SuggestedAssayType < ActiveRecord::Base


  #initial(invalid) unique uri before added to ontology, it can be updated when sync with ontology
  alias_attribute :uuid, :uri
  acts_as_uniquely_identifiable


  belongs_to :contributor,:class_name => "Person"

  # link_from: where the new assay type link was initiated, e.g. new assay type link at assay creation page,--> link_from = "assays".
  #or from admin page --> manage assay types
  attr_accessor  :link_from


  validates_presence_of :label
  validates_uniqueness_of :label, :uri
  validate :label_not_defined_in_ontology
  before_validation :default_parent

  scope :modelling_types, where(:is_for_modelling => true)
  scope :exp_types, where(:is_for_modelling => false )


  def ontology_reader
    if self.is_for_modelling
      Seek::Ontologies::ModellingAnalysisTypeReader.instance
    else
      Seek::Ontologies::AssayTypeReader.instance
    end
  end

  def default_parent_uri
      ontology_reader.default_parent_class_uri.try(:to_s)
  end

  def label_not_defined_in_ontology
      ontology_labels =  Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_label.keys
      ontology_labels |= Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_label.keys

      errors[:base] << "Assay type with label #{self.label} is already defined in ontology!" if ontology_labels.each(&:downcase).include?(self.label.downcase)
  end


  def parents
    Array(parent)
  end
  def parent
    ontology_reader.class_hierarchy.hash_by_uri[self.parent_uri] || SuggestedAssayType.where(:uri=> self.parent_uri).first
  end
  # before adding to ontology ang assigned a uri, returns its parent_uri
  def default_parent
    if self.parent_uri.blank?
          raise Exception.new("Assay type #{self.label} has no default parent uri!") if self.default_parent_uri.blank?
          self.parent_uri = self.default_parent_uri
    end
  end

  def children
      SuggestedAssayType.where(:parent_uri=> self.uri)
  end

  def assays
      Assay.where(assay_type_uri: self.uri)
  end

  def can_edit?
      contributor==User.current_user.try(:person) || User.admin_logged_in?
  end

  def can_destroy?
  auth = User.admin_logged_in?
  auth && self.assays.count == 0 && self.children.empty?
  end

  def get_child_assays suggested_assay_type=self
      result = suggested_assay_type.assays
      suggested_assay_type.children.each do |child|
        result = result | child.assays
        result = result | get_child_assays(child) if !child.children.empty?
      end
      return result
  end

end
  

