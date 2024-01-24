class AssayClass < ApplicationRecord
  # this returns an instance of AssayClass according to one of the constants defined in seek/isa/assay_class.rb
  # if there is not a match nil is returned
  def self.for_type(type)
    AssayClass.find_by(key: type)
  end

  def self.experimental
    for_type(Seek::ISA::AssayClass::EXP)
  end

  def self.modelling
    for_type(Seek::ISA::AssayClass::MODEL)

  end

  def self.assay_stream
    for_type(Seek::ISA::AssayClass::STREAM)
  end

  def is_modelling?
    key == Seek::ISA::AssayClass::MODEL
  end

  def is_experimental?
    key == Seek::ISA::AssayClass::EXP
  end

  def is_assay_stream?
    key == Seek::ISA::AssayClass::STREAM
  end

  # for cases where a longer more descriptive key is useful, but can't rely on the title
  #  which may have been changed over time
  def long_key
    { 'EXP': 'Experimental Assay', 'MODEL': 'Modelling Analysis', 'STREAM': 'Assay Stream' }[key.to_sym]
  end
end
