require 'test_helper'

class BaseTypeTest < ActiveSupport::TestCase
  test 'all types' do
    assert_equal %w(Integer Float String DateTime Date Text Boolean SeekStrain SeekSample CV).sort,
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
    assert_equal 'CV', Seek::Samples::BaseType::CV
  end

  test 'valid?' do
    assert Seek::Samples::BaseType.valid?('String')
    refute Seek::Samples::BaseType.valid?('Fish')
    %w(Integer Float String DateTime Date Text Boolean SeekStrain SeekSample CV).each do |type|
      assert Seek::Samples::BaseType.valid?(type)
    end
  end
end
