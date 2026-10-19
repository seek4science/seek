require 'test_helper'

class ISAAssayTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    User.current_user = @person.user
    @study = FactoryBot.create(:isa_json_compliant_study, contributor: @person)
    @material_assay = FactoryBot.create(:isa_json_compliant_material_assay, contributor: @person,
                                        study: @study,
                                        linked_sample_type: @study.sample_types.last)
    @data_file_assay = FactoryBot.create(:isa_json_compliant_data_file_assay, contributor: @person,
                                        study: @study,
                                        linked_sample_type: @study.sample_types.last)
  end

  def teardown
    User.current_user = nil
  end

  def material_isa_assay(id = @material_assay.id)
    ISAAssay.new.tap { |a| a.populate(id) }
  end

  def data_file_isa_assay(id=@data_file_assay.id)
    ISAAssay.new.tap { |a| a.populate(id) }
  end

  test 'populate assigns the assay, its sample type and the input sample type' do
    form = material_isa_assay

    assert_equal @material_assay, form.assay
    assert_equal @material_assay.sample_type, form.sample_type
    assert_equal @study.sample_types.last.id, form.input_sample_type_id
  end

  test 'populate leaves everything nil when the assay does not exist' do
    form = ISAAssay.new
    form.populate(0)

    assert_nil form.assay
    assert_nil form.sample_type
  end

  test 'validation does not raise when populated with a missing id' do
    form = ISAAssay.new
    form.populate(0)

    refute form.valid?
    assert form.errors[:assay].any?
  end

  test 'validation does not raise when the assay has no sample type' do
    plain_assay = FactoryBot.create(:assay, contributor: @person)
    form = ISAAssay.new
    form.populate(plain_assay.id)

    refute form.valid?
    assert form.errors[:sample_type].any?
  end

  test 'an ISA JSON compliant assay is valid' do
    form = material_isa_assay

    assert form.valid?, form.errors.full_messages.join(', ')
  end

  test 'sample type must have exactly one protocol tagged attribute' do
    form = material_isa_assay
    protocol_attribute = form.sample_type.sample_attributes.detect { |a| a.isa_tag&.isa_protocol? }
    protocol_attribute.isa_tag = ISATag.find_by(title: Seek::ISA::TagType::PARAMETER_VALUE)

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), "exactly one attribute with the 'protocol' ISA Tag"
  end

  test 'sample type must not have more than one protocol tagged attribute' do
    form = material_isa_assay
    parameter_value = form.sample_type.sample_attributes.detect { |a| a.isa_tag&.isa_parameter_value? }
    parameter_value.isa_tag = ISATag.find_by(title: Seek::ISA::TagType::PROTOCOL)

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), "exactly one attribute with the 'protocol' ISA Tag"
  end

  test 'sample type must have exactly one other_material or data_file tagged attribute' do
    material_form = material_isa_assay
    output_attribute = material_form.sample_type.sample_attributes.detect { |a| a.isa_tag&.isa_other_material? }
    output_attribute.isa_tag = ISATag.find_by(title: Seek::ISA::TagType::PARAMETER_VALUE)

    refute material_form.valid?
    assert_includes material_form.errors.full_messages.join(', '),
                    "exactly one attribute with the 'data_file' or 'other_material' ISA tag"

    data_file_form = data_file_isa_assay
    output_attribute = data_file_form.sample_type.sample_attributes.detect { |a| a.isa_tag&.isa_data_file? }
    output_attribute.isa_tag = ISATag.find_by(title: Seek::ISA::TagType::PARAMETER_VALUE)

    refute data_file_form.valid?
    assert_includes data_file_form.errors.full_messages.join(', '),
                    "exactly one attribute with the 'data_file' or 'other_material' ISA tag"

  end

  test 'every sample attribute must have an ISA tag' do
    form = material_isa_assay
    form.sample_type.sample_attributes.detect { |a| a.isa_tag&.isa_parameter_value? }.isa_tag = nil

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), 'All attributes should have an ISA Tag'
  end

  test 'input attribute must have input in its title' do
    form = material_isa_assay
    form.sample_type.sample_attributes.detect(&:input_attribute?).title = 'Renamed'

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), 'No valid input attribute detected'
  end

  test 'an input sample type is required' do
    form = material_isa_assay
    form.input_sample_type_id = nil

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), 'Input Assay is not provided'
  end

  test 'sample type validation is skipped for an assay stream' do
    assay_stream = FactoryBot.create(:assay_stream, contributor: @person, study: @study)
    form = material_isa_assay(assay_stream.id)

    assert_nil form.sample_type
    assert form.valid?, form.errors.full_messages.join(', ')
  end
end
