require 'test_helper'

class TextValueTest < ActiveSupport::TestCase
  test 'annotation count' do
    sop1 = FactoryBot.create :sop
    sop2 = FactoryBot.create :sop
    sop3 = FactoryBot.create :sop
    u = FactoryBot.create :user
    tag = FactoryBot.create :tag, annotatable: sop1, source: u, value: 'coffee', attribute_name: 'tag'
    text_value = tag.value
    FactoryBot.create :tag, annotatable: sop2, source: u, value: text_value, attribute_name: 'tag'
    FactoryBot.create :tag, annotatable: sop3, source: u, value: text_value, attribute_name: 'tag'

    assert_equal 3, text_value.annotation_count('tag')

    FactoryBot.create :tag, annotatable: sop1, source: u, value: text_value, attribute_name: 'desc'

    assert_equal 1, text_value.annotation_count('desc')
    assert_equal 4, text_value.annotation_count(%w(tag desc))

    u2 = FactoryBot.create :user
    FactoryBot.create :tag, annotatable: sop1, source: u2, value: text_value, attribute_name: 'tag'

    assert_equal 4, text_value.annotation_count('tag')
    assert_equal 5, text_value.annotation_count(%w(tag desc))
  end

  test 'all tags includes seed values' do
    sop = FactoryBot.create :sop
    u = FactoryBot.create :user
    coffee = FactoryBot.create :tag, annotatable: sop, source: u, value: 'coffee', attribute_name: 'tag'
    tv = TextValue.create text: 'frog'
    AnnotationValueSeed.create value: tv, annotation_attribute: AnnotationAttribute.find_or_create_by(name: 'tag')

    assert_equal 2, TextValue.all_tags.count

    assert_equal %w(coffee frog), TextValue.all_tags.collect(&:text).sort
  end

  test 'all tags' do
    sop = FactoryBot.create :sop
    sop1 = FactoryBot.create :sop
    sop2 = FactoryBot.create :sop

    u = FactoryBot.create :user

    coffee = FactoryBot.create :tag, annotatable: sop, source: u, value: 'coffee', attribute_name: 'tag'
    fish = FactoryBot.create :tag, annotatable: sop1, source: u, value: 'fish', attribute_name: 'tag'
    soup = FactoryBot.create :tag, annotatable: sop2, source: u, value: 'soup', attribute_name: 'tag'
    soup2 = FactoryBot.create :tag, annotatable: sop, source: u, value: soup.value, attribute_name: 'tag'
    spade = FactoryBot.create :tag, annotatable: sop, source: u, value: 'spade', attribute_name: 'tool'
    ruby = FactoryBot.create :tag, annotatable: sop2, source: u, value: 'ruby', attribute_name: 'expertise'
    fish2 = FactoryBot.create :tag, annotatable: sop2, source: u, value: fish.value, attribute_name: 'expertise'
    blah = FactoryBot.create :tag, annotatable: sop2, source: u, value: 'blah', attribute_name: 'desc'

    assert_equal 5, TextValue.all_tags.count
    assert_equal %w(coffee fish ruby soup spade), TextValue.all_tags.collect(&:text).sort
    assert_equal 1, TextValue.all_tags(['tool']).count
    assert_equal spade.value, TextValue.all_tags(['tool'])[0]
    assert_equal 2, TextValue.all_tags(['expertise']).count
    assert_equal %w(fish ruby), TextValue.all_tags('expertise').collect(&:text).sort
    assert_equal 1, TextValue.all_tags(['desc']).count
    assert_equal blah.value, TextValue.all_tags('desc')[0]
  end

  test 'has attribute_name?' do
    sop = FactoryBot.create :sop
    u = FactoryBot.create :user
    coffee = FactoryBot.create :tag, annotatable: sop, source: u, value: 'coffee', attribute_name: 'tag'
    FactoryBot.create :tag, annotatable: sop, source: u, value: coffee.value, attribute_name: 'title'
    tv = TextValue.create text: 'frog'
    AnnotationValueSeed.create value: tv, annotation_attribute: AnnotationAttribute.find_or_create_by(name: 'tag')

    assert tv.has_attribute_name?('tag')
    assert !tv.has_attribute_name?('title')

    assert coffee.value.has_attribute_name?('tag')
    assert coffee.value.has_attribute_name?('title')
    assert !coffee.value.has_attribute_name?('description')
  end
end
