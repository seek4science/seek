require 'test_helper'

class WorkflowClassTest < ActiveSupport::TestCase
  setup do
    $authorization_checks_disabled = true
  end

  teardown do
    $authorization_checks_disabled = false
  end

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
    c3 = WorkflowClass.create!(title: 'Custom   type')

    assert c1.key.present?
    assert c2.key.present?
    assert c3.key.present?

    assert_not_equal c1.key, c2.key
    assert_not_equal c2.key, c3.key
    assert_not_equal c1.key, c3.key
  end

  test 'extractable boolean and finders' do
    WorkflowClass.destroy_all

    ex = FactoryBot.create(:cwl_workflow_class)
    un = FactoryBot.create(:unextractable_workflow_class)

    assert ex.extractable?
    refute un.extractable?

    assert WorkflowClass.extractable.include?(ex)
    refute WorkflowClass.extractable.include?(un)

    refute WorkflowClass.unextractable.include?(ex)
    assert WorkflowClass.unextractable.include?(un)
  end

  test 'RO-Crate metadata' do
    WorkflowClass.destroy_all

    cwl = FactoryBot.create(:cwl_workflow_class).ro_crate_metadata
    other = FactoryBot.create(:unextractable_workflow_class, title: 'My other type', key: nil).ro_crate_metadata

    assert_equal({
                     "@id"=>"#cwl",
                     "@type"=>"ComputerLanguage",
                     "name"=>"Common Workflow Language",
                     "alternateName"=>"CWL",
                     "identifier"=>{"@id"=>"https://w3id.org/cwl/v1.0/"},
                     "url"=>{"@id"=>"https://www.commonwl.org/"}
                 }, cwl)
    assert_equal({"@id"=>"#my_other_type", "@type"=>"ComputerLanguage", "name"=>"My other type"}, other)
  end

  test 'match from metadata' do
    WorkflowClass.destroy_all

    tav = WorkflowClass.create!(title: 'Taverna Workflow Engine',
                                key: 'TAV',
                                alternate_name: 'Taverna',
                                identifier: 'https://doi.org/10.1093/nar/gkt328',
                                url: 'https://taverna.incubator.apache.org/')

    cwl = FactoryBot.create(:cwl_workflow_class)

    # Match on name
    match = WorkflowClass.match_from_metadata(
        "@id" => "#tavvo",
        "@type" => "ComputerLanguage",
        "name" => "Taverna")

    assert_equal tav, match

    # Match on alt name
    match = WorkflowClass.match_from_metadata(
        "@id" => "#tavvo",
        "@type" => "ComputerLanguage",
        "name" => "Tavvo",
        "alternateName" => "Taverna Workflow Engine")

    assert_equal tav, match

    # Match on identifier
    match = WorkflowClass.match_from_metadata(
        "@id" => "#cwl",
        "@type" => "ComputerLanguage",
        "identifier" => { "@id" => "https://doi.org/10.1093/nar/gkt328" },
        "alternateName" => "blalbalbla ignore me")

    assert_equal tav, match

    # Match on URL
    match = WorkflowClass.match_from_metadata(
        "@id" => "#something",
        "@type" => "ComputerLanguage",
        "name" => "not helpful",
        "url" => { "@id" => "https://taverna.incubator.apache.org/" })

    assert_equal tav, match

    # Match on key
    match = WorkflowClass.match_from_metadata("@id" => "#tav")

    assert_equal tav, match

    # Match priority for ambiguous lookups
    match = WorkflowClass.match_from_metadata(
        "@id" => "#taverna",
        "name" => "Taverna",
        "@type" => "ComputerLanguage",
        "identifier" => { "@id" => "https://w3id.org/cwl/v1.0/" },
        "alternateName" => "blalbalbla ignore me")

    assert_equal cwl, match

    # No match
    match = WorkflowClass.match_from_metadata(
        "@id" => "#booboo",
        "name" => "Abloobloobloo",
        "@type" => "ComputerLanguage",
        "alternateName" => "blalbalbla ignore me")

    assert_nil match

    # Match on string URL
    match = WorkflowClass.match_from_metadata("url" => "https://www.commonwl.org/",
                                              "@type" => "ComputerLanguage")

    assert_equal cwl, match
  end
end
