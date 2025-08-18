# ISA - Investigation, Study, Assays, Observation Units
investigation = Investigation.new(title: 'Central Carbon Metabolism of Sulfolobus solfataricus',
                                  description: 'An investigation in the CCM of S. solfataricus with a focus on the unique temperature adaptations and regulation; using a combined modelling and experimental approach.')
investigation.projects = [$project]
investigation.contributor = $guest_person
investigation.policy = Policy.create(name: 'default policy', access_type: 1)
investigation.annotate_with(['metabolism', 'thermophile'], 'tag', $guest_person)
investigation.save
puts 'Seeded 1 investigation.'

study = Study.new(title: 'Carbon loss at high T')
study.contributor = $guest_person
study.policy = Policy.create(name: 'default policy', access_type: 1)
study.investigation = investigation
study.annotate_with(['thermophile', 'high temperature'], 'tag', $guest_person)
study.save
puts 'Seeded 1 study.'

## Observation unit
observation_unit = ObservationUnit.new(title: 'Large scale bioreactor')
observation_unit.description = 'A large scale bioreactor with a 1000 mL reservoir.'
observation_unit.other_creators = [$admin_person.name, 'Jane Doe']
observation_unit.contributor = $guest_person
observation_unit.policy = Policy.create(name: 'default policy', access_type: 1)
observation_unit.annotate_with(['bioreactor'], 'tag', $guest_person)
observation_unit.study = study
disable_authorization_checks { observation_unit.save }
puts 'Seeded 1 observation unit'

## Assays ##

## Experimental assay?
exp_assay = Assay.new(title: 'Reconstituted system reference state',
                      description: 'The four purified enzymes were incubated in assay buffer and consumption of 3PG and production of F6P were measured in time, together with GAP and DHAP concentrations.')
exp_assay.contributor = $guest_person
exp_assay.policy = Policy.create(name: 'default policy', access_type: 1)
exp_assay.study = study
# exp_assay.observation_units = [observation_unit] # TODO ActiveRecord::HasManyThroughNestedAssociationsAreReadonly: Cannot modify association 'Assay#observation_units' because it goes through more than one other association. (ActiveRecord::HasManyThroughNestedAssociationsAreReadonly)
exp_assay.assay_class = AssayClass.experimental
exp_assay.organisms = [$organism]
exp_assay.save
puts "exp_assay: Seeded 1 #{exp_assay.assay_class.long_key.downcase}."

# Modeling assay?
model_assay = Assay.new(title: 'Model reconstituted system',
                        description: 'Mathematical model for the reconstituted system with PGK, GAPDH, TPI and FBPAase.')
model_assay.contributor = $guest_person
model_assay.policy = Policy.create(name: 'default policy', access_type: 1)
model_assay.study = study
model_assay.assay_class = AssayClass.modelling
model_assay.save
puts "Seeded 1 #{model_assay.assay_class.long_key.downcase}."

# Assay stream
assay_stream = Assay.new(title: 'Assay stream',
                         description: 'A stream of assays? This is a test assay stream for the example data.',)
assay_stream.contributor = $guest_person
assay_stream.policy = Policy.create(name: 'default policy', access_type: 1)
assay_stream.study = study
assay_stream.assay_class = AssayClass.assay_stream
assay_stream.save
puts "Seeded 1 assay stream #{model_assay.assay_class.long_key.downcase}."

# Store references for other seed files
$investigation = investigation
$study = study
$observation_unit = observation_unit
$exp_assay = exp_assay
$model_assay = model_assay
$assay_stream = assay_stream