require 'test_helper'

class EmtExtractorTest < ActiveSupport::TestCase

  fixtures :sample_attribute_types

  test 'creates extended metadata type with simple attributes from valid json file' do

    emt_file = fixture_file_upload('extended_metadata_type/valid_simple_emt.json', 'application/json')

    assert_difference('ExtendedMetadataType.count') do
      Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(emt_file)
    end

    emt = ExtendedMetadataType.find_by(title: 'person')
    assert_not_nil emt
    assert_equal 'ExtendedMetadata', emt.supported_type
    assert emt.enabled
    assert_equal 2, emt.extended_metadata_attributes.count

    attr1 = emt.extended_metadata_attributes.find_by(title: 'first_name')
    assert_not_nil attr1
    assert_equal 'First name', attr1.label
    assert_equal SampleAttributeType.find_by(title: 'String'), attr1.sample_attribute_type
    assert_equal true, attr1.required

    attr2 = emt.extended_metadata_attributes.find_by(title: 'last_name')
    assert_not_nil attr2
    assert_equal 'last name', attr2.label
    # add for description
    assert_nil attr2.description
    assert_equal SampleAttributeType.find_by(title: 'String'), attr2.sample_attribute_type
    assert_equal false, attr2.required

  end



  test 'creates extended metadata type with linked attributes from valid json file' do

    person_emt = FactoryBot.create(:role_name_extended_metadata_type)

    uploaded_file = update_id('valid_emt_with_linked_emt.json', person_emt, 'PERSON_EMT_ID')

    assert_difference('ExtendedMetadataType.count') do
      Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(uploaded_file)
    end

    emt = ::ExtendedMetadataType.find_by(title: 'family')
    assert_not_nil emt
    assert_equal 'Investigation', emt.supported_type
    assert emt.enabled
    assert_equal 3, emt.extended_metadata_attributes.count

    dad_attr = emt.extended_metadata_attributes.find_by(title: 'dad')
    assert_not_nil dad_attr
    assert_equal 'Dad', dad_attr.label
    assert_nil dad_attr.description
    assert_equal SampleAttributeType.find_by(title: 'Linked Extended Metadata'), dad_attr.sample_attribute_type
    refute dad_attr.required

    mom_attr = emt.extended_metadata_attributes.find_by(title: 'mom')
    assert_not_nil mom_attr
    assert_equal 'Mom', mom_attr.label
    assert_nil mom_attr.description
    assert_equal SampleAttributeType.find_by(title: 'Linked Extended Metadata'), mom_attr.sample_attribute_type
    refute mom_attr.required

    child_attr = emt.extended_metadata_attributes.find_by(title: 'child')
    assert_not_nil child_attr
    assert_equal 'child', child_attr.label
    assert_nil child_attr.description
    assert_equal SampleAttributeType.find_by(title: 'Linked Extended Metadata (multiple)'), child_attr.sample_attribute_type
    refute child_attr.required

  end

  test 'creates extended metadata type with controlled vocab attributes from valid json file' do

    topic_cv = FactoryBot.create(:topics_controlled_vocab)

    uploaded_file = update_id('valid_emt_with_cv_with_ontologies.json', topic_cv, 'CV_TOPICS_ID')

    assert_difference('ExtendedMetadataType.count') do
      Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(uploaded_file)
    end


    emt = ::ExtendedMetadataType.find_by(title: 'An example with attributes associated with ontology terms')
    assert_not_nil emt
    assert_equal 'Study', emt.supported_type
    assert emt.enabled
    assert_equal 1, emt.extended_metadata_attributes.count

    topics_attr = emt.extended_metadata_attributes.find_by(title: 'Topics')
    assert_not_nil topics_attr
    assert_equal 'Topics', topics_attr.label
    assert_equal "Topics, used for annotating. Describes the domain, field of interest, of study, application, work, data, or technology. Initially seeded from the EDAM ontology.", topics_attr.description
    assert_equal SampleAttributeType.find_by(title: 'Controlled Vocabulary'), topics_attr.sample_attribute_type
    assert topics_attr.required

    assert_equal topic_cv, topics_attr.sample_controlled_vocab
    assert_equal 4, topics_attr.sample_controlled_vocab.sample_controlled_vocab_terms.count


  end


  test 'handles invalid json file' do
    invalid_emt_file = fixture_file_upload('extended_metadata_type/invalid_json.json')

    assert_no_difference('ExtendedMetadataType.count') do

      error = assert_raises(StandardError) do
        Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(invalid_emt_file)
      end

      assert_match /Failed to parse JSON file: 784: unexpected token at/, error.message
    end
  end


  test 'handles invalid json file with wrong attr type' do
    invalid_emt_file = fixture_file_upload('extended_metadata_type/invalid_emt_with_wrong_type.json')

    assert_no_difference('ExtendedMetadataType.count') do

      error = assert_raises(StandardError) do
        Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(invalid_emt_file)
      end

      assert_match /Invalid JSON file: The property '#\/attributes\/0' of type object did not match any of the required schemas/, error.message
    end
  end

  test 'handles invalid json file with wrong id' do
    invalid_emt_file = fixture_file_upload('extended_metadata_type/invalid_emt_with_wrong_id.json')

    assert_no_difference('ExtendedMetadataType.count') do

      error = assert_raises(StandardError) do
        Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(invalid_emt_file)
      end

      assert_match /Couldn't find SampleControlledVocab with 'id'=-1/, error.message
    end
  end


  private
  def update_id(emt_file_name, person_emt, replaced)
    emt_file = fixture_file_upload("extended_metadata_type/#{emt_file_name}", 'application/json')
    updated_content = emt_file.read.gsub(replaced, person_emt.id.to_s)
    updated_emt_file = StringIO.new(updated_content)

    ActionDispatch::Http::UploadedFile.new(
      tempfile: updated_emt_file,
      filename: emt_file_name,
      type: 'application/json'
    )
  end


end

