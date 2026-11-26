require 'test_helper'
require 'minitest/mock'

class RdfRegenerateAllJobTest < ActiveSupport::TestCase
  test 'queues rdf generation for every rdf capable item' do
    project = FactoryBot.create(:project)
    person = FactoryBot.create(:person)
    sop = FactoryBot.create(:sop)
    RdfGenerationQueue.delete_all

    assert_enqueued_jobs(1, only: RdfGenerationJob) do
      RdfRegenerateAllJob.perform_now
    end

    [project, person, sop].each do |item|
      entry = RdfGenerationQueue.find_by(item: item)
      assert entry, "#{item.class.name} should be queued"
      refute entry.refresh_dependents
    end
    assert_equal Seek::Util.rdf_capable_types.sum(&:count), RdfGenerationQueue.count
  end

  test 'clears the triple store' do
    cleared = false
    Seek::Rdf::RdfRepository.instance.stub(:clear_all, -> { cleared = true }) do
      RdfRegenerateAllJob.perform_now
    end

    assert cleared
  end
end
