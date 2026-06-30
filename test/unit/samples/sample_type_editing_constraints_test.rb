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
    person = c.sample_type.contributor
    project = c.sample_type.projects.first
    template = FactoryBot.create(:isa_source_template)
    inv = FactoryBot.create(:investigation, projects: [project], contributor: person, is_isa_json_compliant: true)
    study = FactoryBot.create(:study, contributor: person, investigation: inv)
    sample_type_from_template = create_sample_type_from_template(template, project, person, [study])
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

  test 'allow editing isa tag' do
    person = FactoryBot.create(:person)
    project = person.projects.first
    template = FactoryBot.create(:isa_source_template, contributor: person, projects: [project])
    inv = FactoryBot.create(:investigation, projects: [project], contributor: person, is_isa_json_compliant: true)
    study = FactoryBot.create(:study, contributor: person, investigation: inv)
    study_sample_type_from_template = create_sample_type_from_template(template, project, person, [study])
    sample_type = FactoryBot.create(:isa_source_sample_type, projects: [project], contributor: person)

    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type)
    c_inherited = Seek::Samples::SampleTypeEditingConstraints.new(study_sample_type_from_template)
    assert sample_type.sample_attributes.none? { |attribute| c.send(:inherited?, attribute) }
    assert study_sample_type_from_template.sample_attributes.all? { |attribute| c_inherited.send(:inherited?, attribute) }
    assert study_sample_type_from_template.sample_attributes.none? { |attribute| c_inherited.allow_isa_tag_change?(attribute) }
    assert sample_type.sample_attributes.all? { |attribute| c.allow_isa_tag_change?(attribute) }

    # Adding an extra attribute to the sample_type
    study_sample_type_from_template.sample_attributes << FactoryBot.create(:sample_attribute, title: 'Extra Source Characteristic', sample_attribute_type: FactoryBot.create(:string_sample_attribute_type), required: false, isa_tag_id: FactoryBot.create(:source_characteristic_isa_tag).id, sample_type: study_sample_type_from_template)
    study_sample_type_from_template.reload
    c_inherited = Seek::Samples::SampleTypeEditingConstraints.new(study_sample_type_from_template)
    extra_source_characteristic = study_sample_type_from_template.sample_attributes.detect { |sa| sa.title == 'Extra Source Characteristic' }
    refute extra_source_characteristic.nil?
    ## Extra source characteristic should be all blank, since there are no samples
    assert c_inherited.send(:all_blank?, extra_source_characteristic.accessor_name)
    ## Extra source characteristic is not inherrited from a template
    refute c_inherited.send(:inherited?, extra_source_characteristic)
    ## Extra source characteristic should be editable
    assert c_inherited.allow_isa_tag_change?(extra_source_characteristic)

    # Add sample to the sample type but leave the extra characteristic empty
    isa_source_no_extra_char = FactoryBot.create(:isa_source, sample_type: study_sample_type_from_template, contributor: person)
    study_sample_type_from_template.samples << isa_source_no_extra_char
    study_sample_type_from_template.save
    ## Extra source characteristic should be all blank
    assert c_inherited.send(:all_blank?, extra_source_characteristic.accessor_name)
    ## The first attribute has a sample which is filled in => Not allowed to change ISA tag
    refute c_inherited.allow_isa_tag_change?(study_sample_type_from_template.sample_attributes.first)
    ## Extra source characteristic is completely empty => Allowed to change ISA tag
    assert c_inherited.allow_isa_tag_change?(extra_source_characteristic)

    # Add sample to the sample type with an extra characteristic value
    isa_source_with_extra_char = FactoryBot.create(:isa_source, sample_type: study_sample_type_from_template, contributor: person)
    isa_source_with_extra_char.set_attribute_value('Extra Source Characteristic', 'Blue')
    isa_source_with_extra_char.save
    study_sample_type_from_template.samples << isa_source_with_extra_char
    study_sample_type_from_template.save
    c_inherited = Seek::Samples::SampleTypeEditingConstraints.new(study_sample_type_from_template)
    ## Extra source characteristic isn't all blank anymore
    refute c_inherited.send(:all_blank?, extra_source_characteristic.accessor_name)
    ## Extra source characteristic is not empty => Not allowed to change ISA tag
    refute c_inherited.allow_isa_tag_change?(extra_source_characteristic)
  end

  test 'allow_change_at_creation?' do
    template = FactoryBot.create(:isa_source_template)

    # nil attr is always allowed (represents a brand-new attribute row)
    c = Seek::Samples::SampleTypeEditingConstraints.new(SampleType.new)
    assert c.allow_change_at_creation?(nil)

    # new record, attribute without template_attribute_id -> allowed
    non_inherited_attr = SampleAttribute.new(title: 'Custom')
    assert c.allow_change_at_creation?(non_inherited_attr)

    # new record, template_id set -> sample type is ISA JSON compliant
    # attribute with template_attribute_id -> NOT allowed (inherited from template)
    new_type_with_template = SampleType.new(template_id: template.id)
    new_type_with_template.create_sample_attributes_from_isa_template(template)
    c_template = Seek::Samples::SampleTypeEditingConstraints.new(new_type_with_template)
    assert new_type_with_template.is_isa_json_compliant?,
           'New sample type with template_id set should be ISA JSON compliant'

    # Inherited attributes should return false
    assert new_type_with_template.sample_attributes.none? { |attribute| c_template.allow_change_at_creation?(attribute) },
           'Inherited attributes should not be changeable at creation time'

    # nil or non-inherited attr is still allowed even on a template-linked sample type
    assert c_template.allow_change_at_creation?(nil)
    assert c_template.allow_change_at_creation?(SampleAttribute.new(title: 'Custom'))

    # existing (saved) record -> always returns true regardless of inheritance
    person = FactoryBot.create(:person)
    saved_type = create_sample_type_from_template(template, person.projects.first, person)
    refute saved_type.new_record?
    c_saved = Seek::Samples::SampleTypeEditingConstraints.new(saved_type)
    saved_type.sample_attributes.each do |attr|
      assert c_saved.allow_change_at_creation?(attr),
             "#{attr.title}: allow_change_at_creation? should return true for an existing record"
    end
  end

  test 'allow editing unit' do
    person = FactoryBot.create(:person)
    project = person.projects.first

    # Create sample type
    # 'weight' attribute has a unit with symbol 'g'
    sample_type = FactoryBot.create(:patient_sample_type,
                                    projects: [project],
                                    contributor: person)
    weight_attribute = sample_type.sample_attributes.detect { |sa| sa.title == 'weight' }

    # Allow attribute unit to change when there are no samples
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type)
    assert c.allow_isa_tag_change?(weight_attribute)

    # Adding samples that have no value for the weight attribute should still allow users to change the attribute's unit
    sample_no_weight = Sample.new(sample_type: sample_type, projects: [project], contributor: person)
    sample_no_weight.set_attribute_value('full name', 'Anakin Skywalker')
    sample_no_weight.set_attribute_value(:age, 49)
    sample_no_weight.save
    assert sample_no_weight.valid?
    assert_equal sample_type.samples.count, 1
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type)
    assert c.allow_unit_change?(weight_attribute)

    # Adding samples that do have a value for the weight attribute should prevent users to change the attribute's unit
    sample_with_weight = Sample.new(sample_type: sample_type, projects: [project], contributor: person)
    sample_with_weight.set_attribute_value('full name', 'Luke Skywalker')
    sample_with_weight.set_attribute_value(:age, 25)
    sample_with_weight.set_attribute_value(:weight, 75111.1)
    sample_with_weight.save
    assert sample_with_weight.valid?
    assert_equal sample_type.samples.count, 2
    c = Seek::Samples::SampleTypeEditingConstraints.new(sample_type)
    refute c.allow_unit_change?(weight_attribute)
  end

  private

  # sample type with 3 samples
  # - the address attribute includes some blanks
  # - the postcode is always blank
  # - full name and age are required and always have values
  def sample_type_with_samples(person = nil)
    person ||= FactoryBot.create(:person)

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

  def create_sample_type_from_template(template, project, person, studies=[], assays=[])
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
                      studies: studies,
                      assays: assays,
                      sample_attributes: )
  end
end
