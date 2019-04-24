class SampleResourceLink < ApplicationRecord

  belongs_to :sample
  belongs_to :resource, polymorphic: true

end
