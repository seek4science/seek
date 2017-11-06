# Strain
Factory.define(:strain) do |f|
  f.sequence(:title) { |n| "Strain#{n}" }
  f.association :organism
  f.projects { [Factory.build(:project)] }
  f.association :contributor, factory: :person
end

Factory.define(:min_strain, class: Strain) do |f|
  f.title 'A Minimal Strain'
  f.association :organism, factory: :min_organism
  f.projects {[Factory.build(:min_project)]}
end

# Phenotype
Factory.define :phenotype do |f|
  f.sequence(:description) { |n| "phenotype #{n}" }
  f.association :strain, factory: :strain
end

# Genotype
Factory.define :genotype do |f|
  f.association :gene, factory: :gene
  f.association :modification, factory: :modification
  f.association :strain, factory: :strain
end

# Gene
Factory.define :gene do |f|
  f.sequence(:title) { |n| "gene #{n}" }
end

# Modification
Factory.define :modification do |f|
  f.sequence(:title) { |n| "modification #{n}" }
end
