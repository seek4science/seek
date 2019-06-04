class GalaxyExecutionQueueItem < ApplicationRecord

  belongs_to :data_file
  belongs_to :sample
  belongs_to :person
  belongs_to :workflow

  QUEUED=0
  RUNNING=1
  FINISHED=20
  FAILED=99

  STATUS = {
      QUEUED => "queued",
      RUNNING => "running",
      FINISHED => "finished",
      FAILED => "failed"
  }.freeze

  def status_name
    STATUS[status]
  end

  def history_url

  end

end