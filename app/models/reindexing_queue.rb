class ReindexingQueue < ApplicationRecord
  include ResourceQueue

  def self.job_class
    ReindexingJob
  end
end
