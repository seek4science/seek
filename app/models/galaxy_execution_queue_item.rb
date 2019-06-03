class GalaxyExecutionQueueItem < ApplicationRecord

  belongs_to :data_file
  belongs_to :sample
  belongs_to :person

  QUEUED=0
  RUNNING=1
  FINISHED=2

end