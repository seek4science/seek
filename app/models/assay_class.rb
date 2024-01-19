class AssayClass < ApplicationRecord
  # this returns an instance of AssayClass according to one of the types "experimental", "modelling" or "assay_stream"
  # if there is not a match nil is returned
  def self.for_type(type)
    keys = { "experimental": 'EXP', "modelling": 'MODEL', "assay_stream": 'ASS' }
    AssayClass.find_by(key: keys[type.to_sym])
  end

  def self.experimental
    for_type('experimental')
  end

  def self.modelling
    for_type('modelling')
  end

  def self.assay_stream
    for_type('assaystream')
  end

  def is_modelling?
    key == 'MODEL'
  end

  def is_experimental?
    key == 'EXP'
  end

  def is_assay_stream?
    key == 'ASS'
  end

  # for cases where a longer more descriptive key is useful, but can't rely on the title
  #  which may have been changed over time
  def long_key
    { 'EXP': 'Experimental Assay', 'MODEL': 'Modelling Analysis', 'ASS': 'Assay Stream' }[key.to_sym]
  end
end
