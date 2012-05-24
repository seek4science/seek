class WorkGroup < ActiveRecord::Base
  belongs_to :institution
  belongs_to :project
  has_many :group_memberships, :dependent => :destroy
  has_many :people, :through=>:group_memberships
  
  def destroy
    if people.empty?
        super
    else
      raise Exception.new("Cannot delete with associated people. This WorkGroup has "+people.size.to_s+" people associated with it")
    end
  end
  
  def description
    project.name + " at " + institution.name
  end

end
