construction_data = RelationshipType.find_or_initialize_by(title:'Construction data')
construction_data.update_attributes(description:'Data used for model testing',key:RelationshipType::CONSTRUCTION)

validation_data = RelationshipType.find_or_initialize_by(title:'Validation data')
validation_data.update_attributes(description:'Data used for validating a model',key:RelationshipType::VALIDATION)

simulation_data = RelationshipType.find_or_initialize_by(title:'Simulation results')
simulation_data.update_attributes(description:'Data resulting from running a model simulation',key:RelationshipType::SIMULATION)