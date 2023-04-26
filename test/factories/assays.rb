FactoryBot.define do
  # AssayClass
  # :assay_modelling and :assay_experimental rely on the existence of the AssayClasses

  factory(:modelling_assay_class, class: AssayClass) do
    title { I18n.t('assays.modelling_analysis') }
    key { 'MODEL' }
  end

  factory(:experimental_assay_class, class: AssayClass) do
    title { I18n.t('assays.experimental_assay') }
    key { 'EXP' }
    description { "An experimental assay class description" }
  end

  # SuggestedTechnologyType
  factory(:suggested_technology_type) do
    sequence(:label) { | n | "A TechnologyType#{n}" }
    ontology_uri { 'http://jermontology.org/ontology/JERMOntology#Technology_type' }
  end

  # SuggestedAssayType
  factory(:suggested_assay_type) do
    sequence(:label) { | n | "An AssayType#{n}" }
    ontology_uri { 'http://jermontology.org/ontology/JERMOntology#Experimental_assay_type' }
    after_build { | type | type.term_type = 'assay' }
  end

  factory(:suggested_modelling_analysis_type, class: SuggestedAssayType) do
    sequence(:label) { | n | "An Modelling Analysis Type#{n}" }
    ontology_uri { 'http://jermontology.org/ontology/JERMOntology#Model_analysis_type' }
    after_build { | type | type.term_type = 'modelling_analysis' }
  end

  # Assay
  factory(:assay_base, class: Assay) do
    sequence(:title) { | n | "An Assay #{n}" }
    sequence(:description) { | n | "Assay description #{n}" }
    association :contributor, factory: :person
    after_build do |a|
      a.study ||= Factory(:study, contributor: a.contributor)
    end
  end

  factory(:modelling_assay, parent: :assay_base) do
    association :assay_class, factory: :modelling_assay_class
    assay_type_uri { 'http://jermontology.org/ontology/JERMOntology#Model_analysis_type' }
  end

  factory(:modelling_assay_with_organism, parent: :modelling_assay) do
    after_create { | ma | Factory.build(:organism, assay: ma ) }
  end
  factory(:experimental_assay, parent: :assay_base) do
    association :assay_class, factory: :experimental_assay_class
    assay_type_uri { 'http://jermontology.org/ontology/JERMOntology#Experimental_assay_type' }
    technology_type_uri { 'http://jermontology.org/ontology/JERMOntology#Technology_type' }
  end

  factory(:assay, parent: :modelling_assay) {}

  factory(:public_assay, parent: :modelling_assay) do
    policy { Factory(:public_policy) }
    study { Factory(:public_study) }
  end

  factory(:min_assay, class: Assay) do
    title { "A Minimal Assay" }
    association :assay_class, factory: :experimental_assay_class
    association :contributor, factory: :person
    after_build do |a|
      a.study ||= Factory(:min_study, contributor: a.contributor, policy: a.policy.try(:deep_copy))
    end
  end

  factory(:max_assay, class: Assay) do
    title { "A Maximal Modelling Assay" }
    description { "A Western Blot Assay" }
    discussion_links { [Factory.build(:discussion_link, label: 'Slack')] }
    other_creators { "Anonymous creator" }
    technology_type_uri { 'http://jermontology.org/ontology/JERMOntology#Technology_type' }
    association :assay_class, factory: :modelling_assay_class
    association :contributor,  factory: :person
    assay_assets {[Factory(:assay_asset, asset: Factory(:data_file, policy: Factory(:public_policy))),
                   Factory(:assay_asset, asset: Factory(:sop, policy: Factory(:public_policy))),
                   Factory(:assay_asset, asset: Factory(:model, policy: Factory(:public_policy))),
                   Factory(:assay_asset, asset: Factory(:document, policy: Factory(:public_policy))),
                   Factory(:assay_asset, asset: Factory(:sample, policy: Factory(:public_policy)))]}
    relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
    organisms { [Factory(:organism)] }
    after_build do |a|
      a.study ||= Factory(:study, contributor: a.contributor, policy: Factory(:public_policy),
                          investigation: Factory(:investigation, contributor: a.contributor, policy: Factory(:public_policy)))
    end
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
  end

  # AssayAsset
  factory :assay_asset do
    association :assay
    association :asset, factory: :data_file
  end
end
