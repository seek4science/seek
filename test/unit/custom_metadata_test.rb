require 'test_helper'

class CustomMetadataTest < ActiveSupport::TestCase
  test 'initialise' do
    cm = simple_test_object
    cm.set_attribute_value('name', 'fred')

    assert cm.valid?
    cm.save!
  end

  test 'validate associated custom metadata type' do
    # invalid metadata type
    type = CustomMetadataType.new(title: 'invalid', supported_type: 'Study')
    refute type.valid?
    cm = CustomMetadata.new(custom_metadata_type: type, item: FactoryBot.create(:study))
    refute cm.valid?
  end

  test 'set and get attribute value' do
    cm = simple_test_object
    assert_nil cm.get_attribute_value('name')
    cm.set_attribute_value('name', 'fred')
    assert_equal 'fred', cm.get_attribute_value('name')

    cm.save!
    cm = CustomMetadata.find(cm.id)
    assert_equal 'fred', cm.get_attribute_value('name')
  end

  test 'validate values' do
    cm = simple_test_object
    refute cm.valid?
    cm.set_attribute_value('name', 'bob')
    assert cm.valid?
    cm.set_attribute_value('age', 'not a number')
    refute cm.valid?
    cm.set_attribute_value('age', '78')
    assert cm.valid?
    cm.set_attribute_value('date', 'not a date')
    refute cm.valid?
    cm.set_attribute_value('date', Time.now.to_s)
    assert cm.valid?
  end

  test 'mass assign data' do
    cm = simple_test_object
    date = Time.now.to_s
    refute cm.valid?
    cm.update(data: { name: 'Fred', age: 25, date: date })
    assert cm.valid?
    assert_equal 'Fred', cm.get_attribute_value('name')
    assert_equal 25, cm.get_attribute_value('age')
    assert_equal date, cm.get_attribute_value('date')

    # also handles symbols
    assert_equal 'Fred', cm.get_attribute_value(:name)
    assert_equal 25, cm.get_attribute_value(:age)
    assert_equal date, cm.get_attribute_value(:date)
  end

  test 'mass assignment mismatch attributes' do
    cm = simple_test_object
    date = Time.now.to_s
    refute cm.valid?
    exception = assert_raises Seek::JSONMetadata::Data::InvalidKeyException do
      cm.update(data: { name: 'Fred', wrong_age: 25, wrong_date: date })
    end

    assert_match /culprits -/, exception.message
    assert_match /wrong_age,wrong_date/, exception.message

    cm = CustomMetadata.new(custom_metadata_type: FactoryBot.build(:study_custom_metadata_type_with_spaces), item: FactoryBot.create(:study))

    exception = assert_raises Seek::JSONMetadata::Data::InvalidKeyException do
      cm.update(data: {
                             'wrong full name' => 'Stuart Little',
                             'full address' => 'On earth'
                           })
    end

    assert_match /culprit -/, exception.message
    assert_match /wrong full name/, exception.message
  end

  test 'mass assign attributes with spaces' do
    cm = CustomMetadata.new(custom_metadata_type: FactoryBot.build(:study_custom_metadata_type_with_spaces), item: FactoryBot.create(:study))

    cm.update(data: {
                           'full name' => 'Stuart Little',
                           'full address' => 'On earth'
                         })
    assert cm.valid?
    assert_equal 'Stuart Little', cm.get_attribute_value('full name')
    assert_equal 'On earth', cm.get_attribute_value('full address')
  end

  test 'mass assign attributes with symbols' do
    cm = CustomMetadata.new(custom_metadata_type: FactoryBot.build(:study_custom_metadata_type_with_symbols), item: FactoryBot.create(:study))

    cm.update(data: {
                           '+name' => '+name',
                           '-name' => '-name',
                           '&name' => '&name',
                           'name(name)' => 'name(name)'
                         })
    assert cm.valid?
    assert_equal '+name', cm.get_attribute_value('+name')
    assert_equal '-name', cm.get_attribute_value('-name')
    assert_equal '&name', cm.get_attribute_value('&name')
    assert_equal 'name(name)', cm.get_attribute_value('name(name)')
  end

  test 'construct with item with mass assigment' do
    metadata_type = FactoryBot.create(:simple_study_custom_metadata_type)
    contributor = FactoryBot.create(:person)
    investigation = FactoryBot.create(:investigation, contributor: contributor)
    date = Time.now.to_s

    User.with_current_user(contributor.user) do # User needs to be logged in for permission to save
      study = Study.new(title: 'test study',
                        investigation: investigation,
                        contributor: contributor,
                        custom_metadata: CustomMetadata.new(
                          custom_metadata_type: metadata_type,
                          data: { name: 'Fred', age: 25, date: date }
                        ))
      assert study.valid?
      study.save!
      study.reload
      refute_nil study.custom_metadata
      refute_nil study.custom_metadata.custom_metadata_type
      assert_equal 'test study', study.title
      assert_equal 'Fred', study.custom_metadata.get_attribute_value(:name)
      assert_equal 25, study.custom_metadata.get_attribute_value(:age)
      assert_equal date, study.custom_metadata.get_attribute_value(:date)

      ## constructed in 2 steps

      study2 = Study.new(title: 'test study 2',
                         investigation: investigation,
                         contributor: contributor)
      study2.custom_metadata = CustomMetadata.new(
        custom_metadata_type: metadata_type,
        data: { name: 'Fred', age: 25, date: date }
      )

      assert study2.valid?
      study2.save!
      study2.reload
      refute_nil study2.custom_metadata
      refute_nil study2.custom_metadata.custom_metadata_type
      assert_equal 'test study 2', study2.title
      assert_equal 'Fred', study2.custom_metadata.get_attribute_value(:name)
      assert_equal 25, study2.custom_metadata.get_attribute_value(:age)
      assert_equal date, study2.custom_metadata.get_attribute_value(:date)
    end
  end

  test 'associated metadata destroyed with study' do
    contributor = FactoryBot.create(:person)
    User.with_current_user(contributor.user) do
      study = FactoryBot.build(:study, title: 'test study',
                                    contributor: contributor,
                                    custom_metadata: CustomMetadata.new(
                                      custom_metadata_type: FactoryBot.create(:simple_study_custom_metadata_type),
                                      data: { name: 'Fred', age: 25 }
                                    ))
      assert study.valid?
      study.save!
      study.reload
      assert_difference('Study.count', -1) do
        assert_difference('CustomMetadata.count', -1) do
          study.destroy
        end
      end
    end
  end

  test 'associated metadata destroyed with investigation' do
    contributor = FactoryBot.create(:person)
    User.with_current_user(contributor.user) do
      inv = FactoryBot.build(:investigation, title: 'test inv',
                                          contributor: contributor,
                                          custom_metadata: CustomMetadata.new(
                                            custom_metadata_type: FactoryBot.create(:simple_investigation_custom_metadata_type),
                                            data: { name: 'Fred', age: 25 }
                                          ))
      assert inv.valid?
      inv.save!
      inv.reload
      assert_difference('Investigation.count', -1) do
        assert_difference('CustomMetadata.count', -1) do
          inv.destroy
        end
      end
    end
  end

  test 'associated metadata destroyed with assay' do
    contributor = FactoryBot.create(:person)
    User.with_current_user(contributor.user) do
      assay = FactoryBot.build(:assay, title: 'test assay',
                                    contributor: contributor,
                                    custom_metadata: CustomMetadata.new(
                                      custom_metadata_type: FactoryBot.create(:simple_assay_custom_metadata_type),
                                      data: { name: 'Fred', age: 25 }
                                    ))
      assert assay.valid?
      assay.save!
      assay.reload
      assert_difference('Assay.count', -1) do
        assert_difference('CustomMetadata.count', -1) do
          assay.destroy
        end
      end
    end
  end

  private

  def simple_test_object
    CustomMetadata.new(custom_metadata_type: FactoryBot.build(:simple_investigation_custom_metadata_type), item: FactoryBot.create(:investigation))
  end
end
