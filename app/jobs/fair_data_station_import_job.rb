class FairDataStationImportJob < TaskJob
  queue_as QueueNames::SAMPLES

  attr_reader :extractor

  def perform(fair_data_station_upload)
    blob = fair_data_station_upload.content_blob
    person = fair_data_station_upload.contributor
    project = fair_data_station_upload.project
    policy = fair_data_station_upload.policy
    fair_data_station_inv = Seek::FairDataStation::Reader.new.parse_graph(blob.file_path).first
    raise "Unable to find an #{I18n.t('investigation')} in the FAIR Data Station file" unless fair_data_station_inv

    investigation = Seek::FairDataStation::Writer.new.construct_isa(fair_data_station_inv, person, [project], policy)
    User.with_current_user(person) do
      investigation.save!
    end
    fair_data_station_upload.investigation = investigation
    fair_data_station_upload.investigation_external_identifier = investigation.external_identifier
    fair_data_station_upload.save!
  end

  def task
    arguments[0].import_task
  end

  def timelimit
    30.minutes
  end
end
