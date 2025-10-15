FactoryBot.define do

  factory(:fair_data_station_upload, class: FairDataStationUpload) do

    purpose { :import }
    policy { FactoryBot.create(:private_policy) }
    content_blob { FactoryBot.build(:fair_data_station_test_case_content_blob)}
    investigation_external_identifier { 'seek-test-investigation' }

    after(:build) do |resource|
      if resource.project.blank?
        resource.project = FactoryBot.create(:project)
      end
      if resource.contributor.blank?
        resource.contributor = FactoryBot.create(:person, project: resource.project)
      end
    end

  end

  factory(:invalid_fair_data_station_upload, parent: :fair_data_station_upload) do
    content_blob { FactoryBot.build(:copasi_content_blob)}
  end

  factory(:update_fair_data_station_upload, class: FairDataStationUpload) do
    purpose { :update }
    content_blob { FactoryBot.build(:fair_data_station_test_case_modified_content_blob)}
    investigation_external_identifier { 'seek-test-investigation' }
    after(:build) do |resource|
      if resource.contributor.blank?
        resource.contributor = FactoryBot.create(:person)
      end
      if resource.investigation.blank?
        resource.investigation = FactoryBot.create(:investigation, contributor: resource.contributor, projects: [resource.contributor.projects.first])
      end
    end
  end

  factory(:invalid_update_fair_data_station_upload, parent: :update_fair_data_station_upload) do
    content_blob { FactoryBot.build(:fair_data_station_test_case_invalid_content_blob)}
  end

end