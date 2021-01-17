class AssayClass < ApplicationRecord

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

  def is_experimental?
    key == 'EXP'
  end

  # for cases where a longer more descriptive key is useful, but can't rely on the title
  #  which may have been changed over time
  def long_key
    {'EXP'=>'Experimental Assay','MODEL'=>'Modelling Analysis'}[key]
  end
end
