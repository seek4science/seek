require 'test_helper'

class EmtExtractorTest < ActiveSupport::TestCase

  fixtures :sample_attribute_types

  test 'creates extended metadata type with simple attributes from valid json file' do

    emt_file = open_fixture_file('extended_metadata_type/valid_simple_emt.json')
    Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(emt_file)

    emt = ::ExtendedMetadataType.find_by(title: 'person')
    assert_not_nil emt
    assert_equal 'ExtendedMetadata', emt.supported_type
    assert emt.enabled
    assert_equal 2, emt.extended_metadata_attributes.count

    attr1 = emt.extended_metadata_attributes.find_by(title: 'first_name')
    assert_not_nil attr1
    assert_equal 'First name', attr1.label
    assert_equal SampleAttributeType.find_by(title: 'String'), attr1.sample_attribute_type
    assert attr1.required

    attr2 = emt.extended_metadata_attributes.find_by(title: 'last_name')
    assert_not_nil attr2
    assert_equal 'Last Name', attr2.label
    # add for description
    assert_nil attr2.description
    assert_equal SampleAttributeType.find_by(title: 'String'), attr2.sample_attribute_type
    assert attr2.required

    errorfile = Rails.root.join(Seek::Config.append_filestore_path('emt_files'), 'result.error')
    assert File.exist?(errorfile)
    assert_equal '', File.read(errorfile)

  end

  test 'creates extended metadata type with linked attributes from valid json file' do

    person_emt = FactoryBot.create(:role_name_extended_metadata_type)
    emt_file_path = open_fixture_file('extended_metadata_type/valid_emt_with_linked_emt.json')
    updated_file = File.read(emt_file_path).gsub('PERSON_EMT_ID', person_emt.id.to_s)

    Dir.mktmpdir do |dir|
      new_file_path = File.join(dir, 'new_file.json')
      File.write(new_file_path, updated_file)

      assert_difference('ExtendedMetadataType.count') do
        Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(new_file_path)
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

    errorfile = Rails.root.join(Seek::Config.append_filestore_path('emt_files'), 'result.error')
    assert File.exist?(errorfile)
    assert_equal '', File.read(errorfile)


  end

  test 'creates extended metadata type with controlled vocab attributes from valid json file' do

    topic_cv = FactoryBot.create(:topics_controlled_vocab)

    emt_file_path = open_fixture_file('extended_metadata_type/valid_emt_with_cv_with_ontologies.json')
    updated_file = File.read(emt_file_path).gsub('CV_TOPICS_ID', topic_cv.id.to_s)

    Dir.mktmpdir do |dir|
      new_file_path = File.join(dir, 'new_file.json')
      File.write(new_file_path, updated_file)

      assert_difference('ExtendedMetadataType.count') do
        Seek::ExtendedMetadataType::EMTExtractor.extract_extended_metadata_type(new_file_path)
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

    errorfile = Rails.root.join(Seek::Config.append_filestore_path('emt_files'), 'result.error')
    assert File.exist?(errorfile)
    assert_equal '', File.read(errorfile)

  end


  end


