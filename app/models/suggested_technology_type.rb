class SuggestedTechnologyType < ActiveRecord::Base

  #initial(invalid) unique uri before added to ontology, it can be updated when sync with ontology
  alias_attribute :uuid, :uri
  acts_as_uniquely_identifiable


  belongs_to :contributor,:class_name => "Person"

  # link_from: where the new technology type link was initiated, e.g. new technology type link at technology creation page,--> link_from = "assays".
  #or from admin page --> manage technology types
  attr_accessor  :link_from


  validates_presence_of :label
  validates_uniqueness_of :label
  validate :label_not_defined_in_ontology
  before_validation :default_parent

  def ontology_reader
      Seek::Ontologies::TechnologyTypeReader.instance
  end

  def default_parent_uri
      ontology_reader.default_parent_class_uri.try(:to_s)
  end

  def label_not_defined_in_ontology
      ontology_labels =  Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_label.keys

      errors[:base] << "Technology type with label #{self.label} already exists!" if ontology_labels.each(&:downcase).include?(self.label.downcase)
  end


  def parents
    Array(parent)
  end
  def parent
    ontology_reader.class_hierarchy.hash_by_uri[self.parent_uri] || SuggestedTechnologyType.where(:uri=> self.parent_uri).first
  end
  # before adding to ontology ang assigned a uri, returns its parent_uri
  def default_parent
    if self.parent_uri.blank?
          raise Exception.new("Technology type #{self.label} has no default parent uri!") if self.default_parent_uri.blank?
          self.parent_uri = self.default_parent_uri
    end
  end

  def children
      SuggestedTechnologyType.where(:parent_uri=> self.uri)
  end

  def assays
      Assay.where(technology_type_uri: self.uri)
  end

  def can_edit?
      contributor==User.current_user.person || User.admin_logged_in?
  end

  def can_destroy? user=User.current_user
  auth = User.admin_logged_in?
  auth && self.assays.count == 0 && self.children.empty?
  end

end
