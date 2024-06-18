require 'test_helper'

class WorkflowCrateTest < ActiveSupport::TestCase
  test 'conformsTo' do
    crate = ROCrate::WorkflowCrate.new

    ids = crate['conformsTo'].map { |x| x['@id'] }
    assert_includes ids, 'https://w3id.org/ro/crate/1.1'
    assert_includes ids, 'https://w3id.org/workflowhub/workflow-ro-crate/1.0'
  end

  test 'test_suites' do
    crate = ROCrate::WorkflowCrate.new
    assert_empty crate.test_suites
    crate['mentions'] = crate.add_contextual_entity(ROCrate::ContextualEntity.new(crate, '#test_suite', { '@type' => 'TestSuite' })).reference
    assert_equal 1, crate.test_suites.length
    assert_equal '#test_suite', crate.test_suites.first.id

    crate = ROCrate::WorkflowCrate.new
    crate['about'] = [
      crate.add_contextual_entity(ROCrate::ContextualEntity.new(crate, '#test_suite1', { '@type' => 'TestSuite' })).reference,
      crate.add_contextual_entity(ROCrate::ContextualEntity.new(crate, '#test_suite2', { '@type' => 'TestSuite' })).reference
    ]
    assert_equal 2, crate.test_suites.length
    crate['mentions'] = crate.add_contextual_entity(ROCrate::ContextualEntity.new(crate, '#test_suite2', { '@type' => 'TestSuite' })).reference
    assert_equal 2, crate.test_suites.length
    ids = crate.test_suites.map(&:id)
    assert_includes ids, '#test_suite1'
    assert_includes ids, '#test_suite2'
    crate['mentions'] = [crate['mentions'], crate.add_contextual_entity(ROCrate::ContextualEntity.new(crate, '#test_suite3', { '@type' => 'TestSuite' })).reference]
    assert_equal 3, crate.test_suites.length
    ids = crate.test_suites.map(&:id)
    assert_includes ids, '#test_suite1'
    assert_includes ids, '#test_suite2'
    assert_includes ids, '#test_suite3'
  end
end
