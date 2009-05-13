class CreatedData < ActiveRecord::Base

  belongs_to :data_file
  belongs_to :assay
  belongs_to :person

  validates_presence_of :data_file
  validates_associated :assay
  validates_presence_of :person

end
