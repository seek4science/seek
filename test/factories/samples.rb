# Sample
Factory.define(:sample) do |f|
  f.sequence(:title) { |n| "Sample #{n}" }
  f.association :sample_type, factory: :simple_sample_type
  f.association :contributor, factory: :person

  f.after_build do |sample|
    sample.projects = [sample.contributor.projects.first] if sample.projects.empty?
  end
  f.after_build do |sample|
    sample.set_attribute_value(:the_title, sample.title) if sample.data.key?(:the_title)
  end
end

Factory.define(:patient_sample, parent: :sample) do |f|
  f.association :sample_type, factory: :patient_sample_type
  f.after_build do |sample|
    sample.set_attribute_value(:full_name, 'Fred Bloggs')
    sample.set_attribute_value(:age, 44)
    sample.set_attribute_value(:weight, 88.7)
  end
end

Factory.define(:sample_from_file, parent: :sample) do |f|
  f.sequence(:title) { |n| "Sample #{n}" }
  f.association :sample_type, factory: :strain_sample_type

  f.after_build do |sample|
    sample.set_attribute_value(:name, sample.title) if sample.data.key?(:name)
    sample.set_attribute_value(:seekstrain, '1234')
  end

  f.after_build do |sample|
    sample.originating_data_file = Factory(:strain_sample_data_file, projects:sample.projects, contributor:sample.contributor) if sample.originating_data_file.nil?
  end

end
