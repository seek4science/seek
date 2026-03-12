class FairDataStationUpdateJob < TaskJob
  queue_as QueueNames::SAMPLES

  attr_reader :extractor

  def perform(fair_data_station_upload)
    blob = fair_data_station_upload.content_blob
    person = fair_data_station_upload.contributor
    investigation = fair_data_station_upload.investigation

    fair_data_station_inv = Seek::FairDataStation::Reader.new.parse_graph(blob.file_path).first
    raise "Unable to find an #{I18n.t('investigation')} in the FAIR Data Station file" unless fair_data_station_inv

    User.with_current_user(person) do
      Investigation.transaction do
        investigation = Seek::FairDataStation::Writer.new.update_isa(investigation, fair_data_station_inv, person,
                                                                     investigation.projects, investigation.policy)
        investigation.save!
      end
    end
  end

  def task
    arguments[0].update_task
  end

  def timelimit
    30.minutes
  end
end
