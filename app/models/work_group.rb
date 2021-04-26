class WorkGroup < ApplicationRecord
  belongs_to :institution, inverse_of: :work_groups
  belongs_to :project, inverse_of: :work_groups
  has_many :group_memberships, dependent: :destroy, inverse_of: :work_group
  has_many :people, through: :group_memberships, inverse_of: :work_groups
  has_many :dependent_permissions, class_name: 'Permission', as: :contributor, dependent: :destroy

  validates :project, presence: { message: 'A project is required' }
  validates :institution, presence: { message: 'An institution is required' }

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :institution, :project

  def description
    "#{project.title} at #{institution.title}"
  end
end
