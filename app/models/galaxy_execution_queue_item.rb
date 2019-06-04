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
    if history_id
      URI.join(person.galaxy_instance,"/histories/view","?id=#{history_id}").to_s
    end
  end

end