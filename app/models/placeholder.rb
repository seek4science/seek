class Placeholder < ApplicationRecord
  
  include Seek::Rdf::RdfGeneration

  acts_as_asset

  has_ontology_annotations :data, :formats

  validates :projects, presence: true, projects: { self: true }

  belongs_to :project
  belongs_to :file_template
  belongs_to :data_file

  def edam_topics_vocab
    nil
  end
  
  def edam_operations_vocab
    nil
  end
  
  def avatar_key
    :programme
  end

  def self.can_create?
    User.logged_in_and_member?
  end

  def is_discussable?
    false
  end

  def self.user_creatable?
    Seek::Config.placeholders_enabled
  end

end
