class Placeholder < ApplicationRecord
  
  include Seek::Rdf::RdfGeneration

  has_many :projects
  validates :projects, presence: true, projects: { self: true }

  # Returns the columns to be shown on the table view for the resource
  def columns_default
  end

  def columns_allowed
    super + ['license','last_used_at','other_creators','deleted_contributor']  
  end

  def use_mime_type_for_avatar?
    true
  end

  def self.can_create?
    User.logged_in_and_member?
  end

end
