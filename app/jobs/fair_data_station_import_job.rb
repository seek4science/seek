class FairDataStationImportJob < TaskJob
  queue_as QueueNames::SAMPLES

  attr_reader :extractor
  def perform(fair_data_station_upload)

  end

  def task
    arguments[0].fair_data_station_import_task
  end

  def timelimit
    30.minutes
  end
end
