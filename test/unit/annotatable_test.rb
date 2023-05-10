require 'test_helper'

class AnnotatableTest < ActiveSupport::TestCase

  test 'tagging enabled' do
    assert Model.is_taggable?
    assert Assay.is_taggable?

    model = Model.new
    assay = Assay.new
    assert model.is_taggable?
    assert assay.is_taggable?

    with_config_value :tagging_enabled, false do
      refute Model.is_taggable?
      refute Assay.is_taggable?
      refute model.is_taggable?
      refute assay.is_taggable?
    end
  end

  test 'annotate_with' do
    p = FactoryBot.create :person
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

  test 'annotate_with on new object' do
    person = FactoryBot.create(:person)
    User.current_user = person.user
    TextValue.create!(text: 'Fishing')

    new_sop = FactoryBot.build(:sop, contributor: person)
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

  test 'annotate_with on existing object' do
    person = FactoryBot.create(:person)
    User.current_user = person.user

    existing_sop = FactoryBot.create(:sop, contributor: person)
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
    p = FactoryBot.create :person
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

  test 'add_annotations as array' do
    p = FactoryBot.create :person
    User.current_user = p.user
    assert_equal 0, p.expertise.size
    assert_difference('Annotation.count', 2) do
      assert_difference('TextValue.count', 2) do
        p.add_annotations ['golf','fishing'], 'expertise'
        p.save!
      end
    end

    assert_equal %w(golf fishing).sort, p.expertise.sort

    assert_difference('Annotation.count', -2) do
      assert_no_difference('TextValue.count') do
        p.add_annotations [], 'expertise'
        p.save!
      end
    end

    assert_equal [], p.expertise

    #blanks handled and ignored
    assert_no_difference('Annotation.count', -2) do
      assert_no_difference('TextValue.count') do
        p.add_annotations ['',nil], 'expertise'
        p.save!
      end
    end

    assert_equal [], p.expertise
  end

  test 'annotate_with changed response' do
    p = FactoryBot.create :person
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
    p = FactoryBot.create :person
    User.current_user = p.user
    attr = 'expertise'

    p.annotate_with %w(coffee coffee), attr
    p.save!

    assert_equal ['coffee'], p.annotations_as_text_array
  end

  test 'ignore case sensitive' do
    p = FactoryBot.create :person
    User.current_user = p.user
    attr = 'expertise'

    p.annotate_with %w(coffee Coffee), attr
    p.save!

    updated_expertises = Annotation.where(annotatable_type: p.class.name, annotatable_id: p.id).select { |a| a.annotation_attribute.name == attr }
    assert_equal ['coffee'], updated_expertises.collect { |a| a.value.text }
  end
end
