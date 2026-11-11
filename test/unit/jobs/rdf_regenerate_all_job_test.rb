require 'test_helper'

class RdfRegenerateAllJobTest < ActiveSupport::TestCase
  test 'queues rdf generation for every rdf capable item' do
    workflow = FactoryBot.create(:workflow)
    person = FactoryBot.create(:person)
    RdfGenerationQueue.delete_all

    RdfRegenerateAllJob.perform_now

    assert RdfGenerationQueue.where(item: workflow).exists?
    assert RdfGenerationQueue.where(item: person).exists?
  end
end
