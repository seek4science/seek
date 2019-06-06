class GalaxyExecutionQueueItem < ApplicationRecord

  attr_accessor :outputs

  belongs_to :data_file
  belongs_to :sample
  belongs_to :person
  belongs_to :workflow
  belongs_to :assay

  QUEUED=0
  RUNNING=1
  CREATING_RESULTS=2
  FINISHED=20
  FAILED=99

  STATUS = {
      QUEUED => "queued",
      RUNNING => "running",
      CREATING_RESULTS => "storing",
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

  def error?
    error.present?
  end

  # def outputs
  #   return [] unless output_json
  #   JSON.parse(output_json)
  # end

end