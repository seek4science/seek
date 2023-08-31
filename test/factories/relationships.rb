FactoryBot.define do
  # Relationship
  factory(:relationship) do
    association :subject, factory: :model
    association :other_object, factory: :model
    predicate { Relationship::ATTRIBUTED_TO }
  end
  
  factory(:attribution, parent: :relationship) {}
  
  # RelationshipType
  factory(:validation_data_relationship_type, class:RelationshipType) do
    title { 'Validation data' }
    key { RelationshipType::VALIDATION }
    description { 'Data used for validating a model' }
  end
  
  factory(:simulation_data_relationship_type, class:RelationshipType) do
    title { 'Simulation results' }
    key { RelationshipType::SIMULATION }
    description { 'Data resulting from running a model simulation' }
  end
  
  factory(:construction_data_relationship_type, class:RelationshipType) do
    title { 'Construction data' }
    key { RelationshipType::CONSTRUCTION }
    description { 'Data used for model testing' }
  end
end
