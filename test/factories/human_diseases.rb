FactoryBot.define do
  # HumanDisease
  factory(:human_disease) do
    title { 'An Human Disease' }
  end
  
  factory(:min_human_disease, class: HumanDisease) do
    title { 'A Minimal Human Disease' }
  end
  
  factory(:max_human_disease, class: HumanDisease) do
    title { 'A Maximal Human Disease' }
    projects { [FactoryBot.create(:project)] }
    concept_uri { 'http://purl.bioontology.org/obo/DOID_1909' }
    ontology_id { '23' }
    assays { [FactoryBot.create(:assay, policy: FactoryBot.create(:public_policy))] }
    models { [FactoryBot.create(:model, policy: FactoryBot.create(:public_policy))] }
  end
  
  # AssayHumanDisease
  factory(:assay_human_disease) do
    association :assay
    association :human_disease
  end
  
  # BioportalConcept
  factory(:human_disease_bioportal_concept, class: BioportalConcept) do
    ontology_id { 'DOID' }
    concept_uri { 'http://purl.obolibrary.org/obo/DOID_1909' }
  end
end
