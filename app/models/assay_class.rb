class AssayClass < ActiveRecord::Base

  #this returns an instance of AssayClass according to one of the types "experimental" or "modelling"
  #if there is not a match nil is returned
  def self.for_type type
    ids={"experimental"=>1,"modelling"=>2}
    return AssayClass.find_by_id(ids[type])
  end
end
