class Compound < ActiveRecord::Base
  has_many :studied_factor_links, :as => :substance
  has_many :experimental_condition_links,:as => :substance
  has_many :synonyms, :as => :substance
  has_many :mapping_links, :as => :substance

  alias_attribute :title,:name

  validates_presence_of :name
  validates_uniqueness_of :name
  
  def mappings
    mapping_links.collect{|ml| ml.mapping}
  end

  def data_files
    studied_factor_links.collect{|sf| sf.studied_factor.data_file}
  end
  
  def sops
    experimental_condition_links.collect{|ec| ec.experimental_condition.sop}
  end

end
