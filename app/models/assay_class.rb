class AssayClass < ActiveRecord::Base

  #this returns an instance of AssayClass according to one of the types "experimental" or "modelling"
  #if there is not a match nil is returned
  def self.for_type type
    keys={"experimental"=>"EXP","modelling"=>"MODEL"}
    return AssayClass.find_by(key: keys[type])
  end

  def self.experimental
    self.for_type('experimental')
  end

  def self.modelling
    self.for_type('modelling')
  end

  def is_modelling?
    key == "MODEL"
  end
end
