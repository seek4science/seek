class << self
  def create_tag text, attribute
    text_value = TextValue.find_or_create_by(text:text)
    unless text_value.has_attribute_name?(attribute)
      aa = AnnotationAttribute.find_or_create_by(name: attribute)
      AnnotationValueSeed.where(value_type: 'TextValue', value_id: text_value.id, attribute_id: aa).first_or_create!
    end
  end
end

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "culture_growth_types")

puts "Seeded culture growth types"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "model_formats")

puts "Seeded model formats"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "disciplines")

puts "Seeded disciplines"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "organisms")
ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "bioportal_concepts")
ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "strains")
disable_authorization_checks do
  #create policy for strains
  Strain.find_each do |strain|
    if strain.policy.nil?
      policy = Policy.public_policy
      policy.save
      strain.policy_id = policy.id
      strain.update_column(:policy_id,policy.id)
    end
  end

  # Fix first letters
  Organism.find_each do |organism|
    organism.update_first_letter
    organism.update_column(:first_letter, organism.first_letter)
  end

  Strain.find_each do |strain|
    strain.update_first_letter
    strain.update_column(:first_letter, strain.first_letter)
  end
end

puts "Seeded organisms"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "recommended_model_environments")

puts "Seeded recommended model environments"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "measured_items")

puts "Seeded measured items"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "units")

puts "Seeded units"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "project_positions")

puts "Seeded project positions"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "assay_classes")

puts "Seeded assay classes"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "relationship_types")

puts "Seeded relationship types"

File.open('config/default_data/expertise.list').each do |item|
  unless item.blank?
    item=item.chomp
    create_tag item, "expertise"
  end
end

File.open('config/default_data/tools.list').each do |item|
  unless item.blank?
    item=item.chomp
    create_tag item, "tool"
  end
end

puts "Seeded expertise and tools"

ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "compounds")
ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "synonyms")
ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "mappings")
ActiveRecord::FixtureSet.create_fixtures(File.join(Rails.root, "config/default_data"), "mapping_links")

puts "Seeded compounds and synonyms"
