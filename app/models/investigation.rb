class Investigation < ActiveRecord::Base
  
  belongs_to :project
  has_many :studies  

  validates_presence_of :title
  validates_presence_of :project
  validates_uniqueness_of :title

  acts_as_solr(:fields=>[:description,:title]) if SOLR_ENABLED

  def assets
    assets=[]
    studies.each do |study|
      assets=assets | study.sops.collect{|sop| sop.asset}
    end
    return assets
  end

  def assays
    assays=[]
    studies.each do |study|
      assays = assays | study.assays
    end
    return assays
  end

  
end
