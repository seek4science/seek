FactoryBot.define do

  factory(:fair_data_station_upload, class: FairDataStationUpload) do

    purpose{ :import }
    policy { FactoryBot.create(:private_policy) }
    content_blob { FactoryBot.build(:fair_data_station_test_case_content_blob)}

    after(:build) do |resource|
      if resource.project.blank?
        resource.project = FactoryBot.create(:project)
      end
      if resource.contributor.blank?
        resource.contributor = FactoryBot.create(:person, project: resource.project)
      end
    end

  end


end