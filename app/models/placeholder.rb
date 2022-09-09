class Placeholder < ApplicationRecord
  
  include Seek::Rdf::RdfGeneration

  acts_as_asset

  has_controlled_vocab_annotations :data_types, :data_formats

  validates :projects, presence: true, projects: { self: true }

  belongs_to :project
  belongs_to :file_template
  belongs_to :data_file
  
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
