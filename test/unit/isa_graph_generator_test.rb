require 'test_helper'

class IsaGraphGeneratorTest < ActiveSupport::TestCase

  test 'investigation with studies and assays' do
    investigation = Factory(:investigation)
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study)

    generator = Seek::IsaGraphGenerator.new(investigation)

    # Shallow
    shallow_result = generator.generate

    assert_equal 3, shallow_result[:nodes].length
    assert_equal 2, shallow_result[:edges].length

    assert_includes shallow_result[:nodes], investigation.projects.first
    assert_includes shallow_result[:nodes], investigation
    assert_includes shallow_result[:nodes], study
    assert_not_includes shallow_result[:nodes], assay

    assert_includes shallow_result[:edges], [investigation.projects.first, investigation]
    assert_includes shallow_result[:edges], [investigation, study]

    # Deep
    deep_result = generator.generate(deep: true)

    assert_equal 4, deep_result[:nodes].length
    assert_equal 3, deep_result[:edges].length

    assert_includes deep_result[:nodes], investigation.projects.first
    assert_includes deep_result[:nodes], investigation
    assert_includes deep_result[:nodes], study
    assert_includes deep_result[:nodes], assay

    assert_includes deep_result[:edges], [investigation.projects.first, investigation]
    assert_includes deep_result[:edges], [investigation, study]
    assert_includes deep_result[:edges], [study, assay]
  end


end