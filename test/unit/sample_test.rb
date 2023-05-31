require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  test 'validation' do
    sample = FactoryBot.create :sample, title: 'fish', sample_type: FactoryBot.create(:simple_sample_type), data: { the_title: 'fish' }
    assert sample.valid?
    sample.set_attribute_value(:the_title, nil)
    refute sample.valid?
    sample.title = ''
    refute sample.valid?

    sample.set_attribute_value(:the_title, 'fish')
    sample.sample_type = nil
    refute sample.valid?
  end

  test 'can_manage new record' do
    sample = Sample.new(title: 'can manage test')
    assert sample.new_record?
    assert sample.can_manage?

    User.with_current_user(FactoryBot.create(:user)) do
      assert sample.can_manage?
    end
  end

  test 'test uuid generated' do
    sample = FactoryBot.build(:sample, data: { the_title: 'fish' })
    assert_nil sample.attributes['uuid']
    sample.save
    assert_not_nil sample.attributes['uuid']
  end

  test 'mass assignment' do
    sample = Sample.new title: 'testing'
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    sample.update(data: { 'full name': 'Fred Bloggs', age: 25, postcode: 'M12 9QL', weight: 0.22, address: 'somewhere' })
    assert_equal 'Fred Bloggs', sample.get_attribute_value('full name')
    assert_equal 25, sample.get_attribute_value(:age)
    assert_equal 0.22, sample.get_attribute_value(:weight)
    assert_equal 'M12 9QL', sample.get_attribute_value(:postcode)
    assert_equal 'somewhere', sample.get_attribute_value(:address)
  end

  test 'adds validations' do
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    refute sample.valid?
    sample.set_attribute_value('full name', 'Bob Monkhouse')
    assert_equal 'Bob Monkhouse', sample.get_attribute_value('full name')
    sample.set_attribute_value(:age, 22)
    assert sample.valid?

    sample.set_attribute_value('full name', 'FRED')
    refute sample.valid?

    sample.set_attribute_value('full name', 'Bob Monkhouse')
    sample.set_attribute_value(:postcode, 'fish')
    refute sample.valid?
    assert_equal 1, sample.errors.count
    assert_equal 'is not a valid Post Code', sample.errors['postcode'.to_sym].first
    sample.set_attribute_value(:postcode, 'M13 9PL')
    assert sample.valid?
  end

  test 'removes validations with new assigned type' do
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    refute sample.valid?

    sample.sample_type = FactoryBot.create(:simple_sample_type)
    sample.set_attribute_value(:the_title, 'bob')
    assert sample.valid?
  end

  test 'store and retrieve' do
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    sample.set_attribute_value('full name', 'Jimi Hendrix')
    sample.set_attribute_value(:age, 27)
    sample.set_attribute_value(:weight, 88.9)
    sample.set_attribute_value(:postcode, 'M13 9PL')
    disable_authorization_checks { sample.save! }

    assert_equal 'Jimi Hendrix', sample.get_attribute_value('full name')
    assert_equal 27, sample.get_attribute_value(:age)
    assert_equal 88.9, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)

    sample = Sample.find(sample.id)

    assert_equal 'Jimi Hendrix', sample.get_attribute_value('full name')
    assert_equal 27, sample.get_attribute_value(:age)
    assert_equal 88.9, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)

    sample.set_attribute_value(:age, 28)
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)

    assert_equal 'Jimi Hendrix', sample.get_attribute_value('full name')
    assert_equal 28, sample.get_attribute_value(:age)
    assert_equal 88.9, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)
  end

  test 'various methods of sample data assignment' do
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    # Mass assignment
    sample.data = { 'full name': 'Jimi Hendrix', age: 27, weight: 88.9, postcode: 'M13 9PL' }
    disable_authorization_checks { sample.save! }

    assert_equal 'Jimi Hendrix', sample.get_attribute_value('full name')
    assert_equal 27, sample.get_attribute_value(:age)
    assert_equal 88.9, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute_value('full name')
    assert_equal 27, sample.get_attribute_value(:age)
    assert_equal 88.9, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)

    # Setter
    sample.set_attribute_value(:age, 28)
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute_value('full name')
    assert_equal 28, sample.get_attribute_value(:age)
    assert_equal 88.9, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)

    # Hash
    sample.data[:weight] = 90.1
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute_value('full name')
    assert_equal 28, sample.get_attribute_value(:age)
    assert_equal 90.1, sample.get_attribute_value(:weight)
    assert_equal 'M13 9PL', sample.get_attribute_value(:postcode)
  end

  test 'various methods of sample data assignment perform conversions' do
    sample_type = FactoryBot.create(:simple_sample_type)
    sample_type.sample_attributes << FactoryBot.create(:sample_attribute, title: 'bool',
                                                                sample_attribute_type: FactoryBot.create(:boolean_sample_attribute_type),
                                                                required: false, is_title: false, sample_type: sample_type)
    sample = Sample.new(title: 'testing', sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])

    # Update attributes
    sample.update(data: { the_title: 'fish', bool: '0' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert !sample.data[:bool]

    # Mass assignment
    sample.data = { the_title: 'fish', bool: '1' }
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.data[:bool]

    # Setter
    sample.set_attribute_value(:bool, '0')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert !sample.data[:bool]

    # Hash
    sample.data[:bool] = '0'
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert !sample.data[:bool]
  end

  test 'handling booleans' do
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample_type = FactoryBot.create(:simple_sample_type)
    sample_type.sample_attributes << FactoryBot.create(:sample_attribute, title: 'bool', sample_attribute_type: FactoryBot.create(:boolean_sample_attribute_type), required: false, is_title: false, sample_type: sample_type)
    sample_type.save!
    sample.sample_type = sample_type

    # the simple cases
    sample.update(data: { the_title: 'fish', bool: true })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute_value(:bool)

    sample.update(data: { the_title: 'fish', bool: false })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute_value(:bool)

    # from a form
    sample.update(data: { the_title: 'fish', bool: '1' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute_value(:bool)

    sample.update(data: { the_title: 'fish', bool: '0' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute_value(:bool)

    # as text
    sample.update(data: { the_title: 'fish', bool: 'true' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute_value(:bool)

    sample.update(data: { the_title: 'fish', bool: 'false' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute_value(:bool)

    # as text2
    sample.update(data: { the_title: 'fish', bool: 'TRUE' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute_value(:bool)

    sample.update(data: { the_title: 'fish', bool: 'FALSE' })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute_value(:bool)

    # via accessors
    sample.set_attribute_value(:bool, true)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute_value(:bool)
    sample.set_attribute_value(:bool, false)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute_value(:bool)

    sample.set_attribute_value(:bool, '1')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute_value(:bool)
    sample.set_attribute_value(:bool, '0')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute_value(:bool)

    sample.set_attribute_value(:bool, 'true')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert sample.get_attribute_value(:bool)
    sample.set_attribute_value(:bool, 'false')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    refute sample.get_attribute_value(:bool)

    sample.update(data: { the_title: 'fish', bool: '' })
    assert sample.valid?
    sample.update(data: { the_title: 'fish', bool: nil })
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert_nil sample.get_attribute_value(:bool)

    # not valid
    sample.update(data: { the_title: 'fish', bool: 'fish' })
    refute sample.valid?
    sample.set_attribute_value(:bool, 'true')
    assert sample.valid?
    sample.set_attribute_value(:bool, 'fish')
    refute sample.valid?


    # with required attribute
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample_type = FactoryBot.create(:simple_sample_type)
    sample_type.sample_attributes << FactoryBot.create(:sample_attribute, title: 'bool', sample_attribute_type: FactoryBot.create(:boolean_sample_attribute_type), required: true, is_title: false, sample_type: sample_type)
    sample_type.save!
    sample.sample_type = sample_type

    sample.update(data: { the_title: 'fish', bool: 'true' })
    assert sample.valid?
    sample.update(data: { the_title: 'fish', bool: true })
    assert sample.valid?
    sample.update(data: { the_title: 'fish', bool: false })
    assert sample.valid?
    sample.update(data: { the_title: 'fish', bool: 'false' })
    assert sample.valid?
    sample.update(data: { the_title: 'fish', bool: nil })
    refute sample.valid?
    sample.update(data: { the_title: 'fish', bool: '' })
    refute sample.valid?
  end

  test 'json_metadata' do
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    sample.set_attribute_value('full name', 'Jimi Hendrix')
    sample.set_attribute_value(:age, 27)
    sample.set_attribute_value(:weight, 88.9)
    sample.set_attribute_value(:postcode, 'M13 9PL')
    sample.set_attribute_value(:address, 'Somewhere on earth')
    assert_equal %({"full name":null,"age":null,"weight":null,"address":null,"postcode":null}), sample.json_metadata
    disable_authorization_checks { sample.save! }
    refute_nil sample.json_metadata
    assert_equal %({"full name":"Jimi Hendrix","age":27,"weight":88.9,"address":"Somewhere on earth","postcode":"M13 9PL"}), sample.json_metadata
  end

  test 'json metadata with awkward attributes' do
    person = FactoryBot.create(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << FactoryBot.create(:any_string_sample_attribute, title: 'title', is_title: true, sample_type: sample_type)
    sample_type.sample_attributes << FactoryBot.create(:any_string_sample_attribute, title: 'updated_at', is_title: false, sample_type: sample_type)
    assert sample_type.valid?
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute_value(:title, 'the title')
    sample.set_attribute_value(:updated_at, 'the updated at')
    assert_equal %({"title":null,"updated_at":null}), sample.json_metadata
    disable_authorization_checks { sample.save! }
    assert_equal %({"title":"the title","updated_at":"the updated at"}), sample.json_metadata

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.title
    assert_equal 'the updated at', sample.get_attribute_value(:updated_at)
  end

  # trying to track down an sqlite3 specific problem
  test 'sqlite3 setting of original accessor problem' do
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = FactoryBot.create(:patient_sample_type)
    sample.set_attribute_value('full name', 'Jimi Hendrix')
    sample.set_attribute_value(:age, 22)
    disable_authorization_checks { sample.save! }
    id = sample.id
    assert_equal 5, sample.sample_type.sample_attributes.count
    assert_equal ['full name', 'age', 'weight', 'address', 'postcode'], sample.sample_type.sample_attributes.collect(&:accessor_name)

    sample2 = Sample.find(id)
    assert_equal id, sample2.id
    assert_equal 5, sample2.sample_type.sample_attributes.count
    assert_equal ['full name', 'age', 'weight', 'address', 'postcode'], sample2.sample_type.sample_attributes.collect(&:original_accessor_name)
  end

  test 'projects' do
    person = FactoryBot.create(:person)
    sample = FactoryBot.create(:sample, contributor: person)
    project = FactoryBot.create(:project)
    person.add_to_project_and_institution(project, person.institutions.first)
    sample.update(project_ids: [project.id])
    disable_authorization_checks { sample.save! }
    sample.reload
    assert_equal [project], sample.projects
  end

  test 'authorization' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    public_sample = FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy), contributor: person)
    private_sample = FactoryBot.create(:sample, policy: FactoryBot.create(:private_policy), contributor: person)

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
    assay = FactoryBot.create(:assay)
    study = assay.study
    investigation = study.investigation
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:publicly_viewable_policy))

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
    assay = FactoryBot.create(:assay)
    sample = FactoryBot.create(:sample, policy: FactoryBot.create(:public_policy))
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
    sample = FactoryBot.build(:sample, title: 'frog', policy: FactoryBot.create(:public_policy))
    sample.set_attribute_value(:the_title, 'this should be the title')
    disable_authorization_checks { sample.save! }
    sample.reload
    assert_equal 'this should be the title', sample.title
  end

  test 'sample with clashing attribute names' do
    person = FactoryBot.create(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << FactoryBot.create(:any_string_sample_attribute, title: 'freeze', is_title: true, sample_type: sample_type)
    sample_type.sample_attributes << FactoryBot.create(:any_string_sample_attribute, title: 'updated_at', is_title: false, sample_type: sample_type)
    assert sample_type.valid?
    sample_type.save!
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute_value(:freeze, 'the title')
    refute sample.valid?
    sample.set_attribute_value(:updated_at, 'the updated_at')
    disable_authorization_checks { sample.save! }
    assert_equal 'the title', sample.title

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.get_attribute_value(:freeze)
    assert_equal 'the updated_at', sample.get_attribute_value(:updated_at)
  end

  test 'sample with clashing attribute names with private methods' do
    person = FactoryBot.create(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << FactoryBot.build(:any_string_sample_attribute, title: 'format', is_title: true, sample_type: sample_type)
    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute_value(:format, 'the title')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert_equal 'the title', sample.title

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.get_attribute_value(:format)
  end

  test 'sample with clashing attribute names with dynamic rails methods' do
    person = FactoryBot.create(:person)
    sample_type = SampleType.new title: 'with awkward attributes', projects: person.projects, contributor: person
    sample_type.sample_attributes << FactoryBot.create(:any_string_sample_attribute, title: 'title_before_last_save', is_title: true, sample_type: sample_type)
    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample = Sample.new title: 'testing', project_ids: [FactoryBot.create(:project).id]
    sample.sample_type = sample_type

    sample.set_attribute_value(:title_before_last_save, 'the title')
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    assert_equal 'the title', sample.title

    sample = Sample.find(sample.id)
    assert_equal 'the title', sample.title
    assert_equal 'the title', sample.get_attribute_value(:title_before_last_save)
  end

  test 'strain type stores valid strain info' do
    sample_type = FactoryBot.create(:strain_sample_type)
    strain = FactoryBot.create(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal strain.id, sample.get_attribute_value(:seekstrain)['id']
    assert_equal strain.title, sample.get_attribute_value(:seekstrain)['title']
  end

  test 'strain as title' do
    sample_type = FactoryBot.create(:strain_sample_type)
    sample_type.sample_attributes.first.is_title = false
    sample_type.sample_attributes.last.is_title = true
    sample_type.save!

    strain = FactoryBot.create(:strain, title: 'glow fish')
    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)

    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal 'glow fish', sample.title
  end

  test 'linked sample as title' do
    # setup sample type, to be linked to patient sample type
    patient = FactoryBot.create(:patient_sample)
    assert_equal 'Fred Bloggs', patient.title
    linked_sample_type = FactoryBot.create(:linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    linked_sample_type.sample_attributes.last.is_title = true
    linked_sample_type.sample_attributes.first.is_title = false

    linked_sample_type.save!

    sample = Sample.new(sample_type: linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:title, 'blah2')
    sample.set_attribute_value(:patient, patient.id)
    sample.save!
    assert_equal 'Fred Bloggs', sample.title
  end

  test 'strain type still stores missing strain info' do
    sample_type = FactoryBot.create(:strain_sample_type)
    strain = FactoryBot.create(:strain)
    invalid_strain_id = Strain.last.id + 1 # non-existant strain ID

    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, invalid_strain_id)
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal invalid_strain_id, sample.get_attribute_value(:seekstrain)['id']
    assert_nil sample.get_attribute_value(:seekstrain)['title'] # can't look up the title because that strain doesn't exist!
  end

  test 'strain field can be left blank if optional' do
    sample_type = FactoryBot.create(:optional_strain_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, '')

    assert sample.valid?
  end

  test 'strain field cannot be left blank if required' do
    sample_type = FactoryBot.create(:strain_sample_type)
    strain_attribute = sample_type.sample_attributes.where(title: 'seekstrain').first

    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, '')

    refute sample.valid?
    assert_not_empty sample.errors[strain_attribute.title]
  end

  test 'strain attributes can appear as related items' do
    sample_type = FactoryBot.create(:strain_sample_type)
    sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'seekstrain2',
                                                                      sample_attribute_type: FactoryBot.create(:strain_sample_attribute_type),
                                                                      required: true, sample_type: sample_type)
    sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'seekstrain3',
                                                                      sample_attribute_type: FactoryBot.create(:strain_sample_attribute_type),
                                                                      required: true, sample_type: sample_type)
    strain = FactoryBot.create(:strain)
    strain2 = FactoryBot.create(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    sample.set_attribute_value(:seekstrain2, strain2.id)
    sample.set_attribute_value(:seekstrain3, Strain.last.id + 1000) # Non-existant strain id
    assert sample.valid?
    disable_authorization_checks { sample.save! }
    sample = Sample.find(sample.id)

    assert_equal 2, sample.strains.size
    assert_equal [strain.title, strain2.title].sort, [sample.get_attribute_value(:seekstrain)['title'], sample.get_attribute_value(:seekstrain2)['title']].sort
  end

  test 'set linked sample by id' do
    # setup sample type, to be linked to patient sample type
    patient = FactoryBot.create(:patient_sample)
    linked_sample_type = FactoryBot.create(:linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    linked_sample_type.save!

    sample = Sample.new(sample_type: linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:title, 'blah')
    sample.set_attribute_value(:patient, patient.id)
    assert sample.valid?
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)

    assert_equal patient.id, sample.get_attribute_value(:patient)['id']
    assert_equal [patient], sample.related_samples
  end

  test 'set linked sample by title' do
    # setup sample type, to be linked to patient sample type
    patient = FactoryBot.create(:patient_sample)
    linked_sample_type = FactoryBot.create(:linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type

    linked_sample_type.save!

    sample = Sample.new(sample_type: linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:title, 'blah2')
    sample.set_attribute_value(:patient, patient.title)

    assert sample.valid?
    disable_authorization_checks { sample.save! }

    sample = Sample.find(sample.id)

    assert_equal [patient], sample.related_samples

    # invalid when title not recognised
    sample = Sample.new(sample_type: linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:title, 'blah3')
    sample.set_attribute_value(:patient, 'a b c d e f 123')
    refute sample.valid?
  end

  test 'can create' do
    refute Sample.can_create?
    User.with_current_user FactoryBot.create(:person).user do
      assert Sample.can_create?
      with_config_value :samples_enabled, false do
        refute Sample.can_create?
      end
    end
  end

  test 'is favouritable?' do
    sample = FactoryBot.create(:sample)
    assert sample.is_favouritable?
  end

  test 'sample responds to correct methods' do
    person = FactoryBot.create(:person)
    sample_type = SampleType.new(title: 'Custom', projects: person.projects, contributor: person)
    attribute1 = FactoryBot.create(:any_string_sample_attribute, title: 'banana_type',
                                                       is_title: true, sample_type: sample_type)
    attribute2 = FactoryBot.create(:any_string_sample_attribute, title: 'license',
                                                       sample_type: sample_type)
    sample_type.sample_attributes << attribute1
    sample_type.sample_attributes << attribute2
    assert sample_type.valid?
    disable_authorization_checks { sample_type.save! }
    sample = Sample.new(title: 'testing', project_ids: [FactoryBot.create(:project).id])
    sample.sample_type = sample_type
    sample.set_attribute_value(:banana_type, 'yellow')
    sample.set_attribute_value(:license, 'GPL')
    assert sample.valid?
    disable_authorization_checks { sample.save! }

    refute sample.respond_to?(:banana_type)
    refute sample.respond_to?(:license)

    assert_raises(NoMethodError) do
      sample.license
    end

    assert_raises(NoMethodError) do
      sample.banana_type
    end
  end

  test 'samples extracted from a data file cannot be edited' do
    sample = FactoryBot.create(:sample_from_file)

    refute sample.state_allows_edit?
  end

  test 'samples not extracted from a data file can be edited' do
    sample = FactoryBot.create(:sample)

    assert sample.state_allows_edit?
  end

  test 'extracted samples inherit permissions from data file' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:strain_sample_type)
    data_file = FactoryBot.create(:strain_sample_data_file, policy: FactoryBot.create(:public_policy), contributor: person)

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
    person = FactoryBot.create(:person)
    sample_type = FactoryBot.create(:strain_sample_type)
    data_file = FactoryBot.create(:strain_sample_data_file, policy: FactoryBot.create(:public_policy), contributor: person)
    samples = data_file.extract_samples(sample_type, true)
    sample = samples.first

    assert_equal sample.policy_id, data_file.policy_id

    old_policy_id = sample.policy_id
    disable_authorization_checks { data_file.destroy }

    assert_not_nil sample.reload.policy
    assert_equal old_policy_id, sample.policy_id
  end

  test 'extracted samples inherit projects from data file' do
    person = FactoryBot.create(:person)
    create_sample_attribute_type
    data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
                                    policy: FactoryBot.create(:private_policy), contributor: person
    sample_type = SampleType.new title: 'from template', projects: person.projects, contributor: person
    sample_type.content_blob = FactoryBot.create(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }
    samples = data_file.extract_samples(sample_type, true)
    sample = samples.first

    assert_equal sample.projects, data_file.projects
    assert_equal sample.project_ids, data_file.project_ids

    # Change the projects
    new_projects = [FactoryBot.create(:project), FactoryBot.create(:project)]
    new_projects.each { |p| person.add_to_project_and_institution(p, person.institutions.first) }
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
    data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
                                    policy: FactoryBot.create(:private_policy)
    person = FactoryBot.create(:person)
    sample_type = SampleType.new title: 'from template', projects: person.projects, contributor: person
    sample_type.content_blob = FactoryBot.create(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }
    samples = data_file.extract_samples(sample_type, true)
    sample = samples.first
    creator = FactoryBot.create(:person)

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
    person = FactoryBot.create(:person)
    project_ids = [person.projects.first.id]

    disable_authorization_checks do
      source_type = FactoryBot.create(:source_sample_type, project_ids: project_ids)
      lib1 = source_type.samples.create(data: { title: 'Lib-1', info: 'bla' }, sample_type: source_type, project_ids: project_ids)
      lib2 = source_type.samples.create(data: { title: 'Lib-2', info: 'bla' }, sample_type: source_type, project_ids: project_ids)
      lib3 = source_type.samples.create(data: { title: 'Lib-3', info: 'bla' }, sample_type: source_type, project_ids: project_ids)
      lib4 = source_type.samples.create(data: { title: 'Lib-4', info: 'bla' }, sample_type: source_type, project_ids: project_ids)

      assert_equal 4, source_type.samples.count

      type = SampleType.new(title: 'Sample type linked to other', project_ids: project_ids, contributor: person)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'title', template_column_index: 1,
                                                                 sample_attribute_type: FactoryBot.create(:string_sample_attribute_type),
                                                                 required: true, is_title: true, sample_type: type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'library id', template_column_index: 2,
                                                                 sample_attribute_type: FactoryBot.create(:sample_sample_attribute_type),
                                                                 required: false, sample_type: type, linked_sample_type: source_type)
      type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'info', template_column_index: 3,
                                                                 sample_attribute_type: FactoryBot.create(:string_sample_attribute_type),
                                                                 required: false, sample_type: type)
      type.save!

      data_file = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:linked_samples_incomplete_content_blob), project_ids: project_ids, contributor: person)

      assert_difference('Sample.count', 4) do
        data_file.extract_samples(type, true, false)
      end

      assert_equal [lib1, lib2], data_file.extracted_samples.map(&:related_samples).flatten.sort

      data_file.content_blob = FactoryBot.create(:linked_samples_complete_content_blob)
      data_file.save!

      assert_difference('Sample.count', 1) do # Spreadsheet contains 4 updated samples and 1 new one
        data_file.extract_samples(type, true, true)
      end

      assert_equal [lib1, lib2, lib3, lib4], data_file.reload.extracted_samples.map(&:related_samples).flatten.uniq.sort
    end
  end

  test 'strains linked through join table' do
    sample_type = FactoryBot.create(:strain_sample_type)
    strain = FactoryBot.create(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)

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
    sample_type = FactoryBot.create(:optional_strain_sample_type)
    strain = FactoryBot.create(:strain)

    sample = Sample.new(sample_type: sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:name, 'Strain sample')
    sample.set_attribute_value(:seekstrain, strain.id)
    disable_authorization_checks { sample.save }

    assert_difference('SampleResourceLink.count', -1) do
      sample.set_attribute_value(:seekstrain, '')
      disable_authorization_checks { sample.save }
    end

    assert_not_includes sample.referenced_strains, strain
    assert_not_includes sample.referenced_resources, strain
    assert_not_includes sample.strains, strain
    assert_not_includes strain.samples, sample
  end

  test 'samples linked through join table' do
    project = FactoryBot.create(:project)
    sample_type = FactoryBot.create(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = FactoryBot.create(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id])
    sample.set_attribute_value(:title, 'Linking sample')
    sample.set_attribute_value(:patient, linked_sample.id)

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
    project = FactoryBot.create(:project)
    sample_type = FactoryBot.create(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = FactoryBot.create(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id],
                        data: { title: 'Linking sample',
                                patient: linked_sample.id })

    disable_authorization_checks { sample.save! }

    assert_includes sample.referenced_samples, linked_sample
    assert_includes sample.referenced_resources, linked_sample
    assert_includes sample.linked_samples, linked_sample
    assert_includes linked_sample.linking_samples, sample

    assert_difference('SampleResourceLink.count', -1) do
      sample.set_attribute_value(:patient, '')
      disable_authorization_checks { sample.save! }
    end

    assert_not_includes sample.referenced_samples, linked_sample
    assert_not_includes sample.referenced_resources, linked_sample
    assert_not_includes sample.linked_samples, linked_sample
    assert_not_includes linked_sample.linking_samples, sample
  end

  test 'samples unlinked when source destroyed' do
    project = FactoryBot.create(:project)
    sample_type = FactoryBot.create(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = FactoryBot.create(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id],
                        data: { title: 'Linking sample',
                                patient: linked_sample.id })

    disable_authorization_checks { sample.save! }

    assert_difference('SampleResourceLink.count', -1) do
      disable_authorization_checks { sample.destroy! }
    end
  end

  test 'samples unlinked when destination destroyed' do
    project = FactoryBot.create(:project)
    sample_type = FactoryBot.create(:linked_optional_sample_type, project_ids: [project.id])
    linked_sample = FactoryBot.create(:patient_sample, sample_type: sample_type.sample_attributes.last.linked_sample_type)

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id],
                        data: { title: 'Linking sample',
                                patient: linked_sample.id })

    disable_authorization_checks { sample.save! }

    assert_difference('SampleResourceLink.count', -1) do
      disable_authorization_checks { linked_sample.destroy! }
    end
  end

  test 'related organisms through ncbi id' do
    org1 = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://purl.obolibrary.org/obo/NCBITaxon_12345'))
    org2 = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/12345'))
    org3 = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: 'http://identifiers.org/taxonomy/12346'))
    org4 = FactoryBot.create(:organism, bioportal_concept: FactoryBot.create(:bioportal_concept, concept_uri: nil))
    org5 = FactoryBot.create(:organism, bioportal_concept: nil)

    sample_type = FactoryBot.create(:simple_sample_type)
    sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'ncbi',
                                                                      sample_attribute_type: FactoryBot.create(:ncbi_id_sample_attribute_type),
                                                                      required: false,
                                                                      sample_type: sample_type)
    sample_type.save!

    contributor = FactoryBot.create(:person)
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor: contributor)
      sample.set_attribute_value(:the_title, 'testing related orgs')
      sample.set_attribute_value(:ncbi, '12345')
      sample.save!

      assert_equal [org1, org2].sort, sample.related_organisms.sort
    end

    # with nil ncbi id
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor: contributor)
      sample.set_attribute_value(:the_title, 'testing related orgs')
      sample.set_attribute_value(:ncbi, nil)
      sample.save!

      assert_empty sample.related_organisms
    end

    # with blank ncbi id
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor: contributor)
      sample.set_attribute_value(:the_title, 'testing related orgs')
      sample.set_attribute_value(:ncbi, '')
      sample.save!

      assert_empty sample.related_organisms
    end

    # with partially matching ncbi id
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor: contributor)
      sample.set_attribute_value(:the_title, 'testing related orgs')
      sample.set_attribute_value(:ncbi, '345')
      sample.save!

      assert_empty sample.related_organisms
    end

    # shouldn't be duplicates
    sample_type = FactoryBot.create(:simple_sample_type)
    sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'ncbi',
                                                                      sample_attribute_type: FactoryBot.create(:ncbi_id_sample_attribute_type),
                                                                      required: true,
                                                                      sample_type: sample_type)
    sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'ncbi2',
                                                                      sample_attribute_type: FactoryBot.create(:ncbi_id_sample_attribute_type),
                                                                      required: true,
                                                                      sample_type: sample_type)
    sample_type.save!
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor: contributor)
      sample.set_attribute_value(:the_title, 'testing related orgs')
      sample.set_attribute_value(:ncbi, '12345')
      sample.set_attribute_value(:ncbi2, '12345')
      sample.save!

      assert_equal [org1, org2].sort, sample.related_organisms.sort
    end

    # handles capitalized attribute name
    sample_type = FactoryBot.create(:simple_sample_type)
    sample_type.sample_attributes << FactoryBot.build(:sample_attribute, title: 'NcBi',
                                                                      sample_attribute_type: FactoryBot.create(:ncbi_id_sample_attribute_type),
                                                                      required: true,
                                                                      sample_type: sample_type)
    sample_type.save!
    User.with_current_user(contributor.user) do
      sample = Sample.new(sample_type: sample_type, project_ids: [contributor.projects.first.id], contributor: contributor)
      sample.set_attribute_value(:the_title, 'testing related orgs')
      sample.set_attribute_value(:NcBi, '12345')
      sample.save!

      assert_equal [org1, org2].sort, sample.related_organisms.sort
    end
  end

  test 'accessor with symbols' do
    project = FactoryBot.create(:project)
    sample_type = FactoryBot.create(:sample_type_with_symbols, project_ids: [project.id])
    sample = Sample.new(sample_type: sample_type, project_ids: [project.id])
    sample.set_attribute_value('title&', 'A')
    sample.set_attribute_value('name ++##!', 'B')
    sample.set_attribute_value('size range (bp)', 'C')
    assert_equal 'A', sample.get_attribute_value('title&')
    assert_equal 'B', sample.get_attribute_value('name ++##!')
    assert_equal 'C', sample.get_attribute_value('size range (bp)')
  end

  test 'mass assignment with symbols' do
    project = FactoryBot.create(:project)
    sample_type = FactoryBot.create(:sample_type_with_symbols, project_ids: [project.id])
    sample = Sample.new(sample_type: sample_type, project_ids: [project.id])
    sample.update(data: { 'title&': 'A', 'name ++##!': 'B', 'size range (bp)': 'C' })
    assert_equal 'A', sample.get_attribute_value('title&')
    assert_equal 'B', sample.get_attribute_value('name ++##!')
    assert_equal 'C', sample.get_attribute_value('size range (bp)')
  end

  test 'data file sample' do
    project = FactoryBot.create(:project)
    sample_type = FactoryBot.create(:data_file_sample_type, project_ids:[project.id])
    sample = Sample.new(sample_type: sample_type, project_ids: [project.id])
    df = FactoryBot.create(:data_file)

    sample.update(data:{'data file':df.id})
    assert sample.valid?
    sample.save!

    sample.reload
    expected = {id:df.id,type:'DataFile',title:df.title}.with_indifferent_access
    assert_equal expected, sample.get_attribute_value('data file')

    sample = Sample.new(sample_type: sample_type, project_ids: [project.id])
    sample.set_attribute_value('data file',df.id)
    assert sample.valid?
    sample.save!

    sample.reload
    expected = {'id':df.id,type:'DataFile',title:df.title}.with_indifferent_access
    assert_equal expected, sample.get_attribute_value('data file')

  end

  test 'multi linked sample validation' do
    patient = FactoryBot.create(:patient_sample)
    patient2 = FactoryBot.create(:patient_sample, sample_type:patient.sample_type )
    multi_linked_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    multi_linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    multi_linked_sample_type.save!

    sample = Sample.new(sample_type: multi_linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    sample.set_attribute_value(:title, 'blah')
    sample.set_attribute_value(:patient, [''])
    refute sample.valid?
    sample.set_attribute_value(:patient, [])
    refute sample.valid?
    sample.set_attribute_value(:patient, [patient.id])
    assert sample.valid?
    sample.set_attribute_value(:patient, [patient.id, patient2.id])
    assert sample.valid?
    sample.save!
    assert sample.get_attribute_value("patient").kind_of?(Array)
    assert_equal  patient.id, sample.get_attribute_value("patient")[0]["id"]
    assert_equal  patient2.id, sample.get_attribute_value("patient")[1]["id"]
  end

  test 'refuse multi linked sample as title' do
    patient = FactoryBot.create(:patient_sample)
    multi_linked_sample_type = FactoryBot.create(:multi_linked_sample_type, project_ids: [FactoryBot.create(:project).id])
    multi_linked_sample_type.sample_attributes.last.linked_sample_type = patient.sample_type
    multi_linked_sample_type.sample_attributes.first.is_title = false
    multi_linked_sample_type.sample_attributes.last.is_title = true
    refute multi_linked_sample_type.valid?
  end

  test 'json api doesnt format attribute_map keys' do
    sample = User.with_current_user(FactoryBot.create(:user)) do
      FactoryBot.create(:max_sample)
    end
    json = JSON.parse(ActiveModelSerializers::SerializableResource.new(sample).adapter.to_json)
    attribute_map = json['data']['attributes']['attribute_map']
    assert attribute_map.key?('CAPITAL key')
    assert_equal 'key must remain capitalised', attribute_map['CAPITAL key']
  end

  test 'list_item_title_cache_key_prefix' do
    sample = FactoryBot.create(:sample)
    sample_type = sample.sample_type

    assert_equal "#{sample_type.list_item_title_cache_key_prefix}/#{sample.cache_key}", sample.list_item_title_cache_key_prefix

    #check it changes
    old = sample.list_item_title_cache_key_prefix
    disable_authorization_checks { sample_type.update(title:'changed', updated_at: 1.minute.from_now) }
    refute_equal old, sample.list_item_title_cache_key_prefix
    old = sample.list_item_title_cache_key_prefix
    disable_authorization_checks { sample.update(title:'changed', updated_at: 1.minute.from_now) }
    refute_equal old, sample.list_item_title_cache_key_prefix

  end

end
