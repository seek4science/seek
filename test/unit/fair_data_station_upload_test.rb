require 'test_helper'

class FairDataStationUploadTest < ActiveSupport::TestCase

  test 'validate' do
    person = FactoryBot.create(:person)
    item = FairDataStationUpload.new(contributor: person, project: person.projects.first,
                                     content_blob: FactoryBot.create(:content_blob), purpose: :import)

    assert item.valid?

    item.contributor = nil
    refute item.valid?
    item.contributor = person
    assert item.valid?

    item.project = nil
    refute item.valid?
    item.project = FactoryBot.create(:project)
    refute item.valid?
    item.project = person.projects.first
    assert item.valid?

    item.purpose = nil
    refute item.valid?
    item.purpose = :update
    assert item.valid?

    item.content_blob = nil
    refute item.valid?
  end

  test 'for_project_and_contributor scope' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    person2 = FactoryBot.create(:person)
    project2 = person2.projects.first
    up1 = FactoryBot.create(:fair_data_station_upload, project: project, contributor: person)
    up2 = FactoryBot.create(:fair_data_station_upload, project: project2, contributor: person2)
    up3 = FactoryBot.create(:fair_data_station_upload)

    assert_equal [up1], FairDataStationUpload.for_project_and_contributor(project, person)
    assert_empty FairDataStationUpload.for_project_and_contributor(project2, person)
    assert_empty FairDataStationUpload.for_project_and_contributor(project, person2)
    assert_equal [up2], FairDataStationUpload.for_project_and_contributor(project2, person2)
  end


end