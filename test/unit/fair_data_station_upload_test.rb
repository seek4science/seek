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


end