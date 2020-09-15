# HumanDisease
Factory.define(:human_disease) do |f|
  f.title 'An Human Disease'
end

Factory.define(:min_humandisease, class: HumanDisease) do |f|
  f.title 'A Minimal Human Disease'
end

Factory.define(:max_humandisease, class: HumanDisease) do |f|
  f.title 'A Maximal Human Disease'
  f.projects { [ Factory.build(:max_project) ] }
  f.concept_uri 'http://purl.bioontology.org/obo/DOID_1909'
  f.ontology_id '23'
  f.assays { [ Factory.build(:assay, policy: Factory(:public_policy)) ] }
  f.models { [ Factory.build(:model, policy: Factory(:public_policy)) ] }
end

# AssayHumanDisease
Factory.define(:assay_human_disease) do |f|
  f.association :assay
  f.association :human_disease
end

# BioportalConcept
Factory.define(:human_disease_bioportal_concept, class: BioportalConcept) do |f|
  f.ontology_id 'DOID'
  f.concept_uri 'http://purl.obolibrary.org/obo/DOID_1909'
end
