FactoryBot.define do
  # Organism
  factory(:organism) do
    title { 'An Organism' }
  end
  
  factory(:min_organism, class: Organism) do
    title { 'A Minimal Organism' }
  end
  
  factory(:max_organism, class: Organism) do
    title { 'A Maximal Organism' }
    concept_uri { 'http://purl.bioontology.org/ontology/NCBITAXON/9606' }
    ontology_id { "23" }
    assays { [FactoryBot.create(:public_assay)] }
    models {[FactoryBot.build(:model, policy: FactoryBot.create(:public_policy))]}
    projects {[FactoryBot.build(:project)]}
  end
  
  # AssayOrganism
  factory(:assay_organism) do
    association :assay
    association :strain
    association :organism
  end
  
  # CultureGrowthType
  factory(:culture_growth_type) do
    title { 'a culture_growth_type' }
  end
  
  # TissueAndCellType
  factory(:tissue_and_cell_type) do
    sequence(:title) { |n| "Tisse and cell type #{n}" }
  end
  
  # BioportalConcept
  factory(:bioportal_concept) do
    ontology_id { 'NCBITAXON' }
    concept_uri { 'http://purl.obolibrary.org/obo/NCBITaxon_2287' }
  end
  
  factory(:organism_with_blank_concept, parent: :organism) do
    bioportal_concept { build(:bioportal_concept, ontology_id: '', concept_uri: '') }
  end
end
