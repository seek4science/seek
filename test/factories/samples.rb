# Sample
Factory.define(:sample) do |f|
  f.sequence(:title) { |n| "Sample #{n}" }
  f.association :sample_type, factory: :simple_sample_type
  f.projects { [Factory.build(:project)] }
  f.after_build do |sample|
    sample.set_attribute(:the_title, sample.title) if sample.data.key?(:the_title)
  end
end

Factory.define(:patient_sample, parent: :sample) do |f|
  f.association :sample_type, factory: :patient_sample_type
  f.after_build do |sample|
    sample.set_attribute(:full_name, 'Fred Bloggs')
    sample.set_attribute(:age, 44)
    sample.set_attribute(:weight, 88.7)
  end
end

Factory.define(:sample_from_file, parent: :sample) do |f|
  f.sequence(:title) { |n| "Sample #{n}" }
  f.association :sample_type, factory: :strain_sample_type
  f.projects { [Factory.build(:project)] }
  f.association :originating_data_file, factory: :strain_sample_data_file
  f.after_build do |sample|
    sample.set_attribute(:name, sample.title) if sample.data.key?(:name)
    sample.set_attribute(:seekstrain, '1234')
  end
end
