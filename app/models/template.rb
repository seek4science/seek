class Template < ApplicationRecord
  acts_as_authorized
  
  has_many :template_attributes, inverse_of: :template, dependent: :destroy
  has_many :sample_types
  validates :title, presence: true
  validates :title, uniqueness: { scope: :group }

  accepts_nested_attributes_for :template_attributes, allow_destroy: true

  def can_delete?(user = User.current_user)
    return false if user.nil? || user.person.nil? 
    # return true if user.is_admin?
    contributor == user.person || projects.detect { |project| project.can_manage?(user) }.present?
    contributor && sample_types.empty?
  end

  def can_view?(user = User.current_user)
    (user && user.person && (user.person.projects & projects).any?)
  end

  def self.can_create?
    can = User.logged_in_and_member? && Seek::Config.samples_enabled
    can && User.current_user.is_admin_or_project_administrator?
  end
  
end
