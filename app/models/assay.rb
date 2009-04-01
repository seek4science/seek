class Assay < ActiveRecord::Base

  has_and_belongs_to_many :experiments
  belongs_to :assay_type
  
  def description
    type=assay_type.nil? ? "No type" : assay_type.title
    
    "#{title} (#{type})"
  end

end
