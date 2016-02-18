require 'test_helper'

class SampleTest < ActiveSupport::TestCase
  test 'validation' do
    sample = Factory :sample, title: 'fish', sample_type: Factory(:sample_type)
    assert sample.valid?
    sample.title = nil
    refute sample.valid?
    sample.title = ''
    refute sample.valid?

    sample.title = 'fish'
    sample.sample_type = nil
    refute sample.valid?
  end

  test 'test uuid generated' do
    sample = Sample.new title: 'fish'
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
    sample = Factory(:sample, sample_type: Factory(:sample_type))
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

    sample.sample_type = Factory(:sample_type)

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
    sample.update_attributes({full_name:'Fred Bloggs',age:25,postcode:'M12 9QL',weight:0.22,address:'somewhere'})
    assert_equal 'Fred Bloggs',sample.full_name
    assert_equal 25,sample.age
    assert_equal 0.22,sample.weight
    assert_equal 'M12 9QL',sample.postcode
    assert_equal 'somewhere',sample.address
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

    sample.sample_type = Factory(:sample_type)
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
    sample.address = "Somewhere on earth"
    assert_nil sample.json_metadata
    sample.save!
    refute_nil sample.json_metadata
    assert_equal %!{"full_name":"Jimi Hendrix","age":27,"weight":88.9,"address":"Somewhere on earth","postcode":"M13 9PL"}!, sample.json_metadata
  end
end
