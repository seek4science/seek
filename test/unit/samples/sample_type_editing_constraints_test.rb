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

    type = FactoryBot.create(:linked_optional_sample_type)
    c = Seek::Samples::SampleTypeEditingConstraints.new(type)
    assert c.allow_type_change?(:patient)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'patient' }
    refute_nil attr
    assert c.allow_type_change?(attr)
    assert c.allow_type_change?(nil)

    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      type.samples.create!(data: { title: 'Lib-3', patient: nil }, sample_type: type, project_ids: person.project_ids)

      assert Seek::Samples::SampleTypeEditingConstraints.new(type).allow_type_change?(:patient),
             'Should still allow type change because patient was blank'

      patient_sample = FactoryBot.create(:patient_sample, sample_type: attr.linked_sample_type, contributor: person)
      type.samples.create!(data: { title: 'Lib-4', patient: patient_sample.id }, sample_type: type,
                           project_ids: person.project_ids)

      refute Seek::Samples::SampleTypeEditingConstraints.new(type).allow_type_change?(:patient),
             'Should not allow type change because a sample exists with a patient'
    end
  end

  test 'allow_required?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_required?(:address)
    refute c.allow_required?(:postcode)
    assert c.allow_required?(:age)
    assert c.allow_required?('full name')

    # accepts attribute
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'address' }
    refute_nil attr
    refute c.allow_required?(attr)
    attr = c.sample_type.sample_attributes.detect { |t| t.accessor_name == 'age' }
    refute_nil attr
    assert c.allow_required?(attr)

    # should refute if inherited from a template
    template = FactoryBot.create(:isa_source_template)
    sample_type_from_template = create_sample_type_from_template(template, c.sample_type.projects.first, c.sample_type.contributor)
    sample_type_from_template.sample_attributes << FactoryBot.create(:sample_attribute, title: 'Extra Source Characteristic', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: false, isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, sample_type: sample_type_from_template)

    c_inherited = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_from_template)
    sample_type_from_template.sample_attributes.each do |attr|
      if attr.title == 'Extra Source Characteristic'
        refute c_inherited.send(:inherited?, attr)
        assert c_inherited.allow_required?(attr)
      else
        assert c_inherited.send(:inherited?, attr)
        refute c_inherited.allow_required?(attr)
      end
    end
  end

  test 'allow_attribute_removal?' do
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_with_samples)
    refute c.allow_attribute_removal?(:address)
    assert c.allow_attribute_removal?(:postcode)
    refute c.allow_attribute_removal?(:age)
    refute c.allow_attribute_removal?('full name')
    # accepts attribute
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

  test 'allow editing isa tag' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    template = FactoryBot.create(:isa_source_template)
    sample_type_from_template = create_sample_type_from_template(template, project, person)
    sample_type = FactoryBot.create(:isa_source_sample_type, projects: [project], contributor: person)

    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type)
    c_inherited = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_from_template)
    sample_type.sample_attributes.map { |attribute| refute c.send(:inherited?, attribute) }
    sample_type_from_template.sample_attributes.map { |attribute| assert c_inherited.send(:inherited?, attribute) }
    sample_type_from_template.sample_attributes.map { |attribute| refute c_inherited.allow_isa_tag_change?(attribute) }
    sample_type.sample_attributes.map { |attribute| assert c.allow_isa_tag_change?(attribute) }

    # Adding an extra attribute to the sample_type
    sample_type_from_template.sample_attributes << FactoryBot.create(:sample_attribute, title: 'Extra Source Characteristic', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: false, isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, sample_type: sample_type_from_template)
    sample_type_from_template.reload
    c_inherited = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_from_template)
    extra_source_characteristic = sample_type_from_template.sample_attributes.detect { |sa| sa.title == 'Extra Source Characteristic' }
    refute extra_source_characteristic.nil?
    ## Extra source characteristic should be all blank, since there are no samples
    assert c_inherited.send(:all_blank?, extra_source_characteristic.accessor_name)
    ## Extra source characteristic is not inherrited from a template
    refute c_inherited.send(:inherited?, extra_source_characteristic)
    ## Extra source characteristic should be editable
    assert c_inherited.allow_isa_tag_change?(extra_source_characteristic)

    # Add sample to the sample type but leave the extra characteristic empty
    isa_source_no_extra_char = FactoryBot.create(:isa_source, sample_type: sample_type_from_template, contributor: person)
    sample_type_from_template.samples << isa_source_no_extra_char
    sample_type_from_template.save
    ## Extra source characteristic should be all blank
    assert c_inherited.send(:all_blank?, extra_source_characteristic.accessor_name)
    ## The first attribute has a sample which is filled in => Not allowed to change ISA tag
    refute c_inherited.allow_isa_tag_change?(sample_type_from_template.sample_attributes.first)
    ## Extra source characteristic is completely empty => Allowed to change ISA tag
    assert c_inherited.allow_isa_tag_change?(extra_source_characteristic)

    # Add sample to the sample type with an extra characteristic value
    isa_source_with_extra_char = FactoryBot.create(:isa_source, sample_type: sample_type_from_template, contributor: person)
    isa_source_with_extra_char.set_attribute_value('Extra Source Characteristic', 'Blue')
    isa_source_with_extra_char.save
    sample_type_from_template.samples << isa_source_with_extra_char
    sample_type_from_template.save
    c_inherited = Seek::Samples::SampleTypeEditingConstraints.new(sample_type_from_template)
    ## Extra source characteristic isn't all blank anymore
    refute c_inherited.send(:all_blank?, extra_source_characteristic.accessor_name)
    ## Extra source characteristic is not empty => Not allowed to change ISA tag
    refute c_inherited.allow_isa_tag_change?(extra_source_characteristic)
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

  def create_sample_type_from_template(template, project, person)
    sample_attributes = template.template_attributes.map do |temp_attr|
      SampleAttribute.new(
        title: temp_attr.title,
        description: temp_attr.description,
        sample_attribute_type_id: temp_attr.sample_attribute_type_id,
        required: temp_attr.required,
        unit_id: temp_attr.unit_id,
        is_title: temp_attr.is_title,
        sample_controlled_vocab_id: temp_attr.sample_controlled_vocab_id,
        isa_tag_id: temp_attr.isa_tag_id,
        allow_cv_free_text: temp_attr.allow_cv_free_text,
        template_attribute_id: temp_attr.id
      )
    end

    FactoryBot.create(:sample_type,
                      title: "Sample type created from '#{template.title}'",
                      projects:[project],
                      contributor: person,
                      template_id: template.id,
                      assays: [FactoryBot.build(:assay, contributor: person)],
                      sample_attributes: )
  end
end
