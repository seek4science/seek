require 'test_helper'

class SampleTest < ActiveSupport::TestCase

  test 'validation' do
    sample = Factory :sample, title: 'fish', sample_type: Factory(:simple_sample_type),the_title:'fish'
    assert sample.valid?
    sample.the_title = nil
    refute sample.valid?
    sample.title = ''
    refute sample.valid?

    sample.the_title = 'fish'
    sample.sample_type = nil
    refute sample.valid?
  end

  test 'test uuid generated' do
    sample = Factory.build(:sample,the_title:'fish')
    assert_nil sample.attributes['uuid']
    sample.save
    assert_not_nil sample.attributes['uuid']
  end

  test 'sets up accessor methods' do
    sample = Factory.build(:sample, sample_type: Factory(:patient_sample_type))
    sample.save(validate: false)
    sample = Sample.find(sample.id)
    refute_nil sample.sample_type

    assert_respond_to sample, :full_name
    assert_respond_to sample, :full_name=
    assert_respond_to sample, :age
    assert_respond_to sample, :age=
    assert_respond_to sample, :postcode
    assert_respond_to sample, :postcode=
    assert_respond_to sample, :weight
    assert_respond_to sample, :weight=

    # doesn't affect all sample classes
    sample = Factory(:sample, sample_type: Factory(:simple_sample_type))
    refute_respond_to sample, :full_name
    refute_respond_to sample, :full_name=
    refute_respond_to sample, :age
    refute_respond_to sample, :age=
    refute_respond_to sample, :postcode
    refute_respond_to sample, :postcode=
    refute_respond_to sample, :weight
    refute_respond_to sample, :weight=
  end

  test 'sets up accessor methods when assigned' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)

    assert_respond_to sample, :full_name
    assert_respond_to sample, :full_name=
    assert_respond_to sample, :age
    assert_respond_to sample, :age=
    assert_respond_to sample, :postcode
    assert_respond_to sample, :postcode=
    assert_respond_to sample, :weight
    assert_respond_to sample, :weight=
  end

  test 'removes accessor methods with new assigned type' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)

    assert_respond_to sample, :full_name
    assert_respond_to sample, :full_name=

    sample.sample_type = Factory(:simple_sample_type)

    refute_respond_to sample, :full_name
    refute_respond_to sample, :full_name=
    refute_respond_to sample, :age
    refute_respond_to sample, :age=
    refute_respond_to sample, :postcode
    refute_respond_to sample, :postcode=
    refute_respond_to sample, :weight
    refute_respond_to sample, :weight=
  end

  test 'mass assigment' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.update_attributes(full_name: 'Fred Bloggs', age: 25, postcode: 'M12 9QL', weight: 0.22, address: 'somewhere')
    assert_equal 'Fred Bloggs', sample.full_name
    assert_equal 25, sample.age
    assert_equal 0.22, sample.weight
    assert_equal 'M12 9QL', sample.postcode
    assert_equal 'somewhere', sample.address
  end

  test 'adds validations' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    refute sample.valid?
    sample.full_name = 'Bob Monkhouse'
    sample.age = 22
    assert sample.valid?

    sample.full_name = 'FRED'
    refute sample.valid?

    sample.full_name = 'Bob Monkhouse'
    sample.postcode = 'fish'
    refute sample.valid?
    assert_equal 1, sample.errors.count
    assert_equal 'Postcode is not a valid Post Code', sample.errors.full_messages.first
    sample.postcode = 'M13 9PL'
    assert sample.valid?
  end

  test 'removes validations with new assigned type' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    refute sample.valid?

    sample.sample_type = Factory(:simple_sample_type)
    sample.the_title='bob'
    assert sample.valid?
  end

  test 'store and retrieve' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.full_name = 'Jimi Hendrix'
    sample.age = 27
    sample.weight = 88.9
    sample.postcode = 'M13 9PL'
    sample.save!

    assert_equal 'Jimi Hendrix', sample.full_name
    assert_equal 27, sample.age
    assert_equal 88.9, sample.weight
    assert_equal 'M13 9PL', sample.postcode

    sample = Sample.find(sample.id)

    assert_equal 'Jimi Hendrix', sample.full_name
    assert_equal 27, sample.age
    assert_equal 88.9, sample.weight
    assert_equal 'M13 9PL', sample.postcode

    sample.age = 28
    sample.save!

    sample = Sample.find(sample.id)

    assert_equal 'Jimi Hendrix', sample.full_name
    assert_equal 28, sample.age
    assert_equal 88.9, sample.weight
    assert_equal 'M13 9PL', sample.postcode
  end

  test 'json_metadata' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.full_name = 'Jimi Hendrix'
    sample.age = 27
    sample.weight = 88.9
    sample.postcode = 'M13 9PL'
    sample.address = 'Somewhere on earth'
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
    sample.sample_type=sample_type

    sample.title_ = "the title"
    sample.updated_at_ = "the updated at"
    assert_equal %({"title_":null,"updated_at_":null}), sample.json_metadata
    sample.save!
    assert_equal %({"title_":"the title","updated_at_":"the updated at"}), sample.json_metadata

    sample = Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.title_
    assert_equal "the updated at",sample.updated_at_
  end

  #trying to track down an sqlite3 specific problem
  test 'sqlite3 setting of accessor problem' do
    sample = Sample.new title: 'testing'
    sample.sample_type = Factory(:patient_sample_type)
    sample.full_name = 'Jimi Hendrix'
    sample.age = 22
    sample.save!
    id = sample.id
    assert_equal 5,sample.sample_type.sample_attributes.count
    assert_equal ["full_name", "age", "weight", "address", "postcode"],sample.sample_type.sample_attributes.collect(&:accessor_name)
    assert_respond_to sample,:full_name

    sample2 = Sample.find(id)
    assert_equal id,sample2.id
    assert_equal 5,sample2.sample_type.sample_attributes.count
    assert_equal ["full_name", "age", "weight", "address", "postcode"],sample2.sample_type.sample_attributes.collect(&:accessor_name)
    assert_respond_to sample2,:full_name
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
    sample.the_title='this should be the title'
    sample.save!
    sample.reload
    assert_equal 'this should be the title',sample.title
  end

  test 'sample with clashing attribute names' do
    sample_type = SampleType.new :title=>"with awkward attributes"
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"freeze",is_title:true, :sample_type => sample_type)
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"updated_at",is_title:false, :sample_type => sample_type)
    assert sample_type.valid?
    sample = Sample.new title: 'testing'
    sample.sample_type=sample_type

    sample.freeze_ = "the title"
    refute sample.valid?
    sample.updated_at_ = "the updated_at"
    sample.save!
    assert_equal "the title",sample.title

    sample=Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.freeze_
    assert_equal "the updated_at",sample.updated_at_
  end

  test 'sample with clashing attribute names with private methods' do
    sample_type = SampleType.new :title=>"with awkward attributes"
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"format",is_title:true, :sample_type => sample_type)
    assert sample_type.valid?
    sample = Sample.new title: 'testing'
    sample.sample_type=sample_type

    sample.format_ = "the title"
    assert sample.valid?
    sample.save!
    assert_equal "the title",sample.title

    sample=Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.format_
  end

  test 'sample with clashing attribute names with dynamic rails methods' do
    sample_type = SampleType.new :title=>"with awkward attributes"
    sample_type.sample_attributes << Factory(:any_string_sample_attribute, :title=>"title_was",is_title:true, :sample_type => sample_type)
    assert sample_type.valid?
    sample = Sample.new title: 'testing'
    sample.sample_type=sample_type

    sample.title_was_ = "the title"
    assert sample.valid?
    sample.save!
    assert_equal "the title",sample.title

    sample=Sample.find(sample.id)
    assert_equal "the title",sample.title
    assert_equal "the title",sample.title_was_
  end

end
