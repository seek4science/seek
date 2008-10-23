class WorkGroup < ActiveRecord::Base
  belongs_to :institution
  belongs_to :project
  has_and_belongs_to_many :people
  
  
  def destroy
    if people.empty?
        super
    else
      raise Exception.new("Cannot delete with associated people. This WorkGroup has "+people.size.to_s+" people associated with it")
    end
  end
  
  def description
    project.title + " at " + institution.name
  end
  
end
