class Synonym < ApplicationRecord
  has_many :studied_factor_links, :as => :substance
  has_many :experimental_condition_links, :as => :substance
  belongs_to :substance, :polymorphic => true
  validates_presence_of :name, :substance

  alias_attribute :title,:name
  
  def data_files
    studied_factor_links.collect{|sf| sf.studied_factor.data_file}
  end

  def sops
    experimental_condition_links.collect{|ec| ec.experimental_condition.sop}
  end

  def studied_factors
    studied_factor_links.collect{|sfl| sfl.studied_factor}
  end

  def experimental_conditions
    experimental_condition_links.collect{|ecl| ecl.experimental_condition}
  end

end

