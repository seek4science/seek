require 'test_helper'

class ISAStudyTest < ActiveSupport::TestCase
  def setup
    @person = FactoryBot.create(:person)
    User.current_user = @person.user
    @study = FactoryBot.create(:isa_json_compliant_study, contributor: @person)
  end

  def teardown
    User.current_user = nil
  end

  def isa_study
    ISAStudy.new.tap { |s| s.populate(@study.id) }
  end

  test 'populate assigns the study and both sample types' do
    form = isa_study

    assert_equal @study, form.study
    assert_equal @study.sample_types.first, form.source
    assert_equal @study.sample_types.second, form.sample_collection
  end

  test 'populate leaves everything nil when the study does not exist' do
    form = ISAStudy.new
    form.populate(0)

    assert_nil form.study
    assert_nil form.source
    assert_nil form.sample_collection
  end

  test 'an ISA JSON compliant study is valid' do
    form = isa_study

    assert form.valid?, form.errors.full_messages.join(', ')
  end

  test 'source sample type must have exactly one source tagged attribute' do
    form = isa_study
    # Retag the single 'source' attribute, leaving the source sample type with none
    source_attribute = form.source.sample_attributes.detect { |a| a.isa_tag&.isa_source? }
    source_attribute.isa_tag = ISATag.find_by(title: Seek::ISA::TagType::SOURCE_CHARACTERISTIC)

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), "exactly one attribute with the 'source' ISA tag"
  end

  test 'source sample type must not have more than one source tagged attribute' do
    form = isa_study
    characteristic = form.source.sample_attributes.detect { |a| a.isa_tag&.isa_source_characteristic? }
    characteristic.isa_tag = ISATag.find_by(title: Seek::ISA::TagType::SOURCE)

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), "exactly one attribute with the 'source' ISA tag"
  end

  test 'sample collection sample type must have exactly one sample, protocol and input tagged attribute' do
    [Seek::ISA::TagType::SAMPLE, Seek::ISA::TagType::PROTOCOL, Seek::ISA::TagType::INPUT].each do |tag_type|
      form = isa_study
      attribute = form.sample_collection.sample_attributes.detect { |a| a.isa_tag&.title == tag_type }
      attribute.isa_tag = ISATag.find_by(title: Seek::ISA::TagType::PARAMETER_VALUE)

      refute form.valid?, "expected a missing '#{tag_type}' tag to be rejected"
      assert_includes form.errors.full_messages.join(', '),
                      "exactly one attribute with the '#{tag_type}' ISA tag"
    end
  end

  test 'every sample attribute must have an ISA tag' do
    form = isa_study
    form.source.sample_attributes.detect { |a| a.isa_tag&.isa_source_characteristic? }.isa_tag = nil

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), 'does not have an ISA tag'
  end

  test 'input attribute must have input in its title' do
    form = isa_study
    input_attribute = form.sample_collection.sample_attributes.detect(&:input_attribute?)
    input_attribute.title = 'Renamed'

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), 'No valid input attribute detected'
  end

  test 'input attribute must be a registered sample list' do
    form = isa_study
    input_attribute = form.sample_collection.sample_attributes.detect(&:input_attribute?)
    input_attribute.sample_attribute_type = FactoryBot.create(:string_sample_attribute_type)

    refute form.valid?
    assert_includes form.errors.full_messages.join(', '), 'No valid input attribute detected'
  end
end
