require 'test_helper'

class SampleControlledVocabTest < ActiveSupport::TestCase
  test 'association with terms' do
    User.with_current_user(FactoryBot.create(:project_administrator).user) do
      vocab = SampleControlledVocab.new(title: 'test')
      vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
      vocab.save!
      vocab = SampleControlledVocab.find(vocab.id)
      assert_equal ['fish'], vocab.sample_controlled_vocab_terms.collect(&:label)
    end
  end

  test 'labels' do
    User.with_current_user(FactoryBot.create(:project_administrator).user) do
      vocab = SampleControlledVocab.new(title: 'test')
      vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'fish')
      vocab.sample_controlled_vocab_terms << SampleControlledVocabTerm.new(label: 'sprout')
      vocab.save!
      assert_equal %w(fish sprout), vocab.labels.sort
    end
  end

  test 'validation' do
    User.with_current_user(FactoryBot.create(:project_administrator).user) do
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

  test 'validate ols ols_root_term_uris' do
    vocab = SampleControlledVocab.new(title: 'multiple uris')
    assert vocab.valid?

    vocab.ols_root_term_uris = 'http://purl.obolibrary.org/obo/GO_0090395'
    assert vocab.valid?
    vocab.ols_root_term_uris = 'wibble'
    refute vocab.valid?

    vocab.ols_root_term_uris = 'http://purl.obolibrary.org/obo/GO_0090395, http://purl.obolibrary.org/obo/GO_0085035'
    assert vocab.valid?
    vocab.ols_root_term_uris = 'http://purl.obolibrary.org/obo/GO_0090395, http://purl.obolibrary.org/obo/GO_0085035,   http://purl.obolibrary.org/obo/GO_0090396'
    assert vocab.valid?
    assert_equal 'http://purl.obolibrary.org/obo/GO_0090395, http://purl.obolibrary.org/obo/GO_0085035, http://purl.obolibrary.org/obo/GO_0090396', vocab.ols_root_term_uris
    vocab.ols_root_term_uris = 'http://purl.obolibrary.org/obo/GO_0090395, wibble'
    refute vocab.valid?

    vocab.ols_root_term_uris = 'http://purl.obolibrary.org/obo/GO_0090395, '
    assert vocab.valid?
    assert_equal 'http://purl.obolibrary.org/obo/GO_0090395', vocab.ols_root_term_uris

    vocab.ols_root_term_uris = 'http://purl.obolibrary.org/obo/GO_0090395, http://purl.obolibrary.org/obo/GO_0085035,  '
    assert vocab.valid?
    assert_equal 'http://purl.obolibrary.org/obo/GO_0090395, http://purl.obolibrary.org/obo/GO_0085035', vocab.ols_root_term_uris
  end

  test 'validate unique key' do
    User.with_current_user(FactoryBot.create(:project_administrator).user) do
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
    apples = FactoryBot.create(:apples_sample_controlled_vocab)
    assert apples.title.start_with?('apples controlled vocab')
    assert_equal ['Golden Delicious', 'Granny Smith', 'Bramley', "Cox's Orange Pippin"].sort, apples.labels.sort
  end

  test 'includes term?' do
    apples = FactoryBot.create(:apples_sample_controlled_vocab)
    assert apples.includes_term?('Bramley')
    refute apples.includes_term?('Fish')
  end

  test 'destroy' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)

    User.with_current_user(FactoryBot.create(:project_administrator).user) do
      assert cv.can_delete?
      assert_difference('SampleControlledVocab.count', -1) do
        assert_difference('SampleControlledVocabTerm.count', -4) do
          assert cv.destroy
        end
      end
    end
  end

  test 'cannot destroy if linked to sample type' do
    type = FactoryBot.create(:apples_controlled_vocab_sample_type)
    User.with_current_user(FactoryBot.create(:project_administrator).user) do
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
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    cv_with_sample_type = FactoryBot.create(:apples_controlled_vocab_sample_type).sample_attributes.first.sample_controlled_vocab
    admin = FactoryBot.create(:admin)
    proj_admin = FactoryBot.create(:project_administrator)
    person = FactoryBot.create(:person)

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
    type = FactoryBot.create(:apples_controlled_vocab_sample_type, title: 'test1')
    type2 = FactoryBot.create(:apples_controlled_vocab_sample_type, title: 'test2')

    refute_equal type.id, type2.id, 'sample type ids should be different'

    refute_equal type.sample_attributes.first.id, type2.sample_attributes.first.id, 'sample attributes should be different'

    refute_equal type.sample_attributes.first.sample_controlled_vocab.id, type2.sample_attributes.first.sample_controlled_vocab.id, 'controlled vocabs should be different'
  end

  test 'can edit' do
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)
    cv = FactoryBot.create(:apples_sample_controlled_vocab, title: 'for can_edit test')
    with_config_value :project_admin_sample_type_restriction, false do
      assert_empty cv.samples
      refute cv.can_edit? # nobody logged in
      User.with_current_user(person) do
        assert cv.can_edit?

        type = FactoryBot.create(:apples_controlled_vocab_sample_type, title: 'type for can_edit test')
        cv_with_sample_type = type.sample_attributes.first.sample_controlled_vocab
        assert_empty cv_with_sample_type.samples
        assert cv_with_sample_type.can_edit?

        # cannot edit if linked to samples
        contributor=FactoryBot.create(:person)
        sample = Sample.new(sample_type: FactoryBot.create(:apples_controlled_vocab_sample_type, title: 'type for can_edit test2'),
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
      project_admin = FactoryBot.create(:project_administrator)
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

  test 'admin can edit system controlled vocab' do
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)

    vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    sys_vocab = FactoryBot.create(:topics_controlled_vocab)

    refute vocab.system_vocab?
    assert sys_vocab.system_vocab?

    assert vocab.can_edit?(admin.user)
    assert vocab.can_edit?(person.user)

    assert sys_vocab.can_edit?(admin.user)
    refute sys_vocab.can_edit?(person.user)
  end

  test 'admin can edit even if there are samples' do
    contributor=FactoryBot.create(:person)
    another_person = FactoryBot.create(:person)
    admin = FactoryBot.create(:admin)

    sample = Sample.new(sample_type: FactoryBot.create(:apples_controlled_vocab_sample_type, title: 'type for can_edit test2'),
                        title: 'testing cv can edit', project_ids: contributor.projects.collect(&:id), contributor: contributor)
    sample.set_attribute_value(:apples, 'Bramley')
    disable_authorization_checks do
      assert sample.save!
    end

    cv_with_samples = sample.sample_type.sample_attributes.first.sample_controlled_vocab

    refute cv_with_samples.can_edit?(contributor)
    refute cv_with_samples.can_edit?(another_person)
    assert cv_with_samples.can_edit?(admin)
  end

  test 'can create' do
    admin = FactoryBot.create(:admin)
    none_admin = FactoryBot.create(:person)
    proj_admin = FactoryBot.create(:project_administrator)
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
    type = FactoryBot.create(:apples_controlled_vocab_sample_type, title: 'type for can_edit test')
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

  test 'ontology based?' do
    vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    refute vocab.ontology_based?

    vocab = FactoryBot.create(:topics_controlled_vocab)
    assert vocab.ontology_based?
  end

  test 'should not allow to add term with same label' do
    vocab = FactoryBot.create(:apples_sample_controlled_vocab)
    vocab.sample_controlled_vocab_terms.create(label: 'Golden Delicious')
    assert_raises ActiveRecord::RecordInvalid do
      vocab.sample_controlled_vocab_terms.create!(label: 'Golden Delicious')
    end
  end

  test 'create and update from cv dump' do
    # create first
    json = open_fixture_file('cv_seed_data/topics-annotations-controlled-vocab.json').read
    data = JSON.parse(json).with_indifferent_access
    cv = SampleControlledVocab.new(data)
    assert cv.valid?
    disable_authorization_checks do
      assert_difference('SampleControlledVocab.count', 1) do
        assert_difference('SampleControlledVocabTerm.count', 4) do
          cv.save!
        end
      end
    end
    assert_equal 'Topics test', cv.title
    assert_equal 'Topics description',cv.description
    assert_equal 'http://edamontology.org/topic_0003',cv.ols_root_term_uris
    assert_equal 'edam',cv.source_ontology
    assert_equal 4, cv.sample_controlled_vocab_terms.count
    assert_equal ["Topic", "Environmental sciences", "Carbon cycle", "Ecology"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:label)
    assert_equal ["http://edamontology.org/topic_0003", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_4020", "http://edamontology.org/topic_0610"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:iri)
    assert_equal ["", "http://edamontology.org/topic_0003", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_3855"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:parent_iri)

    # update without deletion
    json = open_fixture_file('cv_seed_data/topics-annotations-controlled-vocab-update.json').read
    data = JSON.parse(json).with_indifferent_access
    disable_authorization_checks do
      assert_no_difference('SampleControlledVocab.count') do
        assert_difference('SampleControlledVocabTerm.count', 2) do
          cv.update_from_json_dump(data, false)
          assert cv.valid?
          cv.save!
        end
      end
    end
    assert_equal 'Topics updated', cv.title
    assert_equal 'Topics description updated',cv.description
    assert_equal 'http://edamontology.org/topic_0003',cv.ols_root_term_uris
    assert_equal 'edam',cv.source_ontology
    assert_equal 6, cv.sample_controlled_vocab_terms.count
    assert_equal ["Topic", "Environmental sciences", "Carbon cycle updated", "Ecology", "Microbial ecology", "Metabarcoding"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:label)
    assert_equal ["http://edamontology.org/topic_0003", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_4020", "http://edamontology.org/topic_0610", "http://edamontology.org/topic_3697", "http://edamontology.org/topic_4038"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:iri)
    assert_equal ["", "http://edamontology.org/topic_0004", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_0610", "http://edamontology.org/topic_3697"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:parent_iri)

    # update with deletion
    data = JSON.parse(json).with_indifferent_access
    disable_authorization_checks do
      assert_no_difference('SampleControlledVocab.count') do
        assert_difference('SampleControlledVocabTerm.count', -1) do
          cv.update_from_json_dump(data, true)
          assert cv.valid?
          cv.save!
        end
      end
    end
    assert_equal 5, cv.sample_controlled_vocab_terms.count
    assert_equal ["Topic", "Environmental sciences", "Carbon cycle updated", "Microbial ecology", "Metabarcoding"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:label)
    assert_equal ["http://edamontology.org/topic_0003", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_4020", "http://edamontology.org/topic_3697", "http://edamontology.org/topic_4038"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:iri)
    assert_equal ["", "http://edamontology.org/topic_0004", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_0610", "http://edamontology.org/topic_3697"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:parent_iri)

    # update with 2 terms moving IRI
    json = open_fixture_file('cv_seed_data/topics-annotations-controlled-vocab-iri-changed.json').read
    data = JSON.parse(json).with_indifferent_access

    disable_authorization_checks do
      assert_no_difference('SampleControlledVocab.count') do
        assert_no_difference('SampleControlledVocabTerm.count') do
          cv.update_from_json_dump(data, true)
          assert cv.valid?
          cv.save!
        end
      end
    end
    assert_equal 5, cv.sample_controlled_vocab_terms.count
    assert_equal ["Topic", "Environmental sciences", "Carbon cycle updated", "Microbial ecology", "Metabarcoding"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:label)
    assert_equal ["http://edamontology.org/topic_0003", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_4020", "http://edamontology.org/new_topic_3697", "http://edamontology.org/new_topic_4038"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:iri)
    assert_equal ["", "http://edamontology.org/topic_0004", "http://edamontology.org/topic_3855", "http://edamontology.org/topic_0610", "http://edamontology.org/topic_3697"], cv.sample_controlled_vocab_terms.sort_by(&:id).collect(&:parent_iri)
  end

end
