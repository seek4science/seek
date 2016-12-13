class SampleResourceLink < ActiveRecord::Base

  belongs_to :sample
  belongs_to :resource, polymorphic: true

end
