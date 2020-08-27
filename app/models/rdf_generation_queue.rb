class RdfGenerationQueue < ApplicationRecord
  include ResourceQueue

  def self.job_class
    RdfGenerationJob
  end
end
