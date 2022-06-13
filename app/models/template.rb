class Template < ApplicationRecord
  acts_as_authorized
  
  has_many :template_attributes, -> { order(:pos) }, inverse_of: :template, dependent: :destroy
  has_many :sample_types
	has_many :samples, through: :sample_types

  validates :title, presence: true
  validates :title, uniqueness: { scope: :group }

  accepts_nested_attributes_for :template_attributes, allow_destroy: true

  def can_delete?(user = User.current_user)
    super && sample_types.empty?
  end

  def can_edit?(user = User.current_user)
    super && sample_types.empty?
  end

  def self.can_create?
    can = User.logged_in_and_member? && Seek::Config.samples_enabled
    can && User.current_user.is_admin_or_project_administrator?
  end

  def resolve_inconsistencies
    resolve_controlled_vocabs_inconsistencies
  end

  private

  # fixes the consistency of the attribute controlled vocabs where the attribute doesn't match.
  # this is to help when a controlled vocab has been selected in the form, but then the type has been changed
  # rather than clearing the selected vocab each time
  def resolve_controlled_vocabs_inconsistencies
    template_attributes.each do |attribute|
      attribute.sample_controlled_vocab = nil unless attribute.sample_attribute_type.controlled_vocab?
    end
  end
	
end

