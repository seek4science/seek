# Organism
Factory.define(:organism) do |f|
  f.title 'An Organism'
end

Factory.define(:min_organism, class: Organism) do |f|
  f.title 'A Minimal Organism'
end

Factory.define(:max_organism, class: Organism) do |f|
  f.title 'A Maximal Organism'
  f.projects { [Factory.build(:max_project)] }
  f.concept_uri 'https://identifiers.org/taxonomy/9606'
  f.ontology_id "23"
  f.assays {[Factory.build(:assay, policy: Factory(:public_policy))]}
  f.models {[Factory.build(:model, policy: Factory(:public_policy))]}
end

# AssayOrganism
Factory.define(:assay_organism) do |f|
  f.association :assay
  f.association :strain
  f.association :organism
end

# CultureGrowthType
Factory.define(:culture_growth_type) do |f|
  f.title 'a culture_growth_type'
end

# TissueAndCellType
Factory.define(:tissue_and_cell_type) do |f|
  f.sequence(:title) { |n| "Tisse and cell type #{n}" }
end

# BioportalConcept
Factory.define(:bioportal_concept) do |f|
  f.ontology_id 'NCBITAXON'
  f.concept_uri 'http://purl.obolibrary.org/obo/NCBITaxon_2287'
end

Factory.define(:organism_with_blank_concept, parent: :organism) do |f|
  f.bioportal_concept Factory(:bioportal_concept,ontology_id:'',concept_uri:'')
end
