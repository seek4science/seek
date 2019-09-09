require 'test_helper'

class SampleTest < ActiveSupport::TestCase

  test 'validation' do
    sample = Factory :sample, title: 'fish', sample_type: Factory(:simple_sample_type), data: { the_title: 'fish' }
    assert sample.valid?
    sample.set_attribute(:the_title, nil)
    refute sample.valid?
    sample.title = ''
    refute sample.valid?

    sample.set_attribute(:the_title, 'fish')
    sample.sample_type = nil
    refute sample.valid?
  end

  test 'can_manage new record' do
    sample = Sample.new(title: 'can manage test')
    assert sample.new_record?
    assert sample.can_manage?

    User.with_current_user(Factory(:user)) do
      assert sample.can_manage?
    end
  end

  test 'test uuid generated' do
    sample = Factory.build(:sample, data: { the_title: 'fish' })
    assert_nil sample.attributes['uuid']
    sample.save
    assert_not_nil sample.attributes['uuid']
  end

  test 'responds to correct methods when sample type assigned' do
    sample = Factory.build(:sample, sample_type: Factory(:patient_sample_type))
    sample.save(validate: false)
    sample = Sample.find(sample.id)
    refute_nil sample.sample_type

    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name'
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name='
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'age'
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'age='
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'postcode'
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'postcode='
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'weight'
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'weight='

    # doesn't affect all sample classes
    sample = Factory(:sample, sample_type: Factory(:simple_sample_type))
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name='
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'age'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'age='
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'postcode'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'postcode='
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'weight'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'weight='
  end

  test 'removes methods with new assigned type' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)

    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name'
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name='

    sample.sample_type = Factory(:simple_sample_type)

    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name='
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'age'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'age='
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'postcode'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'postcode='
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'weight'
    refute_respond_to sample, SampleAttribute::METHOD_PREFIX + 'weight='
  end

  test 'mass assignment' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.update_attributes(data: { full_name: 'Fred Bloggs', age: 25, postcode: 'M12 9QL', weight: 0.22, address: 'somewhere' })
    assert_equal 'Fred Bloggs', sample.get_attribute(:full_name)
    assert_equal 25, sample.get_attribute(:age)
    assert_equal 0.22, sample.get_attribute(:weight)
    assert_equal 'M12 9QL', sample.get_attribute(:postcode)
    assert_equal 'somewhere', sample.get_attribute(:address)
  end

  test 'adds validations' do
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = Factory(:patient_sample_type)
    refute sample.valid?
    sample.set_attribute(:full_name, 'Bob Monkhouse')
    sample.set_attribute(:age, 22)
    assert sample.valid?

    sample.set_attribute(:full_name, 'FRED')
    refute sample.valid?

    sample.set_attribute(:full_name, 'Bob Monkhouse')
    sample.set_attribute(:postcode, 'fish')
    refute sample.valid?
    assert_equal 1, sample.errors.count
    assert_equal 'is not a valid Post Code', sample.errors[(SampleAttribute::METHOD_PREFIX + 'postcode').to_sym].first
    sample.set_attribute(:postcode, 'M13 9PL')
    assert sample.valid?
  end

  test 'removes validations with new assigned type' do
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = Factory(:patient_sample_type)
    refute sample.valid?

    sample.sample_type = Factory(:simple_sample_type)
    sample.set_attribute(:the_title, 'bob')
    assert sample.valid?
  end

  test 'store and retrieve' do
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = Factory(:patient_sample_type)
    sample.set_attribute(:full_name, 'Jimi Hendrix')
    sample.set_attribute(:age, 27)
    sample.set_attribute(:weight, 88.9)
    sample.set_attribute(:postcode, 'M13 9PL')
    disable_authorization_checks { sample.save! }

    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 27, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)

    sample = Sample.find(sample.id)

    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 27, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)

    sample.set_attribute(:age, 28)
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)

    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)
  end

  test 'various methods of sample data assignment' do
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = Factory(:patient_sample_type)
    # Mass assignment
    sample.data = { full_name: 'Jimi Hendrix', age: 27, weight: 88.9, postcode: 'M13 9PL' }
    disable_authorization_checks { sample.save! }

    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 27, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 27, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)

    # Setter
    sample.set_attribute(:age, 28)
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)

    # Method name
    sample.send((SampleAttribute::METHOD_PREFIX + 'postcode=').to_sym, 'M14 8PL')
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M14 8PL', sample.get_attribute(:postcode)

    # Hash
    sample.data[:weight] = 90.1
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 90.1, sample.get_attribute(:weight)
    assert_equal 'M14 8PL', sample.get_attribute(:postcode)
  end

  test 'various methods of sample data assignment perform conversions' do
    sample_type = Factory(:simple_sample_type)
    sample_type.sample_attributes << Factory(:sample_attribute, title: 'bool',
                                                                sample_attribute_type: Factory(:boolean_sample_attribute_type),
                                                                required: false, is_title: false, sample_type: sample_type)
    sample = Sample.new(title: 'testing', sample_type: sample_type, project_ids: [Factory(:project).id])

    # Update attributes
    sample.update_attributes(data: { the_title: 'fish', bool: '0' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert !sample.data[:bool]

    # Mass assignment
    sample.data = { the_title: 'fish', bool: '1' }
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.data[:bool]

    # Setter
    sample.set_attribute(:bool, '0')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert !sample.data[:bool]

    # Method name
    sample.send((SampleAttribute::METHOD_PREFIX + 'bool=').to_sym, '1')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.data[:bool]

    # Hash
    sample.data[:bool] = '0'
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert !sample.data[:bool]
  end

  test 'handling booleans' do
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample_type = Factory(:simple_sample_type)
    sample_type.sample_attributes << Factory(:sample_attribute, title: 'bool', sample_attribute_type: Factory(:boolean_sample_attribute_type), required: false, is_title: false, sample_type: sample_type)
    sample_type.save!
    sample.sample_type = sample_type

    # the simple cases
    sample.update_attributes(data: { the_title: 'fish', bool: true })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title: 'fish', bool: false })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute(:bool)

    # from a form
    sample.update_attributes(data: { the_title: 'fish', bool: '1' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title: 'fish', bool: '0' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute(:bool)

    # as text
    sample.update_attributes(data: { the_title: 'fish', bool: 'true' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title: 'fish', bool: 'false' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute(:bool)

    # as text2
    sample.update_attributes(data: { the_title: 'fish', bool: 'TRUE' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title: 'fish', bool: 'FALSE' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute(:bool)

    # via accessors
    sample.set_attribute(:bool, true)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute(:bool)
    sample.set_attribute(:bool, false)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute(:bool)

    sample.set_attribute(:bool, '1')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute(:bool)
    sample.set_attribute(:bool, '0')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute(:bool)

    sample.set_attribute(:bool, 'true')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute(:bool)
    sample.set_attribute(:bool, 'false')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute(:bool)

    # not valid
    sample.update_attributes(data: { the_title: 'fish', bool: 'fish' })
    refute sample.valid?
    sample.set_attribute(:bool, 'true')
    assert sample.valid?
    sample.set_attribute(:bool, 'fish')
    refute sample.valid?
  end

  test 'json_metadata' do
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = Factory(:patient_sample_type)
    sample.set_attribute(:full_name, 'Jimi Hendrix')
    sample.set_attribute(:age, 27)
    sample.set_attribute(:weight, 88.9)
    sample.set_attribute(:postcode, 'M13 9PL')
    sample.set_attribute(:address, 'Somewhere on earth')
    assert_equal %({"full_name":null,"age":null,"weight":null,"address":null,"postcode":null}), sample.json_metadata
    disable_authorization_checks { sample.save! }
    refute_nil sample.json_metadata
    assert_equal %({"full_name":"Jimi Hendrix","age":27,"weight":88.9,"address":"Somewhere on earth","postcode":"M13 9PL"}), sample.json_metadata
  end

  test 'json metadata with awkward attributes' do
    person = Factory(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, title: 'title', is_title: true, sample_type: sample_type)
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, title: 'updated_at', is_title: false, sample_type: sample_type)
    assert sample_type.valid?
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute(:title, 'the title')
    sample.set_attribute(:updated_at, 'the updated at')
    assert_equal %({"title":null,"updated_at":null}), sample.json_metadata
    disable_authorization_checks { sample.save! }
    assert_equal %({"title":"the title","updated_at":"the updated at"}), sample.json_metadata

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.title
    assert_equal 'the updated at', sample.get_attribute(:updated_at)
  end

  # trying to track down an sqlite3 specific problem
  test 'sqlite3 setting of accessor problem' do
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = Factory(:patient_sample_type)
    sample.set_attribute(:full_name, 'Jimi Hendrix')
    sample.set_attribute(:age, 22)
    disable_authorization_checks { sample.save! }
    id = sample.id
    assert_equal 5, sample.sample_type.sample_attributes.count
    assert_equal %w(full_name age weight address postcode), sample.sample_type.sample_attributes.collect(&:hash_key)
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name'

    sample2 = Sample.find(id)
    assert_equal id, sample2.id
    assert_equal 5, sample2.sample_type.sample_attributes.count
    assert_equal %w(full_name age weight address postcode), sample2.sample_type.sample_attributes.collect(&:hash_key)
    assert_respond_to sample2, SampleAttribute::METHOD_PREFIX + 'full_name'
  end

  test 'projects' do
    person = Factory(:person)
    sample = Factory(:sample, contributor:person)
    project = Factory(:project)
    person.add_to_project_and_institution(project,person.institutions.first)
    sample.update_attributes(project_ids: [project.id])
    disable_authorization_checks { sample.save! }
    sample.reload
    assert_equal [project], sample.projects
  end

  test 'authorization' do
    person = Factory(:person)
    other_person = Factory(:person)
    public_sample = Factory(:sample, policy: Factory(:public_policy), contributor: person)
    private_sample = Factory(:sample, policy: Factory(:private_policy), contributor: person)

    assert public_sample.can_view?(person.user)
    assert public_sample.can_view?(nil)
    assert public_sample.can_view?(other_person.user)
    assert public_sample.can_download?(person.user)
    assert public_sample.can_download?(nil)
    assert public_sample.can_download?(other_person.user)

    assert private_sample.can_view?(person.user)
    refute private_sample.can_view?(nil)
    refute private_sample.can_view?(other_person.user)
    assert private_sample.can_download?(person.user)
    refute private_sample.can_download?(nil)
    refute private_sample.can_download?(other_person.user)

    assert_equal [public_sample, private_sample].sort, Sample.authorized_for('view', person.user).sort
    assert_equal [public_sample], Sample.authorized_for('view', other_person.user)
    assert_equal [public_sample], Sample.authorized_for('view', nil)
    assert_equal [public_sample, private_sample].sort, Sample.authorized_for('download', person.user).sort
    assert_equal [public_sample], Sample.authorized_for('download', other_person.user)
    assert_equal [public_sample], Sample.authorized_for('download', nil)
  end

  test 'assays studies and investigation' do
    assay = Factory(:assay)
    study = assay.study
    investigation = study.investigation
    sample = Factory(:sample, policy: Factory(:publicly_viewable_policy))

    assert_empty sample.assays
    assert_empty sample.studies
    assert_empty sample.investigations

    User.with_current_user(assay.contributor.user) do
      assay.associate(sample)
      assay.save!
    end
    sample.reload

    assert_equal [assay], sample.assays
    assert_equal [study], sample.studies
    assert_equal [investigation], sample.investigations
  end

  test 'cleans up assay asset on destroy' do
    assay = Factory(:assay)
    sample = Factory(:sample, policy: Factory(:public_policy))
    assert_difference('AssayAsset.count', 1) do
      User.with_current_user(assay.contributor.user) do
        assay.associate(sample)
      end
    end
    assay.save!
    sample.reload
    id = sample.id

    refute_empty AssayAsset.where(asset_type: 'Sample', asset_id: id)

    assert_difference('AssayAsset.count', -1) do
      assert sample.destroy
    end
    assert_empty AssayAsset.where(asset_type: 'Sample', asset_id: id)
  end

  test 'title delegated to title attribute on save' do
    sample = Factory.build(:sample, title: 'frog', policy: Factory(:public_policy))
    sample.set_attribute(:the_title, 'this should be the title')
    disable_authorization_checks { sample.save! }
    sample.reload
    assert_equal 'this should be the title', sample.title
  end

  test 'sample with clashing attribute names' do
    person = Factory(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, title: 'freeze', is_title: true, sample_type: sample_type)
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, title: 'updated_at', is_title: false, sample_type: sample_type)
    assert sample_type.valid?
    sample_type.save!
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute(:freeze, 'the title')
    refute sample.valid?
    sample.set_attribute(:updated_at, 'the updated_at')
    disable_authorization_checks { sample.save! }
    assert_equal 'the title', sample.title

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.get_attribute(:freeze)
    assert_equal 'the updated_at', sample.get_attribute(:updated_at)
  end

  test 'sample with clashing attribute names with private methods' do
    person = Factory(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << Factory.build(:any_string_sample_attribute, title: 'format', is_title: true, sample_type: sample_type)
    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute(:format, 'the title')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert_equal 'the title', sample.title

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.get_attribute(:format)
  end

  test 'sample with clashing attribute names with dynamic rails methods' do
    person = Factory(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, title: 'title_before_last_save', is_title: true, sample_type: sample_type)
    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample = Sample.new title: 'testing', project_ids: [Factory(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute(:title_before_last_save, 'the title')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert_equal 'the title', sample.title

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.get_attribute(:title_before_last_save)
  end

  test 'strain type stores valid strain info' do
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal strain.id, sample.get_attribute(:seekstrain)['id']
    assert_equal strain.title, sample.get_attribute(:seekstrain)['title']
  end

  test 'strain as title' do
    sample_type = Factory(:strain_sample_type)
    sample_type.sample_attributes.first.is_title = false
    sample_type.sample_attributes.last.is_title = true
    sample_type.save!

    strain = Factory(:strain, title: 'glow fish')
    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)

    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal 'glow fish', sample.title
  end

  test 'linked sample as title' do
    # setup sample type, to be linked to patient sample type
    patient = Factory(:patient_sample)
    assert_equal 'Fred Bloggs', patient.title
    linked_sample_type = Factory(:linked_sample_type, project_ids: [Factory(:project).id])
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    linked_sample_type.sample_attributes.last.is_title = true
    linked_sample_type.sample_attributes.first.is_title = false

    linked_sample_type.save!

    sample = Sample.new(sample_type: linked_sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:title, 'blah2')
    sample.set_attribute(:patient, patient.id)
    sample.save!
    assert_equal 'Fred Bloggs', sample.title
  end

  test 'strain type still stores missing strain info' do
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)
    invalid_strain_id = Strain.last.id + 1 # non-existant strain ID

    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, invalid_strain_id)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal invalid_strain_id, sample.get_attribute(:seekstrain)['id']
    assert_nil sample.get_attribute(:seekstrain)['title'] # can't look up the title because that strain doesn't exist!
  end

  test 'strain field can be left blank if optional' do
    sample_type = Factory(:optional_strain_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, '')

    assert sample.valid?
  end

  test 'strain field cannot be left blank if required' do
    sample_type = Factory(:strain_sample_type)
    strain_attribute = sample_type.sample_attributes.where(title: 'seekstrain').first

    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, '')

    refute sample.valid?
    assert_not_empty sample.errors[strain_attribute.method_name]
  end

  test 'strain attributes can appear as related items' do
    sample_type = Factory(:strain_sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: 'seekstrain2',
                                                                      sample_attribute_type: Factory(:strain_sample_attribute_type),
                                                                      required: true, sample_type: sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: 'seekstrain3',
                                                                      sample_attribute_type: Factory(:strain_sample_attribute_type),
                                                                      required: true, sample_type: sample_type)
    strain = Factory(:strain)
    strain2 = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    sample.set_attribute(:seekstrain2, strain2.id)
    sample.set_attribute(:seekstrain3, Strain.last.id + 1000) # Non-existant strain id
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal 2, sample.strains.size
    assert_equal [strain.title, strain2.title].sort, [sample.get_attribute(:seekstrain)['title'], sample.get_attribute(:seekstrain2)['title']].sort
  end

  test 'set linked sample by id' do
    # setup sample type, to be linked to patient sample type
    patient = Factory(:patient_sample)
    linked_sample_type = Factory(:linked_sample_type, project_ids: [Factory(:project).id])
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    linked_sample_type.save!

    sample = Sample.new(sample_type: linked_sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:title, 'blah')
    sample.set_attribute(:patient, patient.id)
    assert sample.valid?
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)

    assert_equal patient.id, sample.get_attribute(:patient)['id']
    assert_equal [patient], sample.related_samples
  end

  test 'set linked sample by title' do
    # setup sample type, to be linked to patient sample type
    patient = Factory(:patient_sample)
    linked_sample_type = Factory(:linked_sample_type, project_ids: [Factory(:project).id])
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type

    linked_sample_type.save!

    sample = Sample.new(sample_type: linked_sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:title, 'blah2')
    sample.set_attribute(:patient, patient.title)

    assert sample.valid?
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)

    assert_equal [patient], sample.related_samples

    # invalid when title not recognised
    sample = Sample.new(sample_type: linked_sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:title, 'blah3')
    sample.set_attribute(:patient, 'a b c d e f 123')
    refute sample.valid?
  end



  test 'can create' do
    refute Sample.can_create?
    User.with_current_user Factory(:person).user do
      assert Sample.can_create?
      with_config_value :samples_enabled, false do
        refute Sample.can_create?
      end
    end
  end

  test 'is favouritable?' do
    sample = Factory(:sample)
    assert sample.is_favouritable?
  end

  test 'sample responds to correct methods' do
    person = Factory(:person)
    sample_type = SampleType.new(title: 'Custom', projects: person.projects, contributor: person)
    attribute1 = Factory(:any_string_sample_attribute, title: 'banana_type',
                                                       is_title: true, sample_type: sample_type)
    attribute2 = Factory(:any_string_sample_attribute, title: 'license',
                                                       sample_type: sample_type)
    sample_type.sample_attributes << attribute1
    sample_type.sample_attributes << attribute2
    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample = Sample.new(title: 'testing', project_ids: [Factory(:project).id])
    sample.sample_type = sample_type
    sample.set_attribute(:banana_type, 'yellow')
    sample.set_attribute(:license, 'GPL')
    assert sample.valid?
    disable_authorization_checks { sample.save! }

    assert sample.respond_to?(attribute1.method_name.to_sym)
    assert sample.respond_to?(attribute2.method_name.to_sym)
    refute sample.respond_to?(SampleAttribute::METHOD_PREFIX + 'hello_kitty')
    refute sample.respond_to?(:banana_type)
    refute sample.respond_to?(:license)

    assert_raises(NoMethodError) do
      sample.license
    end

    assert_raises(NoMethodError) do
      sample.banana_type
    end

    assert_nothing_raised do
      sample.send(attribute1.method_name.to_sym)
    end
  end

  test 'samples extracted from a data file cannot be edited' do
    sample = Factory(:sample_from_file)

    refute sample.state_allows_edit?
  end

  test 'samples not extracted from a data file can be edited' do
    sample = Factory(:sample)

    assert sample.state_allows_edit?
  end

  test 'extracted samples inherit permissions from data file' do
    person = Factory(:person)
    other_person = Factory(:person)
    sample_type = Factory(:strain_sample_type)
    data_file = Factory(:strain_sample_data_file, policy: Factory(:public_policy), contributor: person)

    samples = data_file.extract_samples(sample_type, true)
    sample = samples.first

    assert sample.can_view?(person.user)
    assert sample.can_view?(nil)
    assert sample.can_view?(other_person.user)

    policy = data_file.policy
    disable_authorization_checks do
      policy.access_type = Policy::NO_ACCESS
      policy.save
      sample.reload
    end

    assert sample.can_view?(person.user)
    refute sample.can_view?(nil)
    refute sample.can_view?(other_person.user)
  end

  test 'sample policy persists even after originating data file deleted' do
    person = Factory(:person)
    sample_type = Factory(:strain_sample_type)
    data_file = Factory(:strain_sample_data_file, policy: Factory(:public_policy), contributor: person)
    samples = data_file.extract_samples(sample_type, true)
    sample = samples.first

    assert_equal sample.policy_id, data_file.policy_id

    old_policy_id = sample.policy_id
    disable_authorization_checks { data_file.destroy }

    assert_not_nil sample.reload.policy
    assert_equal old_policy_id, sample.policy_id
  end

  test 'extracted samples inherit projects from data file' do
    person = Factory(:person)
    create_sample_attribute_type
    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                                    policy: Factory(:private_policy), contributor:person
    sample_type = SampleType.new title: 'from template', projects: person.projects, contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }
    samples = data_file.extract_samples(sample_type, true)
    sample = samples.first

    assert_equal sample.projects, data_file.projects
    assert_equal sample.project_ids, data_file.project_ids

    # Change the projects
    new_projects = [Factory(:project), Factory(:project)]
    new_projects.each{|p| person.add_to_project_and_institution(p,person.institutions.first)}
    disable_authorization_checks do
      data_file.projects = new_projects
      data_file.save!
    end

    assert_equal new_projects.sort, sample.projects.sort
    assert_equal sample.projects.sort, data_file.projects.sort
    assert_equal sample.project_ids.sort, data_file.project_ids.sort
  end

  test 'extracted samples inherit creators from data file' do
    create_sample_attribute_type
    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                                    policy: Factory(:private_policy)
    person = Factory(:person)
    sample_type = SampleType.new title: 'from template', projects: person.projects, contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }
    samples = data_file.extract_samples(sample_type, true)
    sample = samples.first
    creator = Factory(:person)

    assert_equal sample.creators, data_file.creators
    assert_not_includes sample.creators, creator

    refute data_file.can_view?(creator.user)
    refute sample.can_view?(creator.user)
    refute sample.can_view?(nil)

    # Add a creator
    disable_authorization_checks do
      data_file.creators << creator
      data_file.save!
    end

    assert_includes data_file.creators, creator
    assert_includes sample.creators, creator

    assert data_file.can_view?(creator.user)
    assert sample.can_view?(creator.user)
    refute sample.can_view?(nil)
  end

  test 'can overwrite existing samples when extracting from data file' do
    person = Factory(:person)
    project_ids = [person.projects.first.id]

    disable_authorization_checks do
      source_type = Factory(:source_sample_type, project_ids: project_ids)
      lib1 = source_type.samples.create(data: { title: 'Lib-1', info: 'bla' }, sample_type: source_type, project_ids: project_ids)
      lib2 = source_type.samples.create(data: { title: 'Lib-2', info: 'bla' }, sample_type: source_type, project_ids: project_ids)
      lib3 = source_type.samples.create(data: { title: 'Lib-3', info: 'bla' }, sample_type: source_type, project_ids: project_ids)
      lib4 = source_type.samples.create(data: { title: 'Lib-4', info: 'bla' }, sample_type: source_type, project_ids: project_ids)

      assert_equal 4, source_type.samples.count

      type = SampleType.new(title: 'Sample type linked to other', project_ids: project_ids, contributor: person)
      type.sample_attributes << Factory.build(:sample_attribute, title: 'title', template_column_index: 1,
                                              sample_attribute_type: Factory(:string_sample_attribute_type),
                                              required: true, is_title: true, sample_type: type)
      type.sample_attributes << Factory.build(:sample_attribute, title: 'library id', template_column_index: 2,
                                              sample_attribute_type: Factory(:sample_sample_attribute_type),
                                              required: false, sample_type: type, linked_sample_type: source_type)
      type.sample_attributes << Factory.build(:sample_attribute, title: 'info', template_column_index: 3,
                                              sample_attribute_type: Factory(:string_sample_attribute_type),
                                              required: false, sample_type: type)
      type.save!

      data_file = Factory(:data_file, content_blob: Factory(:linked_samples_incomplete_content_blob), project_ids: project_ids, contributor:person)

      assert_difference('Sample.count', 4) do
        data_file.extract_samples(type, true, false)
      end

      assert_equal [lib1, lib2], data_file.extracted_samples.map { |s| s.related_samples }.flatten.sort

      data_file.content_blob = Factory(:linked_samples_complete_content_blob)
      data_file.save!

      assert_difference('Sample.count', 1) do # Spreadsheet contains 4 updated samples and 1 new one
        data_file.extract_samples(type, true, true)
      end

      assert_equal [lib1, lib2, lib3, lib4], data_file.reload.extracted_samples.map { |s| s.related_samples }.flatten.uniq.sort
    end
  end

  test 'strains linked through join table' do
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)

    assert_includes sample.referenced_strains, strain
    assert_not_includes sample.strains, strain
    assert_not_includes strain.samples, sample

    assert_difference('SampleResourceLink.count', 1) do
      disable_authorization_checks { sample.save }
    end

    assert_includes sample.referenced_strains, strain
    assert_includes sample.referenced_resources, strain
    assert_includes sample.strains, strain
    assert_includes strain.samples, sample
  end

  test 'link to strain removed when no longer referenced' do
    sample_type = Factory(:optional_strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [Factory(:project).id])
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    disable_authorization_checks { sample.save }

    assert_difference('SampleResourceLink.count', -1) do
      sample.set_attribute(:seekstrain, '')
      disable_authorization_checks { sample.save }
    end

    assert_not_includes sample.referenced_strains, strain
    assert_not_includes sample.referenced_resources, strain
    assert_not_includes sample.strains, strain
    assert_not_includes strain.samples, sample
  end

  test 'samples linked through join table' do
    project = Factory(:project)
    sample_type = Factory(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = Factory(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id])
    sample.set_attribute(:title, 'Linking sample')
    sample.set_attribute(:patient, linked_sample.id)

    assert_includes sample.referenced_samples, linked_sample
    assert_includes sample.referenced_samples, linked_sample
    assert_not_includes sample.linked_samples, linked_sample
    assert_not_includes linked_sample.linking_samples, sample

    assert_difference('SampleResourceLink.count', 1) do
      disable_authorization_checks { sample.save }
    end

    assert_includes sample.referenced_samples, linked_sample
    assert_includes sample.referenced_resources, linked_sample
    assert_includes sample.linked_samples, linked_sample
    assert_includes linked_sample.linking_samples, sample # linked both ways
  end

  test 'samples unlinked when no longer referenced' do
    project = Factory(:project)
    sample_type = Factory(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = Factory(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id],
                        data: { title: 'Linking sample',
                                patient: linked_sample.id})

    disable_authorization_checks { sample.save! }

    assert_includes sample.referenced_samples, linked_sample
    assert_includes sample.referenced_resources, linked_sample
    assert_includes sample.linked_samples, linked_sample
    assert_includes linked_sample.linking_samples, sample

    assert_difference('SampleResourceLink.count', -1) do
      sample.set_attribute(:patient, '')
      disable_authorization_checks { sample.save! }
    end

    assert_not_includes sample.referenced_samples, linked_sample
    assert_not_includes sample.referenced_resources, linked_sample
    assert_not_includes sample.linked_samples, linked_sample
    assert_not_includes linked_sample.linking_samples, sample
  end

  test 'samples unlinked when source destroyed' do
    project = Factory(:project)
    sample_type = Factory(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = Factory(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id],
                        data: { title: 'Linking sample',
                                patient: linked_sample.id})

    disable_authorization_checks { sample.save! }

    assert_difference('SampleResourceLink.count', -1) do
      disable_authorization_checks { sample.destroy! }
    end
  end

  test 'samples unlinked when destination destroyed' do
    project = Factory(:project)
    sample_type = Factory(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = Factory(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id],
                        data: { title: 'Linking sample',
                                patient: linked_sample.id})

    disable_authorization_checks { sample.save! }

    assert_difference('SampleResourceLink.count', -1) do
      disable_authorization_checks { linked_sample.destroy! }
    end
  end

  test 'related organisms through ncbi id' do
    org1 = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_12345'))
    org2 = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/12345'))
    org3 = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/12346'))
    org4 = Factory(:organism, bioportal_concept: Factory(:bioportal_concept, concept_uri: nil))
    org5 = Factory(:organism, bioportal_concept: nil)

    sample_type = Factory(:simple_sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: 'ncbi',
                                                   sample_attribute_type: Factory(:ncbi_id_sample_attribute_type),
                                                   required: false,
                                                   sample_type: sample_type)
    sample_type.save!

    contributor = Factory(:person)
    User.with_current_user(contributor.user) do

      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor:contributor)
      sample.set_attribute(:the_title,'testing related orgs')
      sample.set_attribute(:ncbi,"12345")
      sample.save!

      assert_equal [org1,org2].sort,sample.related_organisms.sort
    end

    #with nil ncbi id
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor:contributor)
      sample.set_attribute(:the_title,'testing related orgs')
      sample.set_attribute(:ncbi,nil)
      sample.save!

      assert_empty sample.related_organisms
    end

    #with blank ncbi id
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor:contributor)
      sample.set_attribute(:the_title,'testing related orgs')
      sample.set_attribute(:ncbi,'')
      sample.save!

      assert_empty sample.related_organisms
    end

    #with partially matching ncbi id
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor:contributor)
      sample.set_attribute(:the_title,'testing related orgs')
      sample.set_attribute(:ncbi,'345')
      sample.save!

      assert_empty sample.related_organisms
    end

    #shouldn't be duplicates
    sample_type = Factory(:simple_sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: 'ncbi',
                                                   sample_attribute_type: Factory(:ncbi_id_sample_attribute_type),
                                                   required: true,
                                                   sample_type: sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: 'ncbi2',
                                                   sample_attribute_type: Factory(:ncbi_id_sample_attribute_type),
                                                   required: true,
                                                   sample_type: sample_type)
    sample_type.save!
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor:contributor)
      sample.set_attribute(:the_title,'testing related orgs')
      sample.set_attribute(:ncbi,'12345')
      sample.set_attribute(:ncbi2,'12345')
      sample.save!

      assert_equal [org1,org2].sort,sample.related_organisms.sort
    end

    #handles capitalized attribute name
    sample_type = Factory(:simple_sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: 'NcBi',
                                                   sample_attribute_type: Factory(:ncbi_id_sample_attribute_type),
                                                   required: true,
                                                   sample_type: sample_type)
    sample_type.save!
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor:contributor)
      sample.set_attribute(:the_title,'testing related orgs')
      sample.set_attribute(:ncbi,'12345')
      sample.save!

      assert_equal [org1,org2].sort,sample.related_organisms.sort
    end

  end


end
