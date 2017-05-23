require 'test_helper'

class TaggableTest < ActiveSupport::TestCase
  test 'tagging enabled' do
    assert Person.is_taggable?
    assert Model.is_taggable?
    assert Assay.is_taggable?

    person = Person.new
    model = Model.new
    assay = Assay.new
    assert person.is_taggable?
    assert model.is_taggable?
    assert assay.is_taggable?

    with_config_value :tagging_enabled, false do
      refute Person.is_taggable?
      refute Model.is_taggable?
      refute Assay.is_taggable?
      refute person.is_taggable?
      refute model.is_taggable?
      refute assay.is_taggable?
    end
  end

  test 'tag_with' do
    p = Factory :person
    User.current_user = p.user
    assert_equal 0, p.expertise.size
    assert_difference('Annotation.count', 2) do
      assert_difference('TextValue.count', 2) do
        p.tag_with %w(golf fishing), 'expertise'
      end
    end
    p.reload
    assert_equal %w(golf fishing).sort, p.expertise.collect(&:text).sort
  end

  test 'tag_annotations' do
    p = Factory :person
    User.current_user = p.user
    assert_equal 0, p.expertise.size
    assert_difference('Annotation.count', 2) do
      assert_difference('TextValue.count', 2) do
        params = { expertise_list: 'golf,fishing' }
        p.tag_annotations params[:expertise_list], 'expertise'
      end
    end
    p.reload
    assert_equal %w(golf fishing).sort, p.expertise.collect(&:text).sort
  end

  test 'tag_with changed response' do
    p = Factory :person
    User.current_user = p.user
    p.save!
    attr = 'expertise'
    p.tag_with(%w(golf fishing), attr)
    p.save!
    assert !p.annotations_with_attribute(attr).empty?
    assert !p.tag_with(%w(golf fishing), attr)
    assert p.tag_with(%w(golf fishing sparrow), attr)
    assert p.tag_with(%w(golf fishing), attr)
  end

  test 'no duplication tags' do
    p = Factory :person
    User.current_user = p.user
    attr = 'tag'

    p.tag_with %w(coffee coffee), attr
    p.reload

    assert_equal ['coffee'], p.annotations_as_text_array
  end

  test 'ignore case sensitive' do
    p = Factory :person
    User.current_user = p.user
    attr = 'expertise'

    p.tag_with %w(coffee Coffee), attr
    p.reload

    updated_expertises = Annotation.where(annotatable_type: p.class.name, annotatable_id: p.id).select { |a| a.annotation_attribute.name == attr }
    assert_equal ['coffee'], updated_expertises.collect { |a| a.value.text }
  end
end
