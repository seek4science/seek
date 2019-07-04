class WorkGroup < ApplicationRecord
  belongs_to :institution, inverse_of: :work_groups
  belongs_to :project, inverse_of: :work_groups
  has_many :group_memberships, dependent: :destroy, inverse_of: :work_group
  has_many :people, through: :group_memberships, inverse_of: :work_groups
  has_many :dependent_permissions, class_name: 'Permission', as: :contributor, dependent: :destroy

  validates :project,:presence => {:message=>"A project is required"}
  validates :institution,:presence => {:message=>"An institution is required"}

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :institution, :project

  def destroy
    if people.empty?
        super
    else
      raise Exception.new("You can not delete the " +description+ ". This Work Group has "+people.size.to_s+" people associated with it. Please disassociate first the people from this Work Group")
    end
  end

  def description
    project.title + " at " + institution.title
  end
end
