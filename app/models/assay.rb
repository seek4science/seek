class Assay < ActiveRecord::Base

  has_many :experiments
  belongs_to :topic
  belongs_to :assay_type
  
  def description
    type=assay_type.nil? ? "No type" : assay_type.title
    
    "#{title} (#{type})"
  end

end
