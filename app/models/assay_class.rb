class AssayClass < ApplicationRecord
  # this returns an instance of AssayClass according to one of the constants defined in seek/isa/assay_class.rb
  # if there is not a match nil is returned
  def self.for_type(type)
    AssayClass.find_by(key: type)
  end

  def self.experimental
    for_type('EXP')
  end

  def self.modelling
    for_type('MODEL')

  end

  def self.assay_stream
    for_type('STREAM')
  end

  def is_modelling?
    key == 'MODEL'
  end

  def is_experimental?
    key == 'EXP'
  end

  def is_assay_stream?
    key == 'STREAM'
  end

  LONG_KEYS = { 'EXP': 'Experimental Assay', 'MODEL': 'Modelling Analysis', 'STREAM': 'Assay Stream' }.freeze

  # for cases where a longer more descriptive key is useful, but can't rely on the title
  #  which may have been changed over time
  def long_key
    LONG_KEYS[key.to_sym]
  end
end
