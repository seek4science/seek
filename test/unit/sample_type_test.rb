require 'test_helper'
require 'time_test_helper'

class SampleTypeTest < ActiveSupport::TestCase

  def setup
    Factory(:admin)#to prevent person being first person and therefore admin
    @person = Factory(:person)
    @project = @person.projects.first
    @project_ids=[@project.id]
  end

  test 'validation' do
    sample_type = SampleType.new title: 'fish', project_ids: @project_ids
    refute sample_type.valid?
    sample_type.sample_attributes << Factory(:simple_string_sample_attribute, is_title: true, sample_type: sample_type)

    assert sample_type.valid?
    sample_type.title = nil
    refute sample_type.valid?
    sample_type.title = ''
    refute sample_type.valid?

    # needs to have a project
    sample_type = SampleType.new title: 'fish'
    sample_type.sample_attributes << Factory(:simple_string_sample_attribute, is_title: true, sample_type: sample_type)
    refute sample_type.valid?
    sample_type.projects = [Factory(:project)]
    assert sample_type.valid?

    # cannot have 2 attributes with the same name
    sample_type = SampleType.new title: 'fish', project_ids: @project_ids
    sample_type.sample_attributes << Factory(:simple_string_sample_attribute, title: 'a', is_title: true, sample_type: sample_type)
    assert sample_type.valid?
    sample_type.sample_attributes << Factory(:simple_string_sample_attribute, title: 'a', is_title: false, sample_type: sample_type)
    refute sample_type.valid?

    # uniqueness check should be case insensitive
    sample_type = SampleType.new title: 'fish', project_ids: @project_ids
    sample_type.sample_attributes << Factory(:simple_string_sample_attribute, title: 'aaa', is_title: true, sample_type: sample_type)
    assert sample_type.valid?
    sample_type.sample_attributes << Factory(:simple_string_sample_attribute, title: 'aAA', is_title: false, sample_type: sample_type)
    refute sample_type.valid?
  end

  test 'is favouritable?' do
    type=Factory(:simple_sample_type,project_ids:@project_ids)
    assert type.is_favouritable?
  end

  test 'test uuid generated' do
    sample_type = SampleType.new title: 'fish'
    assert_nil sample_type.attributes['uuid']
    sample_type.save
    assert_not_nil sample_type.attributes['uuid']
  end

  test 'samples' do
    sample_type = Factory(:simple_sample_type,project_ids:@project_ids)
    assert_empty sample_type.samples
    sample1 = Factory :sample, sample_type: sample_type
    sample2 = Factory :sample, sample_type: sample_type

    sample_type.reload
    assert_equal [sample1, sample2].sort, sample_type.samples.sort
  end

  test 'associate sample attribute default order' do
    sample_type = SampleType.new title: 'sample type', project_ids: @project_ids
    attribute1 = Factory(:simple_string_sample_attribute, is_title: true, sample_type: sample_type)
    attribute2 = Factory(:simple_string_sample_attribute, sample_type: sample_type)
    sample_type.sample_attributes << attribute1
    sample_type.sample_attributes << attribute2
    disable_authorization_checks { sample_type.save! }

    sample_type.reload

    assert_equal [attribute1, attribute2], sample_type.sample_attributes
  end

  test 'associate sample attribute specify order' do
    sample_type = SampleType.new title: 'sample type', project_ids: @project_ids
    attribute3 = Factory(:simple_string_sample_attribute, pos: 3, sample_type: sample_type)
    attribute2 = Factory(:simple_string_sample_attribute, pos: 2, sample_type: sample_type)
    attribute1 = Factory(:simple_string_sample_attribute, pos: 1, is_title: true, sample_type: sample_type)
    sample_type.sample_attributes << attribute3
    sample_type.sample_attributes << attribute2
    sample_type.sample_attributes << attribute1
    disable_authorization_checks { sample_type.save! }

    sample_type.reload

    assert_equal [attribute1, attribute2, attribute3], sample_type.sample_attributes
  end

  # thorough tests of a fairly complex factory, as it will be used in a lot of other tests
  test 'patient sample type factory test' do
    name_type = Factory(:full_name_sample_attribute_type)
    assert name_type.validate_value?('George Bush')
    refute name_type.validate_value?('george bush')
    refute name_type.validate_value?('GEorge Bush')
    refute name_type.validate_value?('George BUsh')
    refute name_type.validate_value?('G(eorge Bush')
    refute name_type.validate_value?('George B2ush')
    refute name_type.validate_value?('George')

    age_type = Factory(:age_sample_attribute_type)
    assert age_type.validate_value?(22)
    assert age_type.validate_value?('97')
    refute age_type.validate_value?(-6)
    refute age_type.validate_value?('six')

    weight_type = Factory(:weight_sample_attribute_type)
    assert weight_type.validate_value?(22.223)
    assert weight_type.validate_value?('97.332')
    refute weight_type.validate_value?('97.332.44')
    refute weight_type.validate_value?(-6)
    refute weight_type.validate_value?(-6.4)
    refute weight_type.validate_value?('-6.4')
    refute weight_type.validate_value?('six')

    post_code = Factory(:postcode_sample_attribute_type)
    assert post_code.validate_value?('M13 9PL')
    assert post_code.validate_value?('M12 7PL')
    refute post_code.validate_value?('12 PL')
    refute post_code.validate_value?('m12 7pl')
    refute post_code.validate_value?('bob')

    type = Factory(:patient_sample_type)
    assert_equal 'Patient data', type.title
    assert_equal ['full name', 'age', 'weight', 'address', 'postcode'], type.sample_attributes.collect(&:title)
    assert_equal [true, true, false, false, false], type.sample_attributes.collect(&:required)
  end

  test 'validate value' do
    type = Factory(:patient_sample_type)
    assert type.validate_value?('full name', 'Fred Bloggs')
    refute type.validate_value?('full name', 'Fred 22')
    assert type.validate_value?('age', 99)
    refute type.validate_value?('age', 'fish')
    assert_raise SampleType::UnknownAttributeException do
      type.validate_value?('monkey', 2)
    end
  end

  test 'controlled vocab sample type validate_value' do
    vocab = Factory(:apples_sample_controlled_vocab)
    assert vocab.includes_term?('Granny Smith')
    assert_equal 4, vocab.sample_controlled_vocab_terms.count
    type = Factory(:apples_controlled_vocab_sample_type)
    type.sample_attributes.first.sample_controlled_vocab = vocab
    type.sample_attributes.first.save!
    assert type.valid?
    assert_equal 4, type.sample_attributes.first.sample_controlled_vocab.sample_controlled_vocab_terms.count

    assert type.validate_value?('apples', 'Granny Smith')
    refute type.validate_value?('apples', 'Orange')
    refute type.validate_value?('apples', 1)
    refute type.validate_value?('apples', nil)
  end

  test 'must have one title attribute' do
    sample_type = SampleType.new title: 'No title', project_ids: @project_ids
    sample_type.sample_attributes << Factory(:sample_attribute, title: 'full name', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, is_title: false, sample_type: sample_type)

    refute sample_type.valid?
    sample_type.sample_attributes << Factory(:sample_attribute, title: 'full name title', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: sample_type)
    assert sample_type.valid?

    disable_authorization_checks { sample_type.save! }

    sample_type.sample_attributes << Factory(:sample_attribute, title: '2nd full name title', sample_attribute_type: Factory(:full_name_sample_attribute_type), required: true, is_title: true, sample_type: sample_type)
    refute sample_type.valid?
  end

  test 'build from template' do
    default_type = SampleAttributeType.default
    default_type ||= Factory(:string_sample_attribute_type, title: 'String')

    sample_type = SampleType.new title: 'from template', project_ids: @project_ids
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    refute_nil sample_type.template

    sample_type.build_attributes_from_template
    attribute_names = sample_type.sample_attributes.collect(&:title)
    assert_equal ['full name', 'date of birth', 'hair colour', 'eye colour'], attribute_names
    columns = sample_type.sample_attributes.collect(&:template_column_index)
    assert_equal [1, 2, 3, 4], columns

    assert sample_type.sample_attributes.first.is_title?
    sample_type.sample_attributes.each do |attr|
      assert_equal default_type, attr.sample_attribute_type
    end

    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample_type = SampleType.find(sample_type.id)
    attribute_names = sample_type.sample_attributes.collect(&:title)
    assert_equal ['full name', 'date of birth', 'hair colour', 'eye colour'], attribute_names
    columns = sample_type.sample_attributes.collect(&:template_column_index)
    assert_equal [1, 2, 3, 4], columns
  end

  # a less clean template, to check it takes the last sample sheet, and handles irregular columns
  test 'build from template2' do
    default_type = SampleAttributeType.default
    default_type ||= Factory(:string_sample_attribute_type, title: 'String')

    sample_type = SampleType.new title: 'from template', project_ids: [Factory(:project).id]
    sample_type.content_blob = Factory(:sample_type_template_content_blob2)
    refute_nil sample_type.template

    sample_type.build_attributes_from_template
    attribute_names = sample_type.sample_attributes.collect(&:title)
    assert_equal ['full name', 'date of birth', 'hair colour', 'eye colour'], attribute_names
    columns = sample_type.sample_attributes.collect(&:template_column_index)
    assert_equal [3, 7, 10, 11], columns

    assert sample_type.sample_attributes.first.is_title?
    sample_type.sample_attributes.each do |attr|
      assert_equal default_type, attr.sample_attribute_type
    end

    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample_type = SampleType.find(sample_type.id)
    attribute_names = sample_type.sample_attributes.collect(&:title)
    assert_equal ['full name', 'date of birth', 'hair colour', 'eye colour'], attribute_names
    columns = sample_type.sample_attributes.collect(&:template_column_index)
    assert_equal [3, 7, 10, 11], columns
  end

  test 'compatible template file' do
    sample_type = SampleType.new title: 'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    assert sample_type.compatible_template_file?

    sample_type = SampleType.new title: 'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob2)
    assert sample_type.compatible_template_file?

    sample_type = SampleType.new title: 'from template'
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    assert sample_type.compatible_template_file?

    sample_type = SampleType.new title: 'from template'
    sample_type.content_blob = Factory(:binary_content_blob)
    refute sample_type.compatible_template_file?

    sample_type = SampleType.new title: 'from template'
    sample_type.content_blob = Factory(:rightfield_content_blob)
    refute sample_type.compatible_template_file?

    sample_type = SampleType.new title: 'from template'
    refute sample_type.compatible_template_file?
  end

  test 'projects' do
    sample_type = Factory(:simple_sample_type)
    refute_empty sample_type.projects

    project2 = Factory(:project)
    sample_type.projects = [project2]
    sample_type.save!
    sample_type.reload
    assert_equal [project2], sample_type.projects
  end

  test 'matches content blob?' do
    template_blob = Factory(:sample_type_populated_template_content_blob)
    non_template1 = Factory(:rightfield_content_blob)
    non_template2 = Factory(:binary_content_blob)

    Factory(:string_sample_attribute_type, title: 'String')
    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: @project_ids
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }

    assert sample_type.matches_content_blob?(template_blob)
    refute sample_type.matches_content_blob?(non_template1)
    refute sample_type.matches_content_blob?(non_template2)
  end

  test 'sample_types_matching_content_blob' do
    Factory(:string_sample_attribute_type, title: 'String')
    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: @project_ids
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }

    Factory(:string_sample_attribute_type, title: 'String')
    sample_type2 = SampleType.new title: 'from template', uploaded_template: true, project_ids: @project_ids
    sample_type2.content_blob = Factory(:sample_type_template_content_blob2)
    sample_type2.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }

    template_blob = Factory(:sample_type_populated_template_content_blob)
    non_template1 = Factory(:rightfield_content_blob)

    assert_empty SampleType.sample_types_matching_content_blob(non_template1)
    assert_equal [sample_type], SampleType.sample_types_matching_content_blob(template_blob)
  end

  test 'build samples from template' do
    Factory(:string_sample_attribute_type, title: 'String')
    sample_type = SampleType.new title: 'from template', project_ids: @project_ids
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }

    template_blob = Factory(:sample_type_populated_template_content_blob)
    samples = sample_type.build_samples_from_template(template_blob)
    assert_equal 4, samples.count
    samples.each { |sample| sample.projects = [Factory(:project)] }

    sample = samples.first
    assert sample.valid?
    assert_equal 'Bob Monkhouse', sample.get_attribute(:full_name)
    assert_equal 'Blue', sample.get_attribute(:hair_colour)
    assert_equal 'Yellow', sample.get_attribute(:eye_colour)
    assert_equal Date.parse('12 March 1970'), Date.parse(sample.get_attribute(:date_of_birth))
  end

  test 'dependant destroy content blob' do
    with_config_value :project_admin_sample_type_restriction, false do
      User.with_current_user(@person.user) do
        Factory(:string_sample_attribute_type, title: 'String')
        sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: @project_ids
        sample_type.content_blob = Factory(:sample_type_template_content_blob)
        sample_type.build_attributes_from_template
        sample_type.save!
        blob = sample_type.content_blob

        assert_difference('ContentBlob.count', -1) do
          assert_difference('SampleType.count', -1) do
            sample_type.destroy
          end
        end

        assert blob.destroyed?
      end
    end
  end

  test 'fix up controlled vocabs' do
    type = Factory(:simple_sample_type,project_ids:@project_ids)
    string_attribute = Factory(:simple_string_sample_attribute, sample_type: type, title: 'string type')
    string_attribute.sample_controlled_vocab = Factory(:apples_sample_controlled_vocab)
    type.sample_attributes << string_attribute
    type.sample_attributes << Factory(:apples_controlled_vocab_attribute, sample_type: type, title: 'cv type')

    refute type.valid?
    type.resolve_inconsistencies
    assert_nil type.sample_attributes[0].sample_controlled_vocab
    refute type.sample_attributes[0].controlled_vocab?
    assert_nil type.sample_attributes[1].sample_controlled_vocab
    refute type.sample_attributes[1].controlled_vocab?
    refute_nil type.sample_attributes[2].sample_controlled_vocab
    assert type.sample_attributes[2].controlled_vocab?

    assert type.valid?
  end

  test 'fix up seek samples' do
    type = Factory(:simple_sample_type,project_ids:@project_ids)
    string_attribute = Factory(:simple_string_sample_attribute, sample_type: type, title: 'string type')
    string_attribute.linked_sample_type = Factory(:simple_sample_type)
    type.sample_attributes << string_attribute
    type.sample_attributes << Factory(:sample_sample_attribute, sample_type: type, title: 'seek sample type')

    refute type.valid?
    type.resolve_inconsistencies
    assert_nil type.sample_attributes[0].linked_sample_type
    refute type.sample_attributes[0].seek_sample?
    assert_nil type.sample_attributes[1].linked_sample_type
    refute type.sample_attributes[1].seek_sample?
    refute_nil type.sample_attributes[2].linked_sample_type
    assert type.sample_attributes[2].seek_sample?

    assert type.valid?
  end

  test 'can edit' do
    with_config_value :project_admin_sample_type_restriction, false do
      refute_nil @project
      another_person = Factory(:person)
      type = Factory(:simple_sample_type, project_ids: @project_ids)

      refute_includes another_person.projects, @project

      assert type.can_edit?(@person.user)
      User.with_current_user(@person.user) do
        assert type.can_edit?
      end

      refute type.can_edit?(another_person.user)
      User.with_current_user(another_person.user) do
        refute type.can_edit?
      end

      refute type.can_edit?
      refute type.can_edit?(nil)
    end
    with_config_value :project_admin_sample_type_restriction, true do
      refute @project.can_be_administered_by?(@person)
      type = Factory(:simple_sample_type, project_ids: @project_ids)
      User.with_current_user(@person.user) do
        refute type.can_edit?
      end
      project_admin=Factory(:project_administrator)
      another_project_admin = Factory(:project_administrator)
      admin = Factory(:admin)
      type = Factory(:simple_sample_type, project_ids: [project_admin.projects.first.id])
      assert type.can_edit?(project_admin.user)
      refute type.can_edit?(another_project_admin.user)
      User.with_current_user(project_admin.user) do
        assert type.can_edit?
      end
      User.with_current_user(another_project_admin.user) do
        refute type.can_edit?
      end
      assert type.can_edit?(admin)
      User.with_current_user(admin.user) do
        assert type.can_edit?
      end
    end

  end

  test 'can create' do
    refute @person.is_project_administrator_of_any_project?
    refute SampleType.can_create?
    with_config_value :project_admin_sample_type_restriction, false do
      User.with_current_user @person.user do

        assert SampleType.can_create?
        with_config_value :samples_enabled, false do
          refute SampleType.can_create?
        end
      end
    end

    with_config_value :project_admin_sample_type_restriction, true do
      User.with_current_user @person.user do
        refute SampleType.can_create?
      end
      User.with_current_user Factory(:project_administrator).user do
        assert SampleType.can_create?
      end
      User.with_current_user Factory(:admin).user do
        assert SampleType.can_create?
      end
    end

  end

  test 'linked sample type factory' do
    # test the factory, whilst setting it up
    type = Factory(:linked_sample_type,project_ids:@project_ids)
    assert_equal 2, type.sample_attributes.count
    assert_equal 'title', type.sample_attributes.first.title
    assert_equal 'patient', type.sample_attributes.last.title

    assert_equal 'String', type.sample_attributes.first.sample_attribute_type.base_type
    assert type.sample_attributes.last.sample_attribute_type.seek_sample?
  end

  test 'can delete' do
    with_config_value :project_admin_sample_type_restriction, false do
      type = Factory(:simple_sample_type,project_ids:@project_ids)
      refute type.can_delete?
      assert type.can_delete?(@person.user)
      User.with_current_user(@person.user) do
        assert type.can_delete?

        #cannot delete with samples
        type = Factory(:patient_sample,project_ids:@project_ids).sample_type
        refute type.can_delete?

        # double check the type has been saved (due to an issue when running all tests together)
        refute type.new_record?

        # cannot delete if linked from another sample type
        linked_sample_type = Factory(:linked_sample_type,project_ids:@project_ids)
        linked_attribute = linked_sample_type.sample_attributes.last
        type = linked_attribute.linked_sample_type

        #some sanity checking
        assert_empty type.samples
        assert_include type.projects,@project
        assert type.can_edit?
        refute_equal linked_sample_type,type
        refute type.can_delete?

        assert_no_difference('SampleType.count') do
          assert_difference('SampleAttribute.count', -1) do
            linked_attribute.destroy
          end
        end

        type.reload
        assert type.can_delete?

        #however, can delete if linked to itself
        type = Factory(:linked_sample_type_to_self,project_ids:@project_ids)
        assert_equal type,type.sample_attributes.last.linked_sample_type
        assert type.can_delete?
      end
      another_person = Factory(:person)
      refute_includes another_person.projects,@project
      type = Factory(:simple_sample_type,project_ids:@project_ids)
      refute type.can_delete?(another_person.user)
      User.with_current_user(another_person.user) do
        refute type.can_delete?
      end
    end

    with_config_value :project_admin_sample_type_restriction, true do
      project_admin = Factory(:project_administrator)
      another_project_admin = Factory(:project_administrator)
      seek_admin=Factory(:admin)
      type = Factory(:simple_sample_type,project_ids:[project_admin.projects.first.id])
      refute type.can_delete?
      refute type.can_delete?(@person.user)
      User.with_current_user(@person.user) do
        refute type.can_delete?
      end

      refute type.can_delete?(another_project_admin.user)
      User.with_current_user(another_project_admin.user) do
        refute type.can_delete?
      end

      assert type.can_delete?(project_admin.user)
      User.with_current_user(project_admin.user) do
        assert type.can_delete?
      end

      assert type.can_delete?(seek_admin.user)
      User.with_current_user(seek_admin.user) do
        assert type.can_delete?
      end
    end


  end

  test 'queue template generation' do
    # avoid the callback, which will automatically call queue_template_generation
    SampleType.skip_callback(:save, :after, :queue_template_generation)

    type = Factory(:simple_sample_type,project_ids:@project_ids)
    assert_difference('Delayed::Job.count', 1) do
      type.queue_template_generation
    end

    type_with_uploaded_template = Factory(:simple_sample_type,
                                          content_blob: Factory(:sample_type_template_content_blob),
                                          uploaded_template: true,
                                          project_ids:@project_ids)
    assert_no_difference('Delayed::Job.count') do
      assert_no_difference('ContentBlob.count') do
        type_with_uploaded_template.queue_template_generation
        type_with_uploaded_template = SampleType.find(type_with_uploaded_template.id)
        refute_nil type_with_uploaded_template.content_blob
      end
    end

    type_with_blob = Factory(:simple_sample_type, content_blob: Factory(:sample_type_template_content_blob))
    assert_difference('Delayed::Job.count', 1) do
      assert_difference('ContentBlob.count', -1) do
        type_with_blob.queue_template_generation
        type_with_blob = SampleType.find(type_with_blob.id)
        assert_nil type_with_blob.content_blob
      end
    end

    SampleType.set_callback(:save, :after, :queue_template_generation)
  end

  test 'trigger template generation on save' do
    Delayed::Job.destroy_all
    sample_type = Factory.build(:simple_sample_type,project_ids:@project_ids)
    refute SampleTemplateGeneratorJob.new(sample_type).exists?

    assert sample_type.valid?

    assert sample_type.new_record?
    disable_authorization_checks { sample_type.save! }
    assert SampleTemplateGeneratorJob.new(sample_type).exists?

    sample_type = Factory(:simple_sample_type)
    Delayed::Job.destroy_all
    refute SampleTemplateGeneratorJob.new(sample_type).exists?

    sample_type.title = 'sample type test job'
    disable_authorization_checks { sample_type.save! }
    assert SampleTemplateGeneratorJob.new(sample_type).exists?
  end

  test 'generate template' do
    SampleType.skip_callback(:save, :after, :queue_template_generation)
    sample_type = Factory(:simple_sample_type,project_ids:@project_ids)
    SampleType.set_callback(:save, :after, :queue_template_generation)

    sample_type.generate_template

    refute_nil sample_type.content_blob
    assert File.exist?(sample_type.content_blob.filepath)
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', sample_type.content_blob.content_type
    assert_equal "#{sample_type.title} template.xlsx", sample_type.content_blob.original_filename
  end

  test 'generate template with cv, with quote in label' do
    SampleType.skip_callback(:save, :after, :queue_template_generation)
    sample_type = Factory(:apples_controlled_vocab_sample_type,project_ids:@project_ids)
    sample_type.save!
    SampleType.set_callback(:save, :after, :queue_template_generation)

    #check the quote hasn't been removed from the factory
    assert sample_type.sample_attributes.last.controlled_vocab?
    refute_nil vocab = sample_type.sample_attributes.last.sample_controlled_vocab
    refute_nil vocab.sample_controlled_vocab_terms.collect(&:label).detect{|l| l.include?("Cox's")}
    sample_type.generate_template

    refute_nil sample_type.content_blob
    assert File.exist?(sample_type.content_blob.filepath)
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', sample_type.content_blob.content_type
    assert_equal "#{sample_type.title} template.xlsx", sample_type.content_blob.original_filename

  end

  test 'generate template with cv, with quote in attribute name' do
    SampleType.skip_callback(:save, :after, :queue_template_generation)
    sample_type = Factory(:simple_sample_type,project_ids:@project_ids)
    sample_type.sample_attributes.first.title="With a ' in the title"
    sample_type.sample_attributes.first.save!
    sample_type.save!
    SampleType.set_callback(:save, :after, :queue_template_generation)

    sample_type.generate_template

    refute_nil sample_type.content_blob
    assert File.exist?(sample_type.content_blob.filepath)
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', sample_type.content_blob.content_type
    assert_equal "#{sample_type.title} template.xlsx", sample_type.content_blob.original_filename

  end

  test 'generate template with cv, with double quote in attribute name' do
    SampleType.skip_callback(:save, :after, :queue_template_generation)
    sample_type = Factory(:simple_sample_type,project_ids:@project_ids)
    sample_type.sample_attributes.first.title='With a " in the title'
    sample_type.sample_attributes.first.save!
    sample_type.save!
    SampleType.set_callback(:save, :after, :queue_template_generation)

    sample_type.generate_template

    refute_nil sample_type.content_blob
    assert File.exist?(sample_type.content_blob.filepath)
    assert_equal 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', sample_type.content_blob.content_type
    assert_equal "#{sample_type.title} template.xlsx", sample_type.content_blob.original_filename

  end

  test 'dependant attributes destroyed' do
    with_config_value :project_admin_sample_type_restriction, false do
      User.with_current_user(@person.user) do
        type = Factory(:patient_sample_type,project_ids:@project_ids)
        attribute_count = type.sample_attributes.count

        assert_difference('SampleAttribute.count', -attribute_count) do
          assert_difference('SampleType.count', -1) do
            type.destroy
          end
        end
      end
    end
  end

  test 'tagging' do
    assert SampleType.is_taggable?
    type = Factory(:simple_sample_type)
    assert_empty type.tags
    User.with_current_user(@person.user) do
      type.tags = 'fish,sparrow'
    end
    type.save!
    type = SampleType.find(type.id)
    assert_equal %w(fish sparrow), type.tags.sort
  end

  test 'refresh samples' do
    type = sample_type_with_samples
    sample=type.samples.first
    updated_at = sample.updated_at
    assert_equal 'Fred Blogs',sample.title
    assert_equal 'M12 9LL',sample.get_attribute(:postcode)
    type.sample_attributes.detect{|t| t.title=="full name"}.is_title=false
    type.sample_attributes.detect{|t| t.title=="postcode"}.is_title=true
    disable_authorization_checks{type.save!}
    pretend_now_is(Time.now + 1.minute) do
      type.refresh_samples
    end


    sample.reload
    assert_equal "M12 9LL",sample.title
    #timestamps shouldn't change
    assert_equal updated_at, sample.updated_at

  end

  private

  #sample type with 3 samples
  # - the address attribute includes some blanks
  # - postcode is not required but have values
  # - full name and age are required and always have values
  def sample_type_with_samples


    sample_type= User.with_current_user(@person.user) do
      sample_type=Factory(:patient_sample_type,project_ids:@project_ids)
      sample = Sample.new sample_type:sample_type,project_ids:@project_ids
      sample.set_attribute(:full_name,'Fred Blogs')
      sample.set_attribute(:age,22)
      sample.set_attribute(:weight,12.2)
      sample.set_attribute(:address,'Somewhere')
      sample.set_attribute(:postcode,'M12 9LL')
      sample.save!

      sample = Sample.new sample_type:sample_type,project_ids:@project_ids
      sample.set_attribute(:full_name,'Fred Jones')
      sample.set_attribute(:age,22)
      sample.set_attribute(:weight,12.2)
      sample.set_attribute(:postcode,'M12 9LJ')
      sample.save!

      sample = Sample.new sample_type:sample_type,project_ids:@project_ids
      sample.set_attribute(:full_name,'Fred Smith')
      sample.set_attribute(:age,22)
      sample.set_attribute(:weight,12.2)
      sample.set_attribute(:address,'Somewhere else')
      sample.set_attribute(:postcode,'M12 9LA')
      sample.save!

      sample_type
    end

    sample_type.reload
    assert_equal 3,sample_type.samples.count

    sample_type

  end
end
