class Assay < ActiveRecord::Base

  has_many :experiments
  belongs_to :topic
  belongs_to :assay_type
  
end
