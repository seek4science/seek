FactoryBot.define do
  # Strain
  factory(:strain) do
    sequence(:title) { |n| "Strain#{n}" }
    association :organism
    projects { [FactoryBot.create(:project)] }
    association :contributor, factory: :person, strategy: :create
  end
  
  factory(:min_strain, class: Strain) do
    title { 'A Minimal Strain' }
    association :organism, factory: :min_organism
    projects { [FactoryBot.create(:min_project)] }
  end
  
  # Phenotype
  factory :phenotype do
    sequence(:description) { |n| "phenotype #{n}" }
    association :strain, factory: :strain
  end
  
  # Genotype
  factory :genotype do
    association :gene, factory: :gene
    association :modification, factory: :modification
    association :strain, factory: :strain
  end
  
  # Gene
  factory :gene do
    sequence(:title) { |n| "gene #{n}" }
  end
  
  # Modification
  factory :modification do
    sequence(:title) { |n| "modification #{n}" }
  end
end
