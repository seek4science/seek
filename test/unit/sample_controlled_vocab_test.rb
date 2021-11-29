require 'test_helper'

class SampleControlledVocabTest < ActiveSupport::TestCase
  test 'association with terms' do
    User.with_current_user(Factory(:project_administrator).user) do
      vocab = SampleControlledVocab.new(title: 'test')
      vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
      vocab.save!
      vocab = SampleControlledVocab.find(vocab.id)
      assert_equal ['fish'], vocab.sample_controlled_vocab_terms.collect(&:label)
    end
  end

  test 'labels' do
    User.with_current_user(Factory(:project_administrator).user) do
      vocab = SampleControlledVocab.new(title: 'test')
      vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
      vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'sprout')
      vocab.save!
      assert_equal %w(fish sprout), vocab.labels.sort
    end
  end

  test 'validation' do
    User.with_current_user(Factory(:project_administrator).user) do
      vocab = SampleControlledVocab.new
      refute vocab.valid?
      vocab.title = 'test'
      assert vocab.valid?
      vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
      assert vocab.valid?
      vocab.save!
      vocab2 = SampleControlledVocab.new(title: 'test')
      refute vocab2.valid?
    end
  end

  test 'validate unique key' do
    User.with_current_user(Factory(:project_administrator).user) do
      SampleControlledVocab.create(title: 'no key')
      SampleControlledVocab.create(title: 'blank key',key:'')
      vocab = SampleControlledVocab.new(title: 'test')
      assert vocab.valid?
      vocab.key='test'
      assert vocab.valid?
      vocab.save!
      vocab = SampleControlledVocab.new(title: 'test2', key:'test')
      refute vocab.valid?
      vocab.key = 'test2'
      assert vocab.valid?
      # blanks are allowed
      vocab.key = nil
      assert vocab.valid?
      vocab.key = ''
      assert vocab.valid?
    end
  end

  test 'apples factory' do
    apples = Factory(:apples_sample_controlled_vocab)
    assert apples.title.start_with?('apples controlled vocab')
    assert_equal ['Golden Delicious', 'Granny Smith', 'Bramley', "Cox's Orange Pippin"].sort, apples.labels.sort
  end

  test 'includes term?' do
    apples = Factory(:apples_sample_controlled_vocab)
    assert apples.includes_term?('Bramley')
    refute apples.includes_term?('Fish')
  end

  test 'destroy' do
    cv = Factory(:apples_sample_controlled_vocab)

    User.with_current_user(Factory(:project_administrator).user) do
      assert cv.can_delete?
      assert_difference('SampleControlledVocab.count', -1) do
        assert_difference('SampleControlledVocabTerm.count', -4) do
          assert cv.destroy
        end
      end
    end
  end

  test 'cannot destroy if linked to sample type' do
    type = Factory(:apples_controlled_vocab_sample_type)
    User.with_current_user(Factory(:project_administrator).user) do
      cv = type.sample_attributes.first.sample_controlled_vocab
      refute cv.can_delete?
      assert_no_difference('SampleControlledVocab.count') do
        assert_no_difference('SampleControlledVocabTerm.count') do
          refute cv.destroy
        end
      end
    end
  end

  test 'can delete?' do
    cv = Factory(:apples_sample_controlled_vocab)
    cv_with_sample_type = Factory(:apples_controlled_vocab_sample_type).sample_attributes.first.sample_controlled_vocab
    admin = Factory(:admin)
    proj_admin = Factory(:project_administrator)
    person = Factory(:person)

    with_config_value :project_admin_sample_type_restriction, false do
      assert cv.can_delete?(admin.user)
      assert cv.can_delete?(proj_admin.user)
      assert cv.can_delete?(person.user)
      refute cv_with_sample_type.can_delete?(admin.user)
      refute cv_with_sample_type.can_delete?(proj_admin.user)
      refute cv_with_sample_type.can_delete?(person.user)
    end

    with_config_value :project_admin_sample_type_restriction, true do
      assert cv.can_delete?(admin.user)
      assert cv.can_delete?(proj_admin.user)
      refute cv.can_delete?(person.user)
      refute cv_with_sample_type.can_delete?(admin.user)
      refute cv_with_sample_type.can_delete?(proj_admin.user)
      refute cv_with_sample_type.can_delete?(person.user)
    end
  end

  #tests a peculiar error that was occuring with sqlite3, where the controlled vocab was the same between factory created sample types
  test 'controlled vocab sample type factory' do
    type = Factory.create(:apples_controlled_vocab_sample_type, title: 'test1')
    type2 = Factory.create(:apples_controlled_vocab_sample_type, title: 'test2')

    refute_equal type.id, type2.id, 'sample type ids should be different'

    refute_equal type.sample_attributes.first.id, type2.sample_attributes.first.id, 'sample attributes should be different'

    refute_equal type.sample_attributes.first.sample_controlled_vocab.id, type2.sample_attributes.first.sample_controlled_vocab.id, 'controlled vocabs should be different'
  end

  test 'can edit' do
    admin = Factory(:admin)
    person = Factory(:person)
    cv = Factory(:apples_sample_controlled_vocab, title: 'for can_edit test')
    with_config_value :project_admin_sample_type_restriction, false do
      assert_empty cv.samples
      refute cv.can_edit? # nobody logged in
      User.with_current_user(person) do
        assert cv.can_edit?

        type = Factory(:apples_controlled_vocab_sample_type, title: 'type for can_edit test')
        cv_with_sample_type = type.sample_attributes.first.sample_controlled_vocab
        assert_empty cv_with_sample_type.samples
        assert cv_with_sample_type.can_edit?

        # cannot edit if linked to samples
        contributor=Factory(:person)
        sample = Sample.new(sample_type: Factory(:apples_controlled_vocab_sample_type, title: 'type for can_edit test2'),
                            title: 'testing cv can edit', project_ids: person.projects.collect(&:id), contributor: person)
        sample.set_attribute_value(:apples, 'Bramley')
        disable_authorization_checks do
          assert sample.save!
        end

        cv_with_samples = sample.sample_type.sample_attributes.first.sample_controlled_vocab
        refute_empty cv_with_samples.samples
        refute cv_with_samples.can_edit?
      end
    end

    # need to be a project administrator if restriction configured
    with_config_value :project_admin_sample_type_restriction, true do
      project_admin = Factory(:project_administrator)
      assert_empty cv.samples
      refute cv.can_edit?(person.user)
      User.with_current_user(person.user) do
        refute cv.can_edit?
      end

      assert cv.can_edit?(project_admin.user)
      User.with_current_user(project_admin.user) do
        assert cv.can_edit?
      end

      assert cv.can_edit?(admin.user)
      User.with_current_user(admin.user) do
        assert cv.can_edit?
      end
    end
  end

  test 'can create' do
    admin = Factory(:admin)
    none_admin = Factory(:person)
    proj_admin = Factory(:project_administrator)
    refute SampleControlledVocab.can_create?
    with_config_value :project_admin_sample_type_restriction, false do
      User.with_current_user none_admin.user do
        assert SampleControlledVocab.can_create?
        with_config_value :samples_enabled, false do
          refute SampleControlledVocab.can_create?
        end
      end
    end

    with_config_value :project_admin_sample_type_restriction, true do
      User.with_current_user none_admin.user do
        refute SampleControlledVocab.can_create?
      end
      User.with_current_user proj_admin.user do
        assert SampleControlledVocab.can_create?
        with_config_value :samples_enabled, false do
          refute SampleControlledVocab.can_create?
        end
      end
      User.with_current_user admin.user do
        assert SampleControlledVocab.can_create?
        with_config_value :samples_enabled, false do
          refute SampleControlledVocab.can_create?
        end
      end
    end
  end

  test 'trigger regeneration of sample type templates when saved' do
    type = Factory(:apples_controlled_vocab_sample_type, title: 'type for can_edit test')
    cv = type.sample_attributes.first.sample_controlled_vocab
    refute_nil cv
    refute cv.new_record?
    assert_equal [type], cv.sample_types

    type.template_generation_task.destroy!
    assert_enqueued_with(job: SampleTemplateGeneratorJob, args: [type]) do
      cv.sample_controlled_vocab_terms.create(label: 'fsdfsdsdfsdf')
    end

    type.template_generation_task.destroy!
    assert_enqueued_with(job: SampleTemplateGeneratorJob, args: [type]) do
      term = cv.sample_controlled_vocab_terms.last
      cv.sample_controlled_vocab_terms.destroy(term)
    end

    type.template_generation_task.destroy!
    # changing the title has no effect
    assert_no_enqueued_jobs(only: SampleTemplateGeneratorJob) do
      cv.title = 'new title'
      cv.save
    end
  end
end
