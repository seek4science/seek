require 'test_helper'

class ISAExporterTest < ActionController::TestCase
  
  def setup
    @seek_sop_type = SampleAttributeType.find_by(base_type: Seek::Samples::BaseType::SEEK_SOP) || FactoryBot.create(:sop_sample_attribute_type)
  end

  test 'find sample origin' do
    current_user = FactoryBot.create(:user)
    controller = ISAExporter::Exporter.new(FactoryBot.create(:investigation), current_user)
    project = FactoryBot.create(:project)

    type_1 = FactoryBot.create(:simple_sample_type, project_ids: [project.id])
    type_2 = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    type_2.sample_attributes.last.linked_sample_type = type_1
    type_2.save!

    type_3 = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    type_3.sample_attributes.last.linked_sample_type = type_2
    type_3.save!

    type_4 = FactoryBot.create(:multi_linked_sample_type, project_ids: [project.id])
    type_4.sample_attributes.last.linked_sample_type = type_3
    type_4.save!

    # Create Samples
    parent =
      FactoryBot.create :sample,
              title: 'PARENT 1',
              sample_type: type_1,
              project_ids: [project.id],
              policy: FactoryBot.create(:public_policy),
              data: {
          the_title: 'PARENT 1'
              }

    child_1 = Sample.new(sample_type: type_2, project_ids: [project.id], policy:FactoryBot.create(:public_policy))
    child_1.set_attribute_value(:patient, [parent.id])
    child_1.set_attribute_value(:title, 'CHILD 1')
    child_1.save!

    child_2 = Sample.new(sample_type: type_3, project_ids: [project.id], policy:FactoryBot.create(:public_policy))
    child_2.set_attribute_value(:patient, [child_1.id])
    child_2.set_attribute_value(:title, 'CHILD 2')
    child_2.save!

    child_3 = Sample.new(sample_type: type_4, project_ids: [project.id], policy:FactoryBot.create(:public_policy))
    child_3.set_attribute_value(:patient, [child_2.id])
    child_3.set_attribute_value(:title, 'CHILD 3')
    child_3.save!

    assert_equal [parent.id], controller.send(:find_sample_origin, [child_1], 0)
    assert_equal [parent.id], controller.send(:find_sample_origin, [child_2], 0)
    assert_equal [parent.id], controller.send(:find_sample_origin, [child_3], 0)
    assert_equal [child_1.id], controller.send(:find_sample_origin, [child_3], 1) # 0: source, 1: sample

    # Create another parent for child 1
    parent_2 =
      FactoryBot.create :sample,
              title: 'PARENT 2',
              sample_type: type_1,
              project_ids: [project.id],
              policy:FactoryBot.create(:public_policy),
              data: {
          the_title: 'PARENT 2'
              }
    disable_authorization_checks do
      child_1.set_attribute_value(:patient, [parent.id, parent_2.id])
      child_1.save!
    end

    child_3.reload
    assert_equal [parent.id, parent_2.id], controller.send(:find_sample_origin, [child_3], 0)
    assert_equal [child_1.id], controller.send(:find_sample_origin, [child_3], 1)

    # Create another parent for child 2
    child_2_another_parent = Sample.new(sample_type: type_2, project_ids: [project.id])
    child_2_another_parent.set_attribute_value(:patient, [parent.id])
    child_2_another_parent.set_attribute_value(:title, 'CHILD 2 ANOTHER PARENT')
    child_2_another_parent.save!

    disable_authorization_checks do
      child_2.set_attribute_value(:patient, [child_1.id, child_2_another_parent.id])
      child_2.save!
    end

    child_3.reload
    assert_equal [child_1.id, child_2_another_parent.id], controller.send(:find_sample_origin, [child_3], 1)
  end

  test 'should export registered sops correctly' do
    person = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, contributor: person, projects: [person.projects.first], is_isa_json_compliant: true)
    sample_collection_sop = FactoryBot.create(:sop, contributor: person, title: 'Sample collection protocol', projects: [investigation.projects.first])
    study = FactoryBot.create(:isa_json_compliant_study, contributor: person, investigation: investigation, sops: [sample_collection_sop])

    # Create sources
    source_sample_type = study.sample_types.first
    (0..10).each do |i|
      FactoryBot.create(:sample, title: "Source #{i}", contributor: person, sample_type: source_sample_type, project_ids: [study.projects.first.id],
                        data: { 'Source Name': "Source #{i}", 'Source Characteristic 1': 'source 1 characteristic 1', 'Source Characteristic 2': 'Bramley' })
    end

    sample_collection_sample_type = study.sample_types.last
    sample_collection_sample_type.sample_attributes.detect { |sa| sa.isa_tag&.isa_protocol? }.update_column('sample_attribute_type_id', @seek_sop_type.id)
    (0..10).each do |i|
      FactoryBot.create(:sample, title: "Sample #{i}", contributor: person, sample_type: sample_collection_sample_type, project_ids: [study.projects.first.id],
                                 data: { 'Sample Name': "Sample #{i}", 'sample collection': sample_collection_sop, Input: "Source #{i}", 'sample characteristic 1': 'value sample 1', 'sample collection parameter value 1': 'value 1' })
    end

    assay_stream = FactoryBot.create(:complete_assay_stream, study: study, contributor: person, sample_collection_sample_type: sample_collection_sample_type)

    pre_treatment_assay = assay_stream.child_assays.detect { |assay| assay.title.include? "Pre-treatment" }
    pre_treatment_sample_type = pre_treatment_assay.sample_type
    0.upto(10) do |i|
      FactoryBot.create(:sample, title: "Pre-treatment #{i}", contributor: person, sample_type: pre_treatment_sample_type, project_ids: [study.projects.first.id],
                         data: { 'Extract Name': "Pre-treatment #{i}", Input: "Sample #{i}", 'Protocol Assay 1': "Pre-treatment protocol", 'other material characteristic 1': "Pre-treatment #{i} characteristic 1", 'Assay 1 parameter value 1': "Pre-treatment #{i} Parameter value 1" })
    end

    extraction_assay = assay_stream.child_assays.detect { |assay| assay.title.include? "Extraction" }
    extraction_assay_sample_type = extraction_assay.sample_type
    0.upto(10) do |i|
      FactoryBot.create(:sample, title: "Extraction #{i}", contributor: person, sample_type: extraction_assay_sample_type, project_ids: [study.projects.first.id],
                         data: { 'Extract Name': "Extract #{i}", Input: "Pre-treatment #{i}", 'Protocol Assay 1': "Extraction protocol", 'other material characteristic 1': "Extract #{i} characteristic 1", 'Assay 1 parameter value 1': "Extract #{i} Parameter value 1" })
    end

    measurement_assay = assay_stream.child_assays.detect { |assay| assay.title.include? "Measurement" }
    measurement_assay_sample_type = measurement_assay.sample_type
    0.upto(10) do |i|
      protocol_name = i%3 == 0 ? "Measurement protocol 1" : "Measurement protocol 2"
      FactoryBot.create(:sample, title: "Measurement #{i}", contributor: person, sample_type: measurement_assay_sample_type, project_ids: [study.projects.first.id],
                         data: { 'File Name': "Measurement #{i}", Input: "Extract #{i}", 'Protocol Assay 2': protocol_name, 'Assay 2 parameter value 1': "Measurement #{i} Parameter 1", 'Data file comment 1': "Measurement #{i} comment 1" })
    end

    isa = JSON.parse(ISAExporter::Exporter.new(investigation, person.user).export)
    assert_not_nil isa

    # Check the number of studies
    assert_equal isa['studies'].count, 1

    # Check the number of assay streams
    assert_equal isa['studies'][0]['assays'].count, 1

    # check the study protocols
    # Study holds a registered SOP as protocol. All samples use the "Sample collection protocol".
    # The pre-treatment assay has free text to describe the protocol. All samples use the "Pre-treatment protocol".
    # The extraction assay has free text to describe the protocol. All samples use the "Extraction protocol".
    # The measurement assay has free text to describe the protocol. Some samples use the "Measurement protocol 1", while others use "Measurement protocol 2".
    # This gives a total of 5 protocols.
    protocols = isa['studies'][0]['protocols']
    assert_equal protocols.count, 5

    # check the parameters
    parameter_attributes = [sample_collection_sample_type, pre_treatment_sample_type, extraction_assay_sample_type, measurement_assay_sample_type].map do |sample_type|
       sample_type.sample_attributes.select { |sa| sa.isa_tag&.isa_parameter_value? }.map(&:title)
    end.flatten.compact.uniq
    isa_parameters = protocols.map { |protocol| protocol['parameters'] }.flatten.compact.map { |parameter| parameter['parameterName']['annotationValue'] }.compact.uniq
    assert_equal isa_parameters.count, parameter_attributes.count
    assert parameter_attributes.all? { |title| isa_parameters.include? title }
  end
end
