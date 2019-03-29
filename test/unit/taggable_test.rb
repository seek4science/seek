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
        p.annotate_with %w(golf fishing), 'expertise'
        p.save!
      end
    end
    assert_equal %w(golf fishing).sort, p.expertise.sort
  end

  test 'tag_with on new object' do
    person = Factory(:person)
    User.current_user = person.user
    TextValue.create!(text: 'Fishing')

    new_sop = Factory.build(:sop, contributor: person)
    assert_equal 0, new_sop.annotations_with_attribute('tag').size
    assert_no_difference('Annotation.count') do
      assert_no_difference('TextValue.count') do
        new_sop.annotate_with %w(golf fishing)
      end
    end

    assert_difference('Annotation.count', 2) do
      assert_difference('TextValue.count', 1, 'Only 1 TextValue needs to be created, other already exists') do
        assert new_sop.save
      end
    end

    tags = new_sop.reload.annotations_with_attribute('tag').collect { |a| a.value.text.downcase }.sort

    assert_equal %w(golf fishing).sort, tags
  end

  test 'tag_with on existing object' do
    person = Factory(:person)
    User.current_user = person.user

    existing_sop = Factory(:sop, contributor: person)
    existing_sop.annotate_with %w(golf fishing)
    existing_sop.save!
    assert_equal 2, existing_sop.annotations_with_attribute('tag').size

    existing_sop.reload.annotate_with %w(golf)

    assert_difference('Annotation.count', -1) do
      assert_no_difference('TextValue.count') do
        assert existing_sop.save
      end
    end

    tags = existing_sop.reload.annotations_with_attribute('tag').collect { |a| a.value.text.downcase }.sort

    assert_equal %w(golf).sort, tags
  end

  test 'add_annotations' do
    p = Factory :person
    User.current_user = p.user
    assert_equal 0, p.expertise.size
    assert_difference('Annotation.count', 2) do
      assert_difference('TextValue.count', 2) do
        params = { expertise_list: 'golf,fishing' }
        p.add_annotations params[:expertise_list], 'expertise'
        p.save!
      end
    end

    assert_equal %w(golf fishing).sort, p.expertise.sort
  end

  test 'tag_with changed response' do
    p = Factory :person
    User.current_user = p.user
    p.save!
    attr = 'expertise'
    p.annotate_with(%w(golf fishing), attr)
    p.save!
    assert !p.reload.annotations_with_attribute(attr).empty?
    p.save!
    assert !p.annotate_with(%w(golf fishing), attr)
    p.save!
    assert p.annotate_with(%w(golf fishing sparrow), attr)
    p.save!
    assert p.annotate_with(%w(golf fishing), attr)
  end

  test 'no duplication tags' do
    p = Factory :person
    User.current_user = p.user
    attr = 'tag'

    p.annotate_with %w(coffee coffee), attr
    p.save!

    assert_equal ['coffee'], p.annotations_as_text_array
  end

  test 'ignore case sensitive' do
    p = Factory :person
    User.current_user = p.user
    attr = 'expertise'

    p.annotate_with %w(coffee Coffee), attr
    p.save!

    updated_expertises = Annotation.where(annotatable_type: p.class.name, annotatable_id: p.id).select { |a| a.annotation_attribute.name == attr }
    assert_equal ['coffee'], updated_expertises.collect { |a| a.value.text }
  end
end
