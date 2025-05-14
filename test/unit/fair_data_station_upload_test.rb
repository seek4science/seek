require 'test_helper'

class FairDataStationUploadTest < ActiveSupport::TestCase

  test 'validate' do
    person = FactoryBot.create(:person)
    item = FairDataStationUpload.new(contributor: person, project: person.projects.first, content_blob: FactoryBot.create(:content_blob))

    assert item.valid?

    item.contributor = nil
    refute item.valid?
    item.contributor = person

    item.project = nil
    refute item.valid?
    item.project = FactoryBot.create(:project)
    refute item.valid?
    item.project = person.projects.first

    item.content_blob = nil
    refute item.valid?
  end
end