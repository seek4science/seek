# AssayClass
#:assay_modelling and :assay_experimental rely on the existence of the AssayClasses
Factory.define(:modelling_assay_class, class: AssayClass) do |f|
  f.title I18n.t('assays.modelling_analysis')
  f.key 'MODEL'
end

Factory.define(:experimental_assay_class, class: AssayClass) do |f|
  f.title I18n.t('assays.experimental_assay')
  f.key 'EXP'
  f.description "An experimental assay class description"
end

# SuggestedTechnologyType
Factory.define(:suggested_technology_type) do |f|
  f.sequence(:label) { |n| "A TechnologyType#{n}" }
  f.ontology_uri 'http://jermontology.org/ontology/JERMOntology#Technology_type'
end

# SuggestedAssayType
Factory.define(:suggested_assay_type) do |f|
  f.sequence(:label) { |n| "An AssayType#{n}" }
  f.ontology_uri 'http://jermontology.org/ontology/JERMOntology#Experimental_assay_type'
  f.after_build { |type| type.term_type = 'assay' }
end

Factory.define(:suggested_modelling_analysis_type, class: SuggestedAssayType) do |f|
  f.sequence(:label) { |n| "An Modelling Analysis Type#{n}" }
  f.ontology_uri 'http://jermontology.org/ontology/JERMOntology#Model_analysis_type'
  f.after_build { |type| type.term_type = 'modelling_analysis' }
end

# Assay
Factory.define(:assay_base, class: Assay) do |f|
  f.sequence(:title) { |n| "An Assay #{n}" }
  f.sequence(:description) { |n| "Assay description #{n}" }
  f.association :contributor, factory: :person
  f.association :study
end

Factory.define(:modelling_assay, parent: :assay_base) do |f|
  f.association :assay_class, factory: :modelling_assay_class
end

Factory.define(:modelling_assay_with_organism, parent: :modelling_assay) do |f|
  f.after_create { |ma| Factory.build(:organism, assay: ma) }
end
Factory.define(:experimental_assay, parent: :assay_base) do |f|
  f.association :assay_class, factory: :experimental_assay_class
  f.assay_type_uri 'http://jermontology.org/ontology/JERMOntology#Experimental_assay_type'
  f.technology_type_uri 'http://jermontology.org/ontology/JERMOntology#Technology_type'
end

Factory.define(:assay, parent: :modelling_assay) {}

Factory.define(:min_assay, class: Assay) do |f|
  f.title "A Minimal Assay"
  f.association :assay_class, factory: :experimental_assay_class
  f.association :study, factory: :study
end

Factory.define(:max_assay, class: Assay) do |f|
  f.title "A Maximal Assay"
  f.description "A Western Blot Assay"
  f.association :assay_class, factory: :experimental_assay_class
  f.association :study, factory: :study
  f.association :contributor,  factory: :person
  f.assay_assets {[Factory(:assay_asset, asset: Factory(:data_file, policy: Factory(:public_policy))),
                   Factory(:assay_asset, asset: Factory(:sop, policy: Factory(:public_policy))),
                   Factory(:assay_asset, asset: Factory(:model, policy: Factory(:public_policy)))]}

  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
end

# AssayAsset
Factory.define :assay_asset do |f|
  f.association :assay
  f.association :asset, factory: :data_file
end

