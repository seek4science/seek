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
    sample = Sample.new title: 'testing'
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
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    refute sample.valid?

    sample.sample_type = Factory(:simple_sample_type)
    sample.set_attribute(:the_title, 'bob')
    assert sample.valid?
  end

  test 'store and retrieve' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.set_attribute(:full_name, 'Jimi Hendrix')
    sample.set_attribute(:age, 27)
    sample.set_attribute(:weight, 88.9)
    sample.set_attribute(:postcode, 'M13 9PL')
    sample.save!

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
    sample.save!

    sample = Sample.find(sample.id)

    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)
  end

  test 'various methods of sample data assignment' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    # Mass assignment
    sample.data = { full_name: 'Jimi Hendrix', age: 27, weight: 88.9, postcode: 'M13 9PL' }
    sample.save!

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
    sample.save!

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M13 9PL', sample.get_attribute(:postcode)

    # Method name
    sample.send((SampleAttribute::METHOD_PREFIX + 'postcode=').to_sym, 'M14 8PL')
    sample.save!

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 88.9, sample.get_attribute(:weight)
    assert_equal 'M14 8PL', sample.get_attribute(:postcode)

    # Hash
    sample.data[:weight] = 90.1
    sample.save!

    sample = Sample.find(sample.id)
    assert_equal 'Jimi Hendrix', sample.get_attribute(:full_name)
    assert_equal 28, sample.get_attribute(:age)
    assert_equal 90.1, sample.get_attribute(:weight)
    assert_equal 'M14 8PL', sample.get_attribute(:postcode)
  end

  test 'various methods of sample data assignment perform conversions' do
    sample_type = Factory(:simple_sample_type)
    sample_type.sample_attributes << Factory(:sample_attribute, title: "bool",
                                             sample_attribute_type: Factory(:boolean_sample_attribute_type),
                                             required: false, is_title: false, sample_type: sample_type)
    sample = Sample.new(title: 'testing', sample_type: sample_type)

    # Update attributes
    sample.update_attributes(data: { the_title:'fish', bool: '0' })
    assert sample.valid?
    sample.save!
    assert_equal false, sample.data[:bool]

    # Mass assignment
    sample.data = { the_title:'fish', bool: '1' }
    assert sample.valid?
    sample.save!
    assert_equal true, sample.data[:bool]

    # Setter
    sample.set_attribute(:bool, '0')
    assert sample.valid?
    sample.save!
    assert_equal false, sample.data[:bool]

    # Method name
    sample.send((SampleAttribute::METHOD_PREFIX + 'bool=').to_sym, '1')
    assert sample.valid?
    sample.save!
    assert_equal true, sample.data[:bool]

    # Hash
    sample.data[:bool] = '0'
    assert sample.valid?
    sample.save!
    assert_equal false, sample.data[:bool]
  end

  test 'handling booleans' do
    sample = Sample.new title: 'testing'
    sample_type = Factory(:simple_sample_type)
    sample_type.sample_attributes << Factory(:sample_attribute,:title=>"bool",:sample_attribute_type=>Factory(:boolean_sample_attribute_type),:required=>false,:is_title=>false, :sample_type => sample_type)
    sample_type.save!
    sample.sample_type = sample_type


    #the simple cases
    sample.update_attributes(data: { the_title:'fish', bool:true })
    assert sample.valid?
    sample.save!
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title:'fish',bool:false })
    assert sample.valid?
    sample.save!
    refute sample.get_attribute(:bool)

    #from a form
    sample.update_attributes(data: { the_title:'fish',bool:'1' })
    puts sample.errors.full_messages
    assert sample.valid?
    sample.save!
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title:'fish',bool:'0' })
    assert sample.valid?
    sample.save!
    refute sample.get_attribute(:bool)

    #as text
    sample.update_attributes(data: { the_title:'fish',bool:'true' })
    assert sample.valid?
    sample.save!
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title:'fish',bool:'false' })
    assert sample.valid?
    sample.save!
    refute sample.get_attribute(:bool)

    #as text2
    sample.update_attributes(data: { the_title:'fish',bool:'TRUE' })
    assert sample.valid?
    sample.save!
    assert sample.get_attribute(:bool)

    sample.update_attributes(data: { the_title:'fish',bool:'FALSE' })
    assert sample.valid?
    sample.save!
    refute sample.get_attribute(:bool)

    #via accessors
    sample.set_attribute(:bool, true)
    assert sample.valid?
    sample.save!
    assert sample.get_attribute(:bool)
    sample.set_attribute(:bool, false)
    assert sample.valid?
    sample.save!
    refute sample.get_attribute(:bool)

    sample.set_attribute(:bool, '1')
    assert sample.valid?
    sample.save!
    assert sample.get_attribute(:bool)
    sample.set_attribute(:bool, '0')
    assert sample.valid?
    sample.save!
    refute sample.get_attribute(:bool)

    sample.set_attribute(:bool, 'true')
    assert sample.valid?
    sample.save!
    assert sample.get_attribute(:bool)
    sample.set_attribute(:bool, 'false')
    assert sample.valid?
    sample.save!
    refute sample.get_attribute(:bool)

    #not valid
    sample.update_attributes(data: { the_title:'fish',bool:'fish' })
    refute sample.valid?
    sample.set_attribute(:bool, 'true')
    assert sample.valid?
    sample.set_attribute(:bool, 'fish')
    refute sample.valid?
  end

  test 'json_metadata' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.set_attribute(:full_name, 'Jimi Hendrix')
    sample.set_attribute(:age, 27)
    sample.set_attribute(:weight, 88.9)
    sample.set_attribute(:postcode, 'M13 9PL')
    sample.set_attribute(:address, 'Somewhere on earth')
    assert_equal %({"full_name":null,"age":null,"weight":null,"address":null,"postcode":null}), sample.json_metadata
    sample.save!
    refute_nil sample.json_metadata
    assert_equal %({"full_name":"Jimi Hendrix","age":27,"weight":88.9,"address":"Somewhere on earth","postcode":"M13 9PL"}), sample.json_metadata
  end

  test 'json metadata with awkward attributes' do
    sample_type = SampleType.new :title=>"with awkward attributes"
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"title",is_title:true, :sample_type => sample_type)
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"updated_at",is_title:false, :sample_type => sample_type)
    assert sample_type.valid?
    sample = Sample.new title: 'testing'
    sample.sample_type = sample_type

    sample.set_attribute(:title, "the title")
    sample.set_attribute(:updated_at, "the updated at")
    assert_equal %({"title":null,"updated_at":null}), sample.json_metadata
    sample.save!
    assert_equal %({"title":"the title","updated_at":"the updated at"}), sample.json_metadata

    sample = Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.title
    assert_equal "the updated at",sample.get_attribute(:updated_at)
  end

  #trying to track down an sqlite3 specific problem
  test 'sqlite3 setting of accessor problem' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.set_attribute(:full_name, 'Jimi Hendrix')
    sample.set_attribute(:age, 22)
    sample.save!
    id = sample.id
    assert_equal 5,sample.sample_type.sample_attributes.count
    assert_equal ["full_name", "age", "weight", "address", "postcode"],sample.sample_type.sample_attributes.collect(&:hash_key)
    assert_respond_to sample, SampleAttribute::METHOD_PREFIX + 'full_name'

    sample2 = Sample.find(id)
    assert_equal id,sample2.id
    assert_equal 5,sample2.sample_type.sample_attributes.count
    assert_equal ["full_name", "age", "weight", "address", "postcode"],sample2.sample_type.sample_attributes.collect(&:hash_key)
    assert_respond_to sample2, SampleAttribute::METHOD_PREFIX + 'full_name'
  end

  test 'projects' do
    sample = Factory(:sample)
    assert_empty sample.projects
    project = Factory(:project)
    sample.update_attributes(project_ids:[project.id])
    sample.save!
    sample.reload
    assert_equal [project],sample.projects
  end

  test 'authorization' do

    person = Factory(:person)
    other_person = Factory(:person)
    public_sample = Factory(:sample,:policy=>Factory(:public_policy),:contributor=>person)
    private_sample = Factory(:sample,:policy=>Factory(:private_policy),:contributor=>person)

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

    assert_equal [public_sample,private_sample].sort,Sample.all_authorized_for(:view,person.user).sort
    assert_equal [public_sample],Sample.all_authorized_for(:view,other_person.user)
    assert_equal [public_sample],Sample.all_authorized_for(:view,nil)
    assert_equal [public_sample,private_sample].sort,Sample.all_authorized_for(:download,person.user).sort
    assert_equal [public_sample],Sample.all_authorized_for(:download,other_person.user)
    assert_equal [public_sample],Sample.all_authorized_for(:download,nil)

  end

  test 'assays studies and investigation' do
    assay = Factory(:assay)
    study = assay.study
    investigation = study.investigation
    sample = Factory(:sample)

    assert_empty sample.assays
    assert_empty sample.studies
    assert_empty sample.investigations

    assay.associate(sample)
    assay.save!
    sample.reload

    assert_equal [assay],sample.assays
    assert_equal [study],sample.studies
    assert_equal [investigation],sample.investigations

  end

  test 'cleans up assay asset on destroy' do
    assay = Factory(:assay)
    sample = Factory(:sample,:policy=>Factory(:public_policy))
    assert_difference('AssayAsset.count',1) do
      assay.associate(sample)
    end
    assay.save!
    sample.reload
    id = sample.id

    refute_empty AssayAsset.where(asset_type:'Sample',asset_id:id)

    assert_difference('AssayAsset.count',-1) do
      assert sample.destroy
    end
    assert_empty AssayAsset.where(asset_type:'Sample',asset_id:id)


  end

  test 'title delegated to title attribute on save' do
    sample = Factory.build(:sample,:title=>'frog',:policy=>Factory(:public_policy))
    sample.set_attribute(:the_title, 'this should be the title')
    sample.save!
    sample.reload
    assert_equal 'this should be the title',sample.title
  end

  test 'sample with clashing attribute names' do
    sample_type = SampleType.new :title=>"with awkward attributes"
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"freeze",is_title:true, :sample_type => sample_type)
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"updated_at",is_title:false, :sample_type => sample_type)
    assert sample_type.valid?
    sample_type.save!
    sample = Sample.new title: 'testing'
    sample.sample_type = sample_type

    sample.set_attribute(:freeze, "the title")
    refute sample.valid?
    sample.set_attribute(:updated_at, "the updated_at")
    sample.save!
    assert_equal "the title",sample.title

    sample=Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.get_attribute(:freeze)
    assert_equal "the updated_at",sample.get_attribute(:updated_at)
  end

  test 'sample with clashing attribute names with private methods' do
    sample_type = SampleType.new :title=>"with awkward attributes"
    sample_type.sample_attributes << Factory.build(:any_string_sample_attribute, :title=>"format",is_title:true, :sample_type => sample_type)
    assert sample_type.valid?
    sample_type.save!
    sample = Sample.new title: 'testing'
    sample.sample_type = sample_type

    sample.set_attribute(:format, "the title")
    assert sample.valid?
    sample.save!
    assert_equal "the title",sample.title

    sample=Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.get_attribute(:format)
  end

  test 'sample with clashing attribute names with dynamic rails methods' do
    sample_type = SampleType.new :title=>"with awkward attributes"
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"title_was",is_title:true, :sample_type => sample_type)
    assert sample_type.valid?
    sample_type.save!
    sample = Sample.new title: 'testing'
    sample.sample_type = sample_type

    sample.set_attribute(:title_was, "the title")
    assert sample.valid?
    sample.save!
    assert_equal "the title",sample.title

    sample=Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.get_attribute(:title_was)
  end

  test 'strain type stores valid strain info' do
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)

    sample = Sample.new(sample_type: sample_type)
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    assert sample.valid?
    sample.save!
    sample = Sample.find(sample.id)

    assert_equal strain.id, sample.get_attribute(:seekstrain)['id']
    assert_equal strain.title, sample.get_attribute(:seekstrain)['title']
  end

  test 'strain type still stores missing strain info' do
    sample_type = Factory(:strain_sample_type)
    strain = Factory(:strain)
    invalid_strain_id = Strain.last.id + 1 # non-existant strain ID

    sample = Sample.new(sample_type: sample_type)
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, invalid_strain_id)
    assert sample.valid?
    sample.save!
    sample = Sample.find(sample.id)

    assert_equal invalid_strain_id, sample.get_attribute(:seekstrain)['id']
    assert_nil sample.get_attribute(:seekstrain)['title'] # can't look up the title because that strain doesn't exist!
  end

  test 'strain attributes can appear as related items' do
    sample_type = Factory(:strain_sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: "seekstrain2",
                                                   sample_attribute_type: Factory(:strain_sample_attribute_type),
                                                   required: true, sample_type: sample_type)
    sample_type.sample_attributes << Factory.build(:sample_attribute, title: "seekstrain3",
                                                   sample_attribute_type: Factory(:strain_sample_attribute_type),
                                                   required: true, sample_type: sample_type)
    strain = Factory(:strain)
    strain2 = Factory(:strain)

    sample = Sample.new(sample_type: sample_type)
    sample.set_attribute(:name, 'Strain sample')
    sample.set_attribute(:seekstrain, strain.id)
    sample.set_attribute(:seekstrain2, strain2.id)
    sample.set_attribute(:seekstrain3, Strain.last.id + 1000) # Non-existant strain id
    assert sample.valid?
    sample.save!
    sample = Sample.find(sample.id)

    assert_equal 2, sample.strains.size
    assert_equal [strain.title, strain2.title].sort, [sample.get_attribute(:seekstrain)['title'],sample.get_attribute(:seekstrain2)['title']].sort
  end

  test 'sample responds to correct methods' do
    sample_type = SampleType.new(title: 'Custom')
    attribute1 = Factory(:any_string_sample_attribute, title: 'banana_type',
                                             is_title:true, sample_type: sample_type)
    attribute2 = Factory(:any_string_sample_attribute, title: 'license',
                         sample_type: sample_type)
    sample_type.sample_attributes << attribute1
    sample_type.sample_attributes << attribute2
    assert sample_type.valid?
    sample_type.save!
    sample = Sample.new(title: 'testing')
    sample.sample_type = sample_type
    sample.set_attribute(:banana_type, 'yellow')
    sample.set_attribute(:license, 'GPL')
    assert sample.valid?
    sample.save!

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

end
