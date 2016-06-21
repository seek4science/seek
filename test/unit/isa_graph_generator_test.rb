require 'test_helper'

class IsaGraphGeneratorTest < ActiveSupport::TestCase

  test 'investigation with studies and assays' do
    investigation = Factory(:investigation)
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study)

    generator = Seek::IsaGraphGenerator.new(investigation)

    # Shallow
    shallow_result = generator.generate

    assert_equal 2, shallow_result[:nodes].length
    assert_equal 1, shallow_result[:edges].length

    assert_includes shallow_result[:nodes], investigation
    assert_includes shallow_result[:nodes], study
    assert_not_includes shallow_result[:nodes], assay

    assert_includes shallow_result[:edges], [investigation, study]

    # Deep
    deep_result = generator.generate(deep: true)

    assert_equal 3, deep_result[:nodes].length
    assert_equal 2, deep_result[:edges].length

    assert_includes deep_result[:nodes], investigation
    assert_includes deep_result[:nodes], study
    assert_includes deep_result[:nodes], assay

    assert_includes deep_result[:edges], [investigation, study]
    assert_includes deep_result[:edges], [study, assay]
  end

  test 'shows sibling assets' do
    assay = Factory(:assay)
    data_file = Factory(:data_file)
    model = Factory(:model)
    sop = Factory(:sop)

    AssayAsset.create(assay: assay, asset: data_file)
    AssayAsset.create(assay: assay, asset: model)
    AssayAsset.create(assay: assay, asset: sop)

    result = Seek::IsaGraphGenerator.new(data_file).generate(include_parents: true)

    assert_equal 4, result[:nodes].length
    assert_equal 3, result[:edges].length

    assert_includes result[:nodes], assay
    assert_includes result[:nodes], data_file
    assert_includes result[:nodes], model
    assert_includes result[:nodes], sop

    assert_includes result[:edges], [assay, data_file]
    assert_includes result[:edges], [assay, model]
    assert_includes result[:edges], [assay, sop]
  end


end