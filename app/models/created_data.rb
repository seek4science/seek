class CreatedData < ActiveRecord::Base

  has_many :data_files
  belongs_to :assay
  belongs_to :person

end
