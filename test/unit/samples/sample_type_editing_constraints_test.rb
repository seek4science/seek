require 'test_helper'

class SampleTypeEditingConstraintsTest < ActiveSupport::TestCase
  test 'initialize' do
    sample_type = FactoryBot.create(:simple_sample_type)
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type)
    assert_equal sample_type, c.sample_type
    assert_empty c.samples

    assert_raises(Exception) do
      Seek::Samples::SampleTypeEditingConstraints.new(nil)
    end
  end

  test 'samples?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    assert c.samples?

    c = Seek::Samples::SampleTypeEditingConstraints.new(FactoryBot.create(:simple_sample_type))
    refute c.samples?
  end

  test 'allow title change?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_name_change?(:address)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'address' }
    refute_nil attr
    refute c.allow_name_change?(attr)
    assert c.allow_name_change?(nil)

    # ok if there are no samples
    c = Seek::Samples::SampleTypeEditingConstraints.new(FactoryBot.create(:simple_sample_type))
    assert c.allow_name_change?(:the_title)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'the_title' }
    refute_nil attr
    assert c.allow_name_change?(attr)
    assert c.allow_name_change?(nil)
  end

  test 'allow type change?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_type_change?(:address)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'address' }
    refute_nil attr
    refute c.allow_type_change?(attr)
    assert c.allow_type_change?(nil)

    # ok, if it is a field that is all blank
    assert c.allow_type_change?(:postcode)

    # ok if there are no samples
    c = Seek::Samples::SampleTypeEditingConstraints.new(FactoryBot.create(:simple_sample_type))
    assert c.allow_type_change?(:the_title)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'the_title' }
    refute_nil attr
    assert c.allow_type_change?(attr)
    assert c.allow_type_change?(nil)
  end

  test 'allow_required?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_required?(:address)
    refute c.allow_required?(:postcode)
    assert c.allow_required?(:age)
    assert c.allow_required?('full name')

    # accespts attribute
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'address' }
    refute_nil attr
    refute c.allow_required?(attr)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'age' }
    refute_nil attr
    assert c.allow_required?(attr)
  end

  test 'allow_attribute_removal?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_attribute_removal?(:address)
    assert c.allow_attribute_removal?(:postcode)
    refute c.allow_attribute_removal?(:age)
    refute c.allow_attribute_removal?('full name')
    # accespts attribute
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'address' }
    refute_nil attr
    refute c.allow_attribute_removal?(attr)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'postcode' }
    refute_nil attr
    assert c.allow_attribute_removal?(attr)
  end

  test 'allow required? with nil' do
    # nil indicates a new attribute, allow_required? is determined by whether there are already samples
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_required?(nil)
    c = Seek::Samples::SampleTypeEditingConstraints.new(FactoryBot.create(:simple_sample_type))
    assert c.allow_required?(nil)
  end

  test 'allow_attribute_removal? with nil' do
    # nil indicates a new attribute, removal is always allowed
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    assert c.allow_attribute_removal?(nil)
    c = Seek::Samples::SampleTypeEditingConstraints.new(FactoryBot.create(:simple_sample_type))
    assert c.allow_attribute_removal?(nil)
  end

  test 'blanks?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    assert c.send(:blanks?, :address)
    assert c.send(:blanks?, :postcode)
    refute c.send(:blanks?, :age)
    refute c.send(:blanks?, 'full name')
  end

  test 'all_blank?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.send(:all_blank?, :address)
    assert c.send(:all_blank?, :postcode)
    refute c.send(:all_blank?, :age)
    refute c.send(:all_blank?, 'full name')
  end

  test 'allow_new_attribute' do
    # currently only allowed if there are not samples
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_new_attribute?
    c = Seek::Samples::SampleTypeEditingConstraints.new(FactoryBot.create(:simple_sample_type))
    assert c.allow_new_attribute?
  end

  private

  # sample type with 3 samples
  # - the address attribute includes some blanks
  # - the postcode is always blank
  # - full name and age are required and always have values
  def sample_type_with_samples
    person = FactoryBot.create(:person)

    sample_type = User.with_current_user(person.user) do
      project = person.projects.first
      sample_type = FactoryBot.create(:patient_sample_type, project_ids: [project.id])
      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute_value('full name', 'Fred Blogs')
      sample.set_attribute_value(:age, 22)
      sample.set_attribute_value(:weight, 12.2)
      sample.set_attribute_value(:address, 'Somewhere')
      sample.save!

      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute_value('full name', 'Fred Jones')
      sample.set_attribute_value(:age, 22)
      sample.set_attribute_value(:weight, 12.2)
      sample.save!

      sample = Sample.new sample_type: sample_type, project_ids: [project.id]
      sample.set_attribute_value('full name', 'Fred Smith')
      sample.set_attribute_value(:age, 22)
      sample.set_attribute_value(:weight, 12.2)
      sample.set_attribute_value(:address, 'Somewhere else')
      sample.save!

      sample_type
    end

    sample_type.reload
    assert_equal 3, sample_type.samples.count

    sample_type
  end
end
