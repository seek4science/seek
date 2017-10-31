# Relationship
Factory.define(:relationship) do |f|
  f.association :subject, factory: :model
  f.association :other_object, factory: :model
  f.predicate Relationship::ATTRIBUTED_TO
end

Factory.define(:attribution, parent: :relationship) {}

# RelationshipType
Factory.define(:validation_data_relationship_type, class:RelationshipType) do |f|
  f.title 'Validation data'
  f.key RelationshipType::VALIDATION
  f.description 'Data used for validating a model'
end

Factory.define(:simulation_data_relationship_type, class:RelationshipType) do |f|
  f.title 'Simulation results'
  f.key RelationshipType::SIMULATION
  f.description 'Data resulting from running a model simulation'
end

Factory.define(:construction_data_relationship_type, class:RelationshipType) do |f|
  f.title 'Construction data'
  f.key RelationshipType::CONSTRUCTION
  f.description 'Data used for model testing'
end
