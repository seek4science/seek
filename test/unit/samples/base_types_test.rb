require 'test_helper'

class BaseTypeTest < ActiveSupport::TestCase
  test 'all types' do
    assert_equal %w(Integer Float String DateTime Date Text Boolean SeekStrain SeekSample SeekSampleMulti CV SeekDataFile CVList LinkedCustomMetadata LinkedCustomMetadataMulti).sort,
                 Seek::Samples::BaseType::ALL_TYPES.sort
  end

  test 'constants' do
    assert_equal 'Integer', Seek::Samples::BaseType::INTEGER
    assert_equal 'Float', Seek::Samples::BaseType::FLOAT
    assert_equal 'String', Seek::Samples::BaseType::STRING
    assert_equal 'DateTime', Seek::Samples::BaseType::DATE_TIME
    assert_equal 'Date', Seek::Samples::BaseType::DATE
    assert_equal 'Text', Seek::Samples::BaseType::TEXT
    assert_equal 'Boolean', Seek::Samples::BaseType::BOOLEAN
    assert_equal 'SeekStrain', Seek::Samples::BaseType::SEEK_STRAIN
    assert_equal 'SeekSample', Seek::Samples::BaseType::SEEK_SAMPLE
    assert_equal 'SeekSampleMulti', Seek::Samples::BaseType::SEEK_SAMPLE_MULTI
    assert_equal 'CV', Seek::Samples::BaseType::CV
    assert_equal 'SeekDataFile',Seek::Samples::BaseType::SEEK_DATA_FILE
    assert_equal 'CVList',Seek::Samples::BaseType::CV_LIST
    assert_equal 'LinkedCustomMetadata',Seek::Samples::BaseType::LINKED_CUSTOM_METADATA
    assert_equal 'LinkedCustomMetadataMulti',Seek::Samples::BaseType::LINKED_CUSTOM_METADATA_MULTI
  end

  test 'valid?' do
    assert Seek::Samples::BaseType.valid?('String')
    refute Seek::Samples::BaseType.valid?('Fish')
    %w(Integer Float String DateTime Date Text Boolean SeekStrain SeekSample SeekSampleMulti CV CVList).each do |type|
      assert Seek::Samples::BaseType.valid?(type)
    end
  end
end
