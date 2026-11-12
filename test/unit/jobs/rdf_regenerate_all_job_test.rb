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

  test 'rdf jobs run on the rdf queue, which has a single worker with one thread' do
    assert_equal QueueNames::RDF, RdfRegenerateAllJob.queue_name
    assert_equal QueueNames::RDF, RdfGenerationJob.queue_name

    config = ActiveSupport::ConfigurationFile.parse(Rails.root.join('config/queue.yml')).deep_symbolize_keys
    workers = config[Rails.env.to_sym][:workers].select { |worker| Array(worker[:queues]).include?(QueueNames::RDF) }
    assert_equal 1, workers.size
    assert_equal 1, workers.first[:threads]
    assert_equal 1, workers.first[:processes]
  end

end
