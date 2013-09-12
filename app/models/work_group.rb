class WorkGroup < ActiveRecord::Base
  belongs_to :institution
  belongs_to :project
  has_many :group_memberships, :dependent => :destroy
  has_many :people, :through=>:group_memberships

  include Seek::Rdf::ReactToAssociatedChange
  update_rdf_on_change :institution, :project

  def description
    project.name + " at " + institution.name
  end

end
