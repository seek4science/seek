class Genotype < ActiveRecord::Base
  belongs_to :strain
  belongs_to :gene
  belongs_to :modification

  accepts_nested_attributes_for :gene#,:reject_if => proc { |a| a['title'].blank? }
  accepts_nested_attributes_for :modification
  validates_presence_of :gene

end
