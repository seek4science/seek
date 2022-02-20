class Placeholder < ApplicationRecord
  
  include Seek::Rdf::RdfGeneration

  acts_as_asset

  has_edam_annotations

  validates :projects, presence: true, projects: { self: true }

  belongs_to :project
  belongs_to :file_template
  belongs_to :data_file
  
  # Returns the columns to be shown on the table view for the resource
  def columns_default
    super + ['format_type', 'data_type']
  end

  def columns_allowed
    super  + ['format_type', 'data_type', 'license','last_used_at','other_creators','deleted_contributor']  
  end

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
