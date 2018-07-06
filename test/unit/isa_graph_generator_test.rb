require 'test_helper'

class IsaGraphGeneratorTest < ActiveSupport::TestCase
  test 'investigation with studies and assays' do
    assay = Factory(:assay)
    study = assay.study
    investigation = assay.investigation
    assay2 = Factory(:assay, contributor: assay.contributor, study: study)

    generator = Seek::IsaGraphGenerator.new(investigation)

    # Shallow
    shallow_result = generator.generate

    assert_equal 2, shallow_result[:nodes].map(&:object).length  # Investigation, Study
    assert_equal 1, shallow_result[:edges].length

    assert_includes shallow_result[:nodes].map(&:object), investigation
    assert_includes shallow_result[:nodes].map(&:object), study
    assert_not_includes shallow_result[:nodes].map(&:object), assay
    assert_not_includes shallow_result[:nodes].map(&:object), assay2

    assert_includes shallow_result[:edges], [investigation, study]

    # Deep
    deep_result = generator.generate(depth: nil)

    assert_equal 4, deep_result[:nodes].map(&:object).length # Investigation, Study, 2 Assays
    assert_equal 3, deep_result[:edges].length

    assert_includes deep_result[:nodes].map(&:object), investigation
    assert_includes deep_result[:nodes].map(&:object), study
    assert_includes deep_result[:nodes].map(&:object), assay
    assert_includes deep_result[:nodes].map(&:object), assay2

    assert_includes deep_result[:edges], [investigation, study]
    assert_includes deep_result[:edges], [study, assay]
    assert_includes deep_result[:edges], [study, assay2]
  end

  test 'sibling assets are collapsed' do
    assay = Factory(:assay)
    data_file = Factory(:data_file, policy: Factory(:publicly_viewable_policy))
    model = Factory(:model, policy: Factory(:publicly_viewable_policy))
    sop = Factory(:sop, policy: Factory(:publicly_viewable_policy))

    User.with_current_user(assay.contributor.user) do
      AssayAsset.create!(assay: assay, asset: data_file)
      AssayAsset.create!(assay: assay, asset: model)
      AssayAsset.create!(assay: assay, asset: sop)
    end

    result = Seek::IsaGraphGenerator.new(data_file).generate(parent_depth: nil)

    assert_equal 5, result[:nodes].length # Project, Investigation, Study, Assay, DataFile
    assert_equal 4, result[:edges].length

    assert_includes result[:nodes].map(&:object), assay
    assert_includes result[:nodes].map(&:object), data_file
    assert_not_includes result[:nodes].map(&:object), model
    assert_not_includes result[:nodes].map(&:object), sop
    assert_equal 3, result[:nodes].detect { |n| n.object == assay }.child_count
    assert_includes result[:nodes].map(&:object), assay.study
    assert_includes result[:nodes].map(&:object), assay.study.investigation
    assert_includes result[:nodes].map(&:object), assay.study.investigation.projects.first

    assert_includes result[:edges], [assay, data_file]
    assert_includes result[:edges], [assay.study, assay]
  end

  test "does not show sibling's children" do
    assay = Factory(:assay)
    study = assay.study
    sibling_assay = Factory(:assay, title: 'sibling', contributor: assay.contributor, study: study)
    data_file = Factory(:data_file, title: 'child', policy: Factory(:publicly_viewable_policy))
    nephew_model = Factory(:model, title: 'nephew', policy: Factory(:publicly_viewable_policy))
    niece_sop = Factory(:sop, title: 'niece', policy: Factory(:publicly_viewable_policy))

    User.with_current_user(assay.contributor.user) do
      AssayAsset.create!(assay: assay, asset: data_file)
      AssayAsset.create!(assay: sibling_assay, asset: nephew_model)
      AssayAsset.create!(assay: sibling_assay, asset: niece_sop)
    end

    result = Seek::IsaGraphGenerator.new(assay).generate(parent_depth: nil, sibling_depth: 1)

    assert_equal 6, result[:nodes].length # Project, Investigation, Study, 2 Assays, DataFile
    assert_equal 5, result[:edges].length

    assert_includes result[:nodes].map(&:object), assay
    assert_includes result[:nodes].map(&:object), data_file
    assert_includes result[:nodes].map(&:object), sibling_assay
    assert_equal 2, result[:nodes].detect { |n| n.object == sibling_assay }.child_count
    assert_not_includes result[:nodes].map(&:object), nephew_model
    assert_not_includes result[:nodes].map(&:object), niece_sop
  end

  test "can show sibling's children" do
    assay = Factory(:assay)
    study = assay.study
    sibling_assay = Factory(:assay, title: 'sibling', contributor: assay.contributor, study: study)
    data_file = Factory(:data_file, title: 'child', policy: Factory(:publicly_viewable_policy))
    nephew_model = Factory(:model, title: 'nephew', policy: Factory(:publicly_viewable_policy))
    niece_sop = Factory(:sop, title: 'niece', policy: Factory(:publicly_viewable_policy))

    User.with_current_user(assay.contributor.user) do
      AssayAsset.create!(assay: assay, asset: data_file)
      AssayAsset.create!(assay: sibling_assay, asset: nephew_model)
      AssayAsset.create!(assay: sibling_assay, asset: niece_sop)
    end

    result = Seek::IsaGraphGenerator.new(assay).generate(parent_depth: nil, sibling_depth: nil)

    assert_equal 8, result[:nodes].length # Project, Investigation, Study, 2 Assays, DataFile, Model, Sop
    assert_equal 7, result[:edges].length

    assert_includes result[:nodes].map(&:object), assay
    assert_includes result[:nodes].map(&:object), data_file
    assert_includes result[:nodes].map(&:object), sibling_assay
    assert_includes result[:nodes].map(&:object), nephew_model
    assert_includes result[:nodes].map(&:object), niece_sop
  end

  test 'maintains child asset count even if the are not included in graph' do
    assay = Factory(:assay)
    study = assay.study
    investigation = assay.investigation
    assay2 = Factory(:assay, contributor: assay.contributor, study: study)
    generator = Seek::IsaGraphGenerator.new(investigation)
    result = generator.generate

    study_node = result[:nodes].detect { |n| n.object == study }

    assert_equal 2, study_node.child_count
    assert_not_includes result[:nodes].map(&:object), assay
    assert_not_includes result[:nodes].map(&:object), assay2
  end

  test 'counts child assets of all ancestors' do
    person = Factory(:person)
    project = person.projects.first
    investigation = Factory(:investigation, contributor: person, projects: [project])
    investigation2 = Factory(:investigation, contributor: person, projects: [project])
    investigation3 = Factory(:investigation, contributor: person, projects: [project])
    study = Factory(:study, contributor: person, investigation: investigation)
    study2 = Factory(:study, contributor: person, investigation: investigation)
    study3 = Factory(:study, contributor: person, investigation: investigation)
    study4 = Factory(:study, contributor: person, investigation: investigation)
    assay = Factory(:assay, contributor: person, study: study)

    generator = Seek::IsaGraphGenerator.new(assay)
    result = generator.generate(parent_depth: nil)

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
