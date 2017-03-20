require 'test_helper'

class IsaGraphGeneratorTest < ActiveSupport::TestCase
  test 'investigation with studies and assays' do
    investigation = Factory(:investigation)
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study)
    assay2 = Factory(:assay, study: study)

    generator = Seek::IsaGraphGenerator.new(investigation)

    # Shallow
    shallow_result = generator.generate

    assert_equal 2, shallow_result[:nodes].map(&:object).length

    assert_equal 1, shallow_result[:edges].length

    assert_includes shallow_result[:nodes].map(&:object), investigation
    assert_includes shallow_result[:nodes].map(&:object), study
    assert_not_includes shallow_result[:nodes].map(&:object), assay
    assert_not_includes shallow_result[:nodes].map(&:object), assay2

    assert_includes shallow_result[:edges], [investigation, study]

    # Deep
    deep_result = generator.generate(deep: true)

    assert_equal 4, deep_result[:nodes].map(&:object).length
    assert_equal 3, deep_result[:edges].length

    assert_includes deep_result[:nodes].map(&:object), investigation
    assert_includes deep_result[:nodes].map(&:object), study
    assert_includes deep_result[:nodes].map(&:object), assay
    assert_includes deep_result[:nodes].map(&:object), assay2

    assert_includes deep_result[:edges], [investigation, study]
    assert_includes deep_result[:edges], [study, assay]
    assert_includes deep_result[:edges], [study, assay2]
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

    assert_equal 7, result[:nodes].length
    assert_equal 6, result[:edges].length

    assert_includes result[:nodes].map(&:object), assay
    assert_includes result[:nodes].map(&:object), data_file
    assert_includes result[:nodes].map(&:object), model
    assert_includes result[:nodes].map(&:object), sop
    assert_includes result[:nodes].map(&:object), assay.study
    assert_includes result[:nodes].map(&:object), assay.study.investigation
    assert_includes result[:nodes].map(&:object), assay.study.investigation.projects.first

    assert_includes result[:edges], [assay, data_file]
    assert_includes result[:edges], [assay, model]
    assert_includes result[:edges], [assay, sop]
  end

  test "does not show sibling's children" do
    investigation = Factory(:investigation)
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study)
    sibling_assay = Factory(:assay, study: study)
    data_file = Factory(:data_file)
    nephew_model = Factory(:model)
    niece_sop = Factory(:sop)

    AssayAsset.create(assay: assay, asset: data_file)
    AssayAsset.create(assay: sibling_assay, asset: nephew_model)
    AssayAsset.create(assay: sibling_assay, asset: niece_sop)

    result = Seek::IsaGraphGenerator.new(assay).generate(include_parents: true)

    assert_equal 6, result[:nodes].length
    assert_equal 5, result[:edges].length

    assert_includes result[:nodes].map(&:object), assay
    assert_includes result[:nodes].map(&:object), data_file
    assert_includes result[:nodes].map(&:object), sibling_assay
    assert_not_includes result[:nodes].map(&:object), nephew_model
  end

  test "show's sibling's child if only one" do
    investigation = Factory(:investigation)
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study)
    sibling_assay = Factory(:assay, study: study)
    data_file = Factory(:data_file)
    nephew_model = Factory(:model)

    AssayAsset.create(assay: assay, asset: data_file)
    AssayAsset.create(assay: sibling_assay, asset: nephew_model)

    result = Seek::IsaGraphGenerator.new(assay).generate(include_parents: true)

    assert_equal 7, result[:nodes].length
    assert_equal 6, result[:edges].length

    assert_includes result[:nodes].map(&:object), assay
    assert_includes result[:nodes].map(&:object), data_file
    assert_includes result[:nodes].map(&:object), sibling_assay
    assert_includes result[:nodes].map(&:object), nephew_model
  end

  test 'maintains child asset count even if the are not included in graph' do
    investigation = Factory(:investigation)
    study = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study)
    assay2 = Factory(:assay, study: study)
    generator = Seek::IsaGraphGenerator.new(investigation)
    result = generator.generate

    study_node = result[:nodes].detect { |n| n.object == study }

    assert_equal 2, study_node.child_count
    assert_not_includes result[:nodes].map(&:object), assay
    assert_not_includes result[:nodes].map(&:object), assay2
  end

  test 'counts child assets of all ancestors' do
    project = Factory(:project)
    investigation = Factory(:investigation, projects: [project])
    investigation2 = Factory(:investigation, projects: [project])
    investigation3 = Factory(:investigation, projects: [project])
    study = Factory(:study, investigation: investigation)
    study2 = Factory(:study, investigation: investigation)
    study3 = Factory(:study, investigation: investigation)
    study4 = Factory(:study, investigation: investigation)
    assay = Factory(:assay, study: study)

    generator = Seek::IsaGraphGenerator.new(assay)
    result = generator.generate(include_parents: true)

    investigation_node = result[:nodes].detect { |n| n.object == investigation }
    project_node = result[:nodes].detect { |n| n.object == project }

    assert_equal 4, investigation_node.child_count
    assert_equal 3, project_node.child_count

    assert_not_includes result[:nodes].map(&:object), investigation2
    assert_not_includes result[:nodes].map(&:object), investigation3
    assert_not_includes result[:nodes].map(&:object), study2
    assert_not_includes result[:nodes].map(&:object), study3
    assert_not_includes result[:nodes].map(&:object), study4
  end
end
