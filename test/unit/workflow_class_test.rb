require 'test_helper'

class WorkflowClassTest < ActiveSupport::TestCase
  test 'validate uniqueness of workflow class title' do
    c1 = WorkflowClass.new(title: 'A Class', key: 'class1')
    assert c1.save

    c2 = WorkflowClass.new(title: 'A Class', key: 'class2')
    refute c2.valid?
    assert c2.errors.added?(:title, :taken, value: c1.title)
  end

  test 'validate uniqueness of workflow class key' do
    c1 = WorkflowClass.new(title: 'A Class', key: 'class1')
    assert c1.save

    c2 = WorkflowClass.new(title: 'Another Class', key: 'class1')
    refute c2.valid?
    assert c2.errors.added?(:key, :taken, value: c1.key)
  end

  test 'validate workflow class extractor is real' do
    c1 = WorkflowClass.new(title: 'Another Class', key: 'class1', extractor: 'Fish')
    refute c1.valid?
    assert c1.errors.added?(:extractor, 'was not a valid format')
  end

  test 'allow creating a workflow class without an extractor' do
    c1 = WorkflowClass.new(title: 'Custom Type')
    assert c1.valid?
    refute c1.key.blank?
    assert_equal Seek::WorkflowExtractors::Base, c1.extractor_class
  end

  test 'assigns unique keys' do
    c1 = WorkflowClass.create!(title: 'Custom Type')
    c2 = WorkflowClass.create!(title: 'Custom  Type')
    c3 = WorkflowClass.create!(title: 'Custom type')

    assert c1.key.present?
    assert c2.key.present?
    assert c3.key.present?

    assert_not_equal c1.key, c2.key
    assert_not_equal c2.key, c3.key
    assert_not_equal c1.key, c3.key
  end

  test 'extractable boolean and finders' do
    ex = Factory(:cwl_workflow_class)
    un = Factory(:unextractable_workflow_class)

    assert ex.extractable?
    refute un.extractable?

    assert WorkflowClass.extractable.include?(ex)
    refute WorkflowClass.extractable.include?(un)

    refute WorkflowClass.unextractable.include?(ex)
    assert WorkflowClass.unextractable.include?(un)
  end

  test 'ro crate metadata' do
    cwl = Factory(:cwl_workflow_class).ro_crate_metadata
    other = Factory(:unextractable_workflow_class, title: 'My other type', key: nil).ro_crate_metadata

    assert_equal({
                     "@id"=>"#cwl",
                     "@type"=>"ComputerLanguage",
                     "name"=>"Common Workflow Language",
                     "alternateName"=>"CWL",
                     "identifier"=>{"@id"=>"https://w3id.org/cwl/v1.0/"},
                     "url"=>{"@id"=>"https://www.commonwl.org/"}
                 }, cwl)
    assert_equal({"@id"=>"#MyOtherType", "@type"=>"ComputerLanguage", "name"=>"My other type"}, other)
  end
end
